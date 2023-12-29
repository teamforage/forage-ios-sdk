//
//  ForagePublicSubmitMethodTests.swift
//
//
//  Created by Danilo Joksimovic on 2023-12-14.
//

import XCTest

@testable import ForageSDK

class MockForageService: LiveForageService {
    var doesCheckBalanceThrow: Bool = false
    var doesCapturePaymentThrow: Bool = false
    var doesTokenizeEBTCardThrow: Bool = false
    var doesCollectPinThrow: Bool = false

    override func checkBalance(pinCollector: VaultCollector, paymentMethodReference: String) async throws -> BalanceModel {
        if doesCheckBalanceThrow {
            throw ForageError.create(
                httpStatusCode: 400,
                code: "ebt_error_55",
                message: "Invalid PIN or PIN not selected - Invalid PIN"
            )
        }

        return BalanceModel(snap: "100.0", cash: "1.0", updated: "2023-4-20T12:36:57.482668-08:00")
    }

    override func tokenizeEBTCard(request: ForagePANRequestModel, completion: @escaping (Result<PaymentMethodModel, Error>) -> Void) {
        if doesTokenizeEBTCardThrow {
            let error = ForageError.create(
                httpStatusCode: 400,
                code: "card_not_reusable",
                message: "Payment method acdef123 is not reusable"
            )

            completion(.failure(error))
            return
        }

        let paymentMethodModel = try! JSONDecoder().decode(
            PaymentMethodModel.self,
            from: ForageMocks().tokenizeSuccess
        )

        completion(.success(paymentMethodModel))
    }

    override func capturePayment(pinCollector: VaultCollector, paymentReference: String) async throws -> PaymentModel {
        if doesCapturePaymentThrow {
            throw ForageError.create(
                httpStatusCode: 400,
                code: "ebt_error_43",
                message: "Lost/stolen card - Cannot Process - Call Customer Service"
            )
        }

        let paymentModel = try! JSONDecoder().decode(
            PaymentModel.self,
            from: ForageMocks().capturePaymentSuccess
        )
        return paymentModel
    }

    override func collectPinForDeferredCapture(
        pinCollector: VaultCollector,
        paymentReference: String
    ) async throws -> VaultResponse {
        if doesCollectPinThrow {
            throw ForageError.create(
                httpStatusCode: 429,
                code: "too_many_requests",
                message: "Request was throttled, please try again later."
            )
        }
        return VaultResponse()
    }
}

class MockForagePINTextField: ForagePINTextField {
    var mockIsComplete: Bool = true

    @IBInspectable override public var isComplete: Bool {
        mockIsComplete
    }
}

let EXPECTED_INCOMPLETE_PIN_MESSAGE = "Invalid EBT Card PIN entered. Please enter your 4-digit PIN."
let EXPECTED_UNKNOWN_SERVER_ERROR = "Unknown error. This is a problem on Forage’s end."

final class ForagePublicSubmitMethodTests: XCTestCase {
    var mockService: MockForageService!
    var mockLogger: MockLogger!

    override func setUpWithError() throws {
        super.setUp()
        mockService = createMockService()
        mockLogger = MockLogger()
        setupMockSDK()
    }

    override func tearDownWithError() throws {
        mockService = nil
        mockLogger = nil
        super.tearDown()
    }

    func createMockService() -> MockForageService {
        MockForageService(
            provider: Provider(URLSessionMock()),
            ldManager: MockLDManager(),
            pollingService: MockPollingService(ldManager: MockLDManager())
        )
    }

    func setupMockSDK() {
        MockForageSDK.setup(ForageSDK.Config(
            merchantID: "merchantID123",
            sessionToken: "dev_authToken123"
        ))
        MockForageSDK.logger = mockLogger
        MockForageSDK.shared.service = mockService
    }

    func createMockPinTextField(isComplete: Bool = true) -> MockForagePINTextField {
        let mockPinTextField = MockForagePINTextField(frame: .zero)
        mockPinTextField.mockIsComplete = isComplete
        return mockPinTextField
    }

    // MARK: "execute" method invocation helpers

