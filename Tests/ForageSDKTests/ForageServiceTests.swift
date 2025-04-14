//
//  ForageServiceTests.swift
//  ForageSDK
//
//  Created by Tiago Oliveira on 29/11/22.
//  Copyright © 2023-Present Forage Technology Corporation. All rights reserved.
//

@testable import ForageSDK
import XCTest

final class ForageServiceTests: XCTestCase {
    var forageMocks: ForageMocks!

    override func setUp() {
        setUpForageSDK()
        forageMocks = ForageMocks()
    }

    func createTestService(_ mockSession: URLSessionMock) -> ForageService {
        LiveForageService(provider: Provider(mockSession))
    }
    
    func test_tokenizeCreditDebitCard_onSuccess_checkExpectedPayload() {
        let mockSession = URLSessionMock()
        mockSession.data = forageMocks.tokenizeCreditDebitSuccess
        mockSession.response = forageMocks.mockSuccessResponse
        let service = createTestService(mockSession)

        let forageCreditDebitRequestModel = ForageCreditDebitRequestModel(
            authorization: "authToken123",
            merchantID: "merchantID123",
            name: "Sleve McDichael",
            number: "5200828282828210",
            expMonth: 1,
            expYear: 45,
            securityCode: "123",
            zipCode: "12345",
            type: "credit",
            customerID: "test-ios-customer-id",
            isHSAFSA: true,
            reusable: true
        )

        let expectation = XCTestExpectation(description: "Tokenize Credit Debit Card - should succeed")
        expectation.assertForOverFulfill = true
        service.tokenizeCreditDebitCard(request: forageCreditDebitRequestModel) { result in
            switch result {
            case let .success(response):
                XCTAssertEqual(response.type, "credit")
                XCTAssertEqual(response.paymentMethodIdentifier, "d0c47b0ed5")
                XCTAssertEqual(response.card.last4, "8210")
                XCTAssertEqual(response.customerID, "test-ios-customer-id")
                expectation.fulfill()
            case .failure:
                XCTFail("Expected success")
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func test_tokenizeCreditDebitCard_onFailure_shouldReturnFailure() {
        let mockSession = URLSessionMock()
        mockSession.error = forageMocks.tokenizeCreditDebitFailure
        mockSession.response = forageMocks.mockFailureResponse
        let service = createTestService(mockSession)

        let forageCreditDebitRequestModel = ForageCreditDebitRequestModel(
            authorization: "authToken123",
            merchantID: "merchantID123",
            name: "Sleve McDichael",
            number: "5200828282828210",
            expMonth: 1,
            expYear: 45,
            securityCode: "123",
            zipCode: "12345",
            type: "credit",
            customerID: "test-ios-customer-id",
            isHSAFSA: true,
            reusable: true
        )

        let expectation = XCTestExpectation(description: "Tokenize Credit Debit Card - result should be failure")
        expectation.assertForOverFulfill = true
        service.tokenizeCreditDebitCard(request: forageCreditDebitRequestModel) { result in
            switch result {
            case .success:
                XCTFail("Expected failure")
            case let .failure(error):
                XCTAssertNotNil(error)
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func test_tokenizeEBTCard_onSuccess_checkExpectedPayload() {
        let mockSession = URLSessionMock()
        mockSession.data = forageMocks.tokenizeEBTSuccess
        mockSession.response = forageMocks.mockSuccessResponse
        let service = createTestService(mockSession)

        let foragePANRequestModel = ForagePANRequestModel(
            authorization: "authToken123",
            merchantID: "merchantID123",
            panNumber: "5076801234123412",
            type: "ebt",
            customerID: "test-ios-customer-id",
            reusable: true
        )

        let expectation = XCTestExpectation(description: "Tokenize EBT Card - should succeed")
        expectation.assertForOverFulfill = true
        service.tokenizeEBTCard(request: foragePANRequestModel) { result in
            switch result {
            case let .success(response):
                XCTAssertEqual(response.type, "ebt")
                XCTAssertEqual(response.paymentMethodIdentifier, "d0c47b0ed5")
                XCTAssertEqual(response.card.last4, "3412")
                XCTAssertEqual(response.card.token, "tok_sandbox_72VEC9LasHbMYiiVWP9zms")
                XCTAssertEqual(response.customerID, "test-ios-customer-id")
                expectation.fulfill()
            case .failure:
                XCTFail("Expected success")
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func test_tokenizeEBTCard_onFailure_shouldReturnFailure() {
        let mockSession = URLSessionMock()
        mockSession.error = forageMocks.tokenizeEBTFailure
        mockSession.response = forageMocks.mockFailureResponse
        let service = createTestService(mockSession)

        let foragePANRequestModel = ForagePANRequestModel(
            authorization: "authToken123",
            merchantID: "merchantID123",
            panNumber: "5076801234123412",
            type: "ebt",
            customerID: "test-ios-customer-id",
            reusable: true
        )

        let expectation = XCTestExpectation(description: "Tokenize EBT Card - result should be failure")
        expectation.assertForOverFulfill = true
        service.tokenizeEBTCard(request: foragePANRequestModel) { result in
            switch result {
            case .success:
                XCTFail("Expected failure")
            case let .failure(error):
                XCTAssertNotNil(error)
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func test_getPaymentMethod_onSuccess_checkExpectedPayload() {
        let mockSession = URLSessionMock()
        mockSession.data = forageMocks.getPaymentMethodSuccess
        mockSession.response = forageMocks.mockSuccessResponse
        let service = createTestService(mockSession)

        let expectation = XCTestExpectation(description: "Get the Payment Method - should succeed")
        expectation.assertForOverFulfill = true
        service.getPaymentMethod(sessionToken: "auth1234", merchantID: "1234567", paymentMethodRef: "ca29d3443f") { result in
            switch result {
            case let .success(paymentMethod):
                XCTAssertEqual(paymentMethod.paymentMethodIdentifier, "ca29d3443f")
                XCTAssertEqual(paymentMethod.type, "ebt")
                XCTAssertEqual(paymentMethod.balance?.snap, "100.00")
                XCTAssertEqual(paymentMethod.balance?.cash, "100.00")
                XCTAssertEqual(paymentMethod.card.token, "tok_sandbox_vJp2BwDc6R6Z16mgzCxuXk")
                XCTAssertEqual(paymentMethod.reusable, true)
                expectation.fulfill()
            case .failure:
                XCTFail("Expected success")
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func test_getPaymentMethod_onFailure_shouldReturnFailure() {
        let mockSession = URLSessionMock()
        mockSession.error = forageMocks.getPaymentMethodFailure
        mockSession.response = forageMocks.mockFailureResponse
        let service = createTestService(mockSession)

        let expectation = XCTestExpectation(description: "Get the Payment Method - result should be failure")
        expectation.assertForOverFulfill = true
        service.getPaymentMethod(sessionToken: "auth1234", merchantID: "1234567", paymentMethodRef: "ca29d3443f") { result in
            switch result {
            case .success:
                XCTFail("Expected failure")
            case let .failure(error):
                XCTAssertNotNil(error)
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func test_getPaymentMethod_onNetworkErrorFailure_shouldReturnFailure() {
        let mockSession = URLSessionMock()
        mockSession.error = forageMocks.networkError
        let service = createTestService(mockSession)

        let expectation = XCTestExpectation(description: "Get the Payment Method - result should be failure")
        expectation.assertForOverFulfill = true
        service.getPaymentMethod(sessionToken: "auth1234", merchantID: "1234567", paymentMethodRef: "ca29d3443f") { result in
            switch result {
            case .success:
                XCTFail("Expected failure")
            case let .failure(error):
                XCTAssertNotNil(error)
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func test_getPaymentMethod_onNilResponse_shouldReturnUnknownServerError() {
        let mockSession = URLSessionMock()
        mockSession.response = nil  // This will trigger the guard statement
        let service = createTestService(mockSession)

        let expectation = XCTestExpectation(description: "Get the Payment Method - result should be unknown server error")
        expectation.assertForOverFulfill = true
        
        service.getPaymentMethod(sessionToken: "auth1234", merchantID: "1234567", paymentMethodRef: "ca29d3443f") { result in
            switch result {
            case .success:
                XCTFail("Expected unknown server error")
            case let .failure(error):
                let forageError = error as! ForageError
                XCTAssertEqual(forageError.code, "unknown_server_error")
                XCTAssertEqual(forageError.httpStatusCode, 500)
                XCTAssertEqual(forageError.message, "Unknown error. This is a problem on Forage’s end.")
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func test_getPaymentMethod_onNonHTTPResponse_shouldReturnUnknownServerError() {
        let mockSession = URLSessionMock()
        // Create a non-HTTP URLResponse
        mockSession.response = URLResponse(url: URL(string: "https://forage.com/tests")!, 
                                        mimeType: nil, 
                                        expectedContentLength: 0, 
                                        textEncodingName: nil)
        let service = createTestService(mockSession)

        let expectation = XCTestExpectation(description: "Get the Payment Method - result should be unknown server error")
        expectation.assertForOverFulfill = true
        
        service.getPaymentMethod(sessionToken: "auth1234", merchantID: "1234567", paymentMethodRef: "ca29d3443f") { result in
            switch result {
            case .success:
                XCTFail("Expected unknown server error")
            case let .failure(error):
                let forageError = error as! ForageError
                XCTAssertEqual(forageError.code, "unknown_server_error")
                XCTAssertEqual(forageError.httpStatusCode, 500)
                XCTAssertEqual(forageError.message, "Unknown error. This is a problem on Forage’s end.")
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func test_getPayment_onSuccess_checkExpectedPayload() {
        let mockSession = URLSessionMock()
        mockSession.data = forageMocks.capturePaymentSuccess
        mockSession.response = forageMocks.mockSuccessResponse
        let service = createTestService(mockSession)

        let expectation = XCTestExpectation(description: "Get the Payment - should succeed")
        expectation.assertForOverFulfill = true
        service.getPayment(sessionToken: "auth1234", merchantID: "1234567", paymentRef: "11767381fd") { (result: Result<PaymentModel, Error>) in
            switch result {
            case let .success(payment):
                XCTAssertEqual(payment.paymentMethodRef, "81dab02290")
                XCTAssertEqual(payment.receipt?.refNumber, "11767381fd")
                XCTAssertEqual(payment.receipt?.balance?.snap, "90.00")
                XCTAssertEqual(payment.lastProcessingError, nil)
                XCTAssertEqual(payment.refunds[0], "9bf75154be")
                expectation.fulfill()
            case .failure:
                XCTFail("Expected success")
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func test_getThinPayment_onSuccess_checkExpectedPayload() {
        let mockSession = URLSessionMock()
        mockSession.data = forageMocks.capturePaymentSuccess
        mockSession.response = forageMocks.mockSuccessResponse
        let service = createTestService(mockSession)

        let expectation = XCTestExpectation(description: "Get the Payment - should succeed")
        expectation.assertForOverFulfill = true
        service.getPayment(sessionToken: "auth1234", merchantID: "1234567", paymentRef: "11767381fd") { (result: Result<ThinPaymentModel, Error>) in
            switch result {
            case let .success(payment):
                XCTAssertEqual(payment.paymentMethodRef, "81dab02290")
                expectation.fulfill()
            case .failure:
                XCTFail("Expected success")
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func test_getPayment_onFailure_shouldReturnFailure() {
        let mockSession = URLSessionMock()
        mockSession.error = forageMocks.getPaymentError
        mockSession.response = forageMocks.mockFailureResponse
        let service = createTestService(mockSession)

        let expectation = XCTestExpectation(description: "Get the Payment - result should be failure")
        expectation.assertForOverFulfill = true
        service.getPayment(sessionToken: "auth1234", merchantID: "1234567", paymentRef: "11767381fd") { (result: Result<PaymentModel, Error>) in
            switch result {
            case .success:
                XCTFail("Expected failure")
            case let .failure(error):
                XCTAssertNotNil(error)
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func test_getBalance_onSuccess_checkExpectedPayload() {
        _ = XCTSkip("Need to clean up and decouple checkBalance before we can test it properly")
    }

    func test_getBalance_onFailure_shouldReturnFailure() {
        _ = XCTSkip("Need to clean up and decouple checkBalance before we can test it properly")
    }

    func test_capturePayment_onSuccess_checkExpectedPayload() {
        _ = XCTSkip("Need to clean up and decouple capturePayment before we can test it properly")
    }

    func test_capturePayment_onFailure_shouldReturnFailure() {
        _ = XCTSkip("Need to clean up and decouple capturePayment before we can test it properly")
    }

    func test_getPaymentMethod_onNilData_shouldReturnInvalidInputDataError() {
        let mockSession = URLSessionMock()
        mockSession.data = nil
        mockSession.response = forageMocks.mockSuccessResponse
        let service = createTestService(mockSession)

        let expectation = XCTestExpectation(description: "Get the Payment Method - result should be invalid input data error")
        expectation.assertForOverFulfill = true
        
        service.getPaymentMethod(sessionToken: "auth1234", merchantID: "1234567", paymentMethodRef: "ca29d3443f") { result in
            switch result {
            case .success:
                XCTFail("Expected invalid input data error")
            case let .failure(error):
                let forageError = error as! ForageError
                XCTAssertEqual(forageError.code, "invalid_input_data")
                XCTAssertEqual(forageError.httpStatusCode, 200) // Using mockSuccessResponse's status code
                XCTAssertEqual(forageError.message, "Double check the reference documentation to validate the request body, and scan your implementation for any other errors.")
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func test_getPaymentMethod_onInvalidJSONData_shouldReturnUnknownServerError() {
        let mockSession = URLSessionMock()
        // Create invalid JSON data that can't be decoded
        mockSession.data = "Invalid JSON Data".data(using: .utf8)
        mockSession.response = forageMocks.mockSuccessResponse
        let service = createTestService(mockSession)

        let expectation = XCTestExpectation(description: "Get the Payment Method - result should be unknown server error")
        expectation.assertForOverFulfill = true
        
        service.getPaymentMethod(sessionToken: "auth1234", merchantID: "1234567", paymentMethodRef: "ca29d3443f") { result in
            switch result {
            case .success:
                XCTFail("Expected unknown server error")
            case let .failure(error):
                let forageError = error as! ForageError
                XCTAssertEqual(forageError.code, "unknown_server_error")
                XCTAssertEqual(forageError.httpStatusCode, 200) // Using mockSuccessResponse's status code
                XCTAssertEqual(forageError.message, "Could not decode payload - Invalid JSON Data")
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func test_getPaymentMethod_onForageServiceError_shouldReturnForageError() {
        let mockSession = URLSessionMock()
        let errorJSON = """
        {
            "path": "/api/payment_methods/test123/",
            "errors": [
                {
                    "code": "custom_error_code",
                    "message": "Custom error message",
                    "source": {
                        "resource": "Payment_Methods",
                        "ref": "test123"
                    }
                }
            ]
        }
        """
        mockSession.data = errorJSON.data(using: .utf8)
        mockSession.response = forageMocks.mockSuccessResponse
        let service = createTestService(mockSession)

        let expectation = XCTestExpectation(description: "Get the Payment Method - result should be forage service error")
        expectation.assertForOverFulfill = true
        
        service.getPaymentMethod(sessionToken: "auth1234", merchantID: "1234567", paymentMethodRef: "test123") { result in
            switch result {
            case .success:
                XCTFail("Expected forage service error")
            case let .failure(error):
                let forageError = error as! ForageError
                XCTAssertEqual(forageError.code, "custom_error_code")
                XCTAssertEqual(forageError.httpStatusCode, 200) // Using mockSuccessResponse's status code
                XCTAssertEqual(forageError.message, "Custom error message")
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }
}
