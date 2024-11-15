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

    func test_tokenizeEBTCard_onSuccess_checkExpectedPayload() {
        let mockSession = URLSessionMock()
        mockSession.data = forageMocks.tokenizeSuccess
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
        mockSession.error = forageMocks.tokenizeFailure
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

    func test_getPayment_onSuccess_checkExpectedPayload() {
        let mockSession = URLSessionMock()
        mockSession.data = forageMocks.capturePaymentSuccess
        mockSession.response = forageMocks.mockSuccessResponse
        let service = createTestService(mockSession)

        let expectation = XCTestExpectation(description: "Get the Payment - should succeed")
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
}