    func executeBalanceCheck(
        doesThrow: Bool = false,
        pinComplete: Bool = true,
        description: String,
        validation: @escaping (Result<BalanceModel, Error>
        ) -> Void
    ) {
        mockService.doesCheckBalanceThrow = doesThrow
        let mockPinTextField = createMockPinTextField(isComplete: pinComplete)
        let expectation = XCTestExpectation(description: description)

        MockForageSDK.shared.checkBalance(
            foragePinTextField: mockPinTextField,
            paymentMethodReference: "abcdef123"
        ) { result in
            validation(result)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func executeCapturePayment(
        doesThrow: Bool = false,
        pinComplete: Bool = true,
        description: String,
        validation: @escaping (Result<PaymentModel, Error>
        ) -> Void
    ) {
        mockService.doesCapturePaymentThrow = doesThrow
        let mockPinTextField = createMockPinTextField(isComplete: pinComplete)
        let expectation = XCTestExpectation(description: description)

        MockForageSDK.shared.capturePayment(
            foragePinTextField: mockPinTextField,
            paymentReference: "11767381fd"
        ) { result in
            validation(result)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func executeDeferPaymentCapture(
        doesThrow: Bool = false,
        pinComplete: Bool = true,
        description: String,
        validation: @escaping (Result<Void, Error>) -> Void
    ) {
        mockService.doesCollectPinThrow = doesThrow
        let mockPinTextField = createMockPinTextField(isComplete: pinComplete)
        let expectation = XCTestExpectation(description: description)

        MockForageSDK.shared.deferPaymentCapture(
            foragePinTextField: mockPinTextField,
            paymentReference: "deferPaymentCapturePaymentRef123"
        ) { result in
            validation(result)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: tokenizeEBTCard tests

    func testTokenizeEBTCard_Success() {
        let expectation = XCTestExpectation(description: "Returns PaymentMethod response")
        let mockPanTextField = ForagePANTextField(frame: .zero)

        MockForageSDK.shared.tokenizeEBTCard(
            foragePanTextField: mockPanTextField,
            customerID: "test-ios-customer-id"
        ) { result in
            switch result {
            case let .success(paymentMethod):
                XCTAssertEqual(paymentMethod.paymentMethodIdentifier, "d0c47b0ed5")
                XCTAssertEqual(paymentMethod.type, "ebt")
                XCTAssertNil(paymentMethod.balance)
                XCTAssertEqual(paymentMethod.card.last4, "3412")
                XCTAssertEqual(paymentMethod.customerID, "test-ios-customer-id")
                XCTAssertEqual(paymentMethod.reusable, true)

                expectation.fulfill()
            case .failure:
                XCTFail("Expected success but got \(String(describing: result))")
            }
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testTokenizeEBTCard_Throws_DoesRejectWithError() {
        let expectation = XCTestExpectation(description: "tokenizeEBTCard rejects with ForageError")
        let mockPanTextField = ForagePANTextField(frame: .zero)

        (MockForageSDK.shared.service as! MockForageService).doesTokenizeEBTCardThrow = true

        MockForageSDK.shared.tokenizeEBTCard(
            foragePanTextField: mockPanTextField,
            customerID: "test-ios-customer-id"
        ) { result in
            switch result {
            case .success:
                XCTFail("Expected ForageError but got \(String(describing: result))")
            case let .failure(error):
                let firstForageError = (error as! ForageError).errors.first!

                XCTAssertEqual(firstForageError.code, "card_not_reusable")
                XCTAssertEqual(firstForageError.message, "Payment method acdef123 is not reusable")
                XCTAssertEqual(firstForageError.httpStatusCode, 400)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: checkBalance tests

    func testCheckBalanceSuccess_ReportsMetricAndResolvesWithBalance() {
        executeBalanceCheck(description: "Balance check succeeds") { result in
            switch result {
            case let .success(balance):
                XCTAssertEqual(balance.snap, "100.0")
                XCTAssertEqual(balance.cash, "1.0")
                XCTAssertEqual(balance.updated, "2023-4-20T12:36:57.482668-08:00")

                // Are metrics-related events being reported correctly?
                XCTAssertEqual(self.mockLogger.lastInfoMsg, "Reported customer-perceived response event")
                XCTAssertTrue(self.mockLogger.lastAttributes!["response_time_ms"] is Double)
                XCTAssertNotEqual(self.mockLogger.lastAttributes!["response_time_ms"] as! Double, 0.0)
                XCTAssertEqual(self.mockLogger.lastAttributes!["log_type"] as! String, "metric")
                XCTAssertEqual(self.mockLogger.lastAttributes!["action"] as! String, "balance")
            case .failure:
                XCTFail("Expected success but got \(String(describing: result))")
            }
        }
    }

    func testCheckBalance_IncompletePIN_LogsAndReturnsUserError() {
        executeBalanceCheck(
            pinComplete: false,
            description: "checkBalance rejects with user_error"
        ) { result in
            switch result {
            case .success:
                XCTFail("Expected user_error but got \(String(describing: result))")
            case let .failure(error):
                let firstForageError = (error as! ForageError).errors.first!

                XCTAssertEqual(firstForageError.code, "user_error")
                XCTAssertEqual(firstForageError.message, EXPECTED_INCOMPLETE_PIN_MESSAGE)
                XCTAssertEqual(firstForageError.httpStatusCode, 400)
            }
        }
    }

    func testCheckBalance_IllegalStateException_LogsAndRejectsWithError() {
        MockForageSDK.shared.service = nil

        executeBalanceCheck(
            pinComplete: false,
            description: "checkBalance rejects with generic unknown_server_error"
        ) { result in
            switch result {
            case .success:
                XCTFail("Expected unknown_server_error but got \(String(describing: result))")
            case let .failure(error):
                let firstForageError = (error as! ForageError).errors.first!

                XCTAssertEqual(firstForageError.code, "unknown_server_error")
                XCTAssertEqual(firstForageError.message, EXPECTED_UNKNOWN_SERVER_ERROR)
                XCTAssertEqual(firstForageError.httpStatusCode, 500)

                XCTAssertEqual(self.mockLogger.lastCriticalMessage, "Attempted to call checkBalance, but ForageService was not initialized")
            }
        }
    }

    func testCheckBalance_ThrowsCardError_ReportsAndRejectsWithError() {
        executeBalanceCheck(
            doesThrow: true,
            description: "checkBalance rejects with card error"
        ) { result in
            switch result {
            case .success:
                XCTFail("Expected ebt_error_55 but got \(String(describing: result))")
            case let .failure(error):
                let firstForageError = (error as! ForageError).errors.first!

                // Assert ForageError response
                XCTAssertEqual(firstForageError.code, "ebt_error_55")
                XCTAssertEqual(firstForageError.message, "Invalid PIN or PIN not selected - Invalid PIN")
                XCTAssertEqual(firstForageError.httpStatusCode, 400)

                XCTAssertEqual(self.mockLogger.lastErrorMsg, "Balance check failed for PaymentMethod abcdef123")

                // Are metrics-related events being reported correctly?
                XCTAssertEqual(self.mockLogger.lastInfoMsg, "Reported customer-perceived response event")
                XCTAssertTrue(self.mockLogger.lastAttributes!["response_time_ms"] is Double)
                XCTAssertNotEqual(self.mockLogger.lastAttributes!["response_time_ms"] as! Double, 0.0)
                XCTAssertEqual(self.mockLogger.lastAttributes!["log_type"] as! String, "metric")
                XCTAssertEqual(self.mockLogger.lastAttributes!["action"] as! String, "balance")
            }
        }
    }

    // MARK: capturePayment tests

    func testCapturePayment_Success_ReportsMetricAndResolvesWithPayment() {
        executeCapturePayment(description: "Capture payment succeeds") { result in
            if case let .success(payment) = result {
                XCTAssertEqual(payment.paymentRef, "11767381fd")
                XCTAssertEqual(payment.amount, "10.00")

                // Are metrics-related events being reported correctly?
                XCTAssertEqual(self.mockLogger.lastInfoMsg, "Reported customer-perceived response event")
                XCTAssertTrue(self.mockLogger.lastAttributes!["response_time_ms"] is Double)
                XCTAssertNotEqual(self.mockLogger.lastAttributes!["response_time_ms"] as! Double, 0.0)
                XCTAssertEqual(self.mockLogger.lastAttributes!["log_type"] as! String, "metric")
                XCTAssertEqual(self.mockLogger.lastAttributes!["action"] as! String, "capture")
            } else {
                XCTFail("Expected success but got \(String(describing: result))")
            }
        }
    }

    func testCapturePayment_IncompletePIN_LogsAndReturnsUserError() {
        executeCapturePayment(
            pinComplete: false,
            description: "Capture payment rejects with user_error"
        ) { result in
            switch result {
            case .success:
                XCTFail("Expected user_error but got \(String(describing: result))")
            case let .failure(error):
                let firstForageError = (error as! ForageError).errors.first!
                XCTAssertEqual(firstForageError.code, "user_error")
                XCTAssertEqual(firstForageError.message, EXPECTED_INCOMPLETE_PIN_MESSAGE)
                XCTAssertEqual(firstForageError.httpStatusCode, 400)
            }
        }
    }

    func testCapturePayment_ThrowsCardError_RejectsWithError() {
        executeCapturePayment(
            doesThrow: true,
            description: "Capture payment rejects with ebt_error_43"
        ) { result in
            switch result {
            case .success:
                XCTFail("Expected ebt_error_43 but got \(String(describing: result))")
            case let .failure(error):
                let firstForageError = (error as! ForageError).errors.first!
                XCTAssertEqual(firstForageError.code, "ebt_error_43")
                XCTAssertEqual(firstForageError.message, "Lost/stolen card - Cannot Process - Call Customer Service")
                XCTAssertEqual(firstForageError.httpStatusCode, 400)

                // Are metrics-related events being reported correctly?
                XCTAssertEqual(self.mockLogger.lastInfoMsg, "Reported customer-perceived response event")
                XCTAssertTrue(self.mockLogger.lastAttributes!["response_time_ms"] is Double)
                XCTAssertNotEqual(self.mockLogger.lastAttributes!["response_time_ms"] as! Double, 0.0)
                XCTAssertEqual(self.mockLogger.lastAttributes!["log_type"] as! String, "metric")
                XCTAssertEqual(self.mockLogger.lastAttributes!["action"] as! String, "capture")
            }
        }
    }

    func testCapturePayment_IllegalStateException_LogsAndRejectsWithError() {
        MockForageSDK.shared.service = nil

        executeCapturePayment(
            pinComplete: false,
            description: "capturePayment rejects with generic unknown_server_error"
        ) { result in
            switch result {
            case .success:
                XCTFail("Expected unknown_server_error but got \(String(describing: result))")
            case let .failure(error):
                let firstForageError = (error as! ForageError).errors.first!

                XCTAssertEqual(firstForageError.code, "unknown_server_error")
                XCTAssertEqual(firstForageError.message, EXPECTED_UNKNOWN_SERVER_ERROR)
                XCTAssertEqual(firstForageError.httpStatusCode, 500)

                XCTAssertEqual(self.mockLogger.lastCriticalMessage, "Attempted to call capturePayment, but ForageService was not initialized")
            }
        }
    }

    // MARK: deferPaymentCapture tests

    func testDeferPaymentCapture_Success() {
        executeDeferPaymentCapture(
            description: "PIN collection for deferred capture succeeds"
        ) { result in
            switch result {
            case .success:
                XCTAssertTrue(true)
            case .failure:
                XCTFail("Expected success but got \(String(describing: result))")
            }
        }
    }

    func testDeferPaymentCapture_IncompletePIN() {
        executeDeferPaymentCapture(
            pinComplete: false,
            description: "deferPaymentCapture rejects with user_error due to incomplete PIN"
        ) { result in
            switch result {
            case .success:
                XCTFail("Expected failure due to incomplete PIN but got success")
            case let .failure(error):
                let forageError = (error as! ForageError).errors.first!
                XCTAssertEqual(forageError.code, "user_error")
                XCTAssertEqual(forageError.message, EXPECTED_INCOMPLETE_PIN_MESSAGE)
                XCTAssertEqual(forageError.httpStatusCode, 400)
            }
        }
    }

    func testDeferPaymentCapture_IllegalState() {
        MockForageSDK.shared.service = nil

        executeDeferPaymentCapture(
            description: "deferPaymentCapture rejects with unknown_server_error due to uninitialized service"
        ) { result in
            switch result {
            case .success:
                XCTFail("Expected unknown_server_error but got success")
            case let .failure(error):
                let forageError = (error as! ForageError).errors.first!
                XCTAssertEqual(forageError.code, "unknown_server_error")
                XCTAssertEqual(forageError.message, EXPECTED_UNKNOWN_SERVER_ERROR)
                XCTAssertEqual(forageError.httpStatusCode, 500)
                XCTAssertEqual(self.mockLogger.lastCriticalMessage, "Attempted to call deferPaymentCapture, but ForageService was not initialized")
            }
        }
    }

    func testDeferPaymentCapture_ThrowsError() {
        executeDeferPaymentCapture(
            doesThrow: true,
            description: "deferPaymentCapture rejects with general error"
        ) { result in
            switch result {
            case .success:
                XCTFail("Expected general error but got success")
            case let .failure(error):
                XCTAssertNotNil(error)
            }
        }
    }
}
