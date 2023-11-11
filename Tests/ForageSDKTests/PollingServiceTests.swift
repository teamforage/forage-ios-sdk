//
//  PollingServiceTests.swift
//
//
//  Created by Danilo Joksimovic on 2023-11-10.
//

@testable import ForageSDK
@testable import LaunchDarkly
import Foundation
import XCTest

class WithMockedWaitNextAttempt: LivePollingService {
    var maxAttempts: Int = 90
    var numTimesCalledWaitNextAttempt: Int = 0
    var didComplete: (() -> Bool) = { false }

    override func waitNextAttempt(completion: @escaping () -> Void) {
        super.incrementRetryCount()
        numTimesCalledWaitNextAttempt += 1
        completion() // complete immediately
    }

    override func getMessage(
        contentId: String,
        request: ForageRequestModel,
        completion: @escaping (Result<MessageResponseModel, Error>) -> Void
    ) {
        if didComplete() {
            completion(.success(MessageResponseModel(
                contentId: "test-completed-content-id",
                messageType: "0200",
                status: "completed",
                failed: false,
                errors: []
            )))
        } else {
            super.getMessage(contentId: contentId, request: request, completion: completion)
        }
    }
}

final class PollingServiceTests: XCTestCase {
    // MARK: Setup

    var forageMocks: ForageMocks!
    var mockLogger: MockLogger!

    private func createTestPollingService(
        _ mockSession: URLSessionMock = URLSessionMock()
    ) -> LivePollingService {
        WithMockedWaitNextAttempt(
            provider: Provider(mockSession),
            logger: mockLogger,
            ldManager: MockLDManager()
        )
    }

    override func setUp() {
        setUpForageSDK()
        mockLogger = MockLogger()
        forageMocks = ForageMocks()
    }

    private func setupTestWithMockData(
        mockData: Data? = nil,
        response: HTTPURLResponse? = nil,
        error: Error? = nil
    ) -> (LivePollingService, ForageRequestModel) {
        let mockSession = URLSessionMock()
        mockSession.data = mockData
        mockSession.response = response
        mockSession.error = error
        let pollingService = createTestPollingService(mockSession)

        let requestModel = ForageRequestModel(
            authorization: "testAuthorization",
            paymentMethodReference: "testPaymentMethodRef",
            paymentReference: "testPaymentRef",
            cardNumberToken: "testCardToken",
            merchantID: "testMerchantID",
            xKey: ["testKey": "testValue"]
        )

        return (pollingService, requestModel)
    }

    // MARK: test_execute - success

    func test_execute_Succeeds() async throws {
        let (pollingService, requestModel) = setupTestWithMockData(
            mockData: forageMocks.getMessageCompleted,
            response: forageMocks.mockSuccessResponse
        )

        let vaultResponse = VaultResponse(
            statusCode: 200,
            urlResponse: forageMocks.mockSuccessResponse,
            data: forageMocks.getMessageCompleted,
            error: nil
        )

        _ = try await awaitResult { completion in
            pollingService.execute(
                vaultResponse: vaultResponse,
                request: requestModel,
                completion: completion
            )
        }

        // did not throw!
        XCTAssertTrue(true)
    }

    // MARK: test_execute - errors

    func test_execute_MalformedVaultResponseFromForage() {
        let (pollingService, requestModel) = setupTestWithMockData(
            mockData: forageMocks.getMessageCompleted,
            response: forageMocks.mockSuccessResponse
        )

        // Vault responds with (incomplete) "sent_to_proxy" response
        let vaultResponse = VaultResponse(
            statusCode: 400,
            urlResponse: forageMocks.mockFailureResponse,
            data: forageMocks.getMessageUnauthorized,
            error: nil
        )

        let expectation = XCTestExpectation(description: "getMessage should fail")

        pollingService.execute(
            vaultResponse: vaultResponse,
            request: requestModel
        ) { result in
            switch result {
            case .success:
                XCTFail("Expected failure, but got success")
            case let .failure(error):
                guard let firstError = (error as! ForageError).errors.first else {
                    XCTFail("Expected a ForageError")
                    return
                }
                XCTAssertEqual(self.mockLogger.lastErrorMsg, "Failed to process vault proxy response for capture of Payment testPaymentMethodRef")
                XCTAssertEqual(firstError.code, "missing_merchant_account")
                XCTAssertEqual(firstError.httpStatusCode, 400)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func test_execute_vaultSucceeded_getMessageFailed() async throws {
        // getMessage responds with failed message
        let (pollingService, requestModel) = setupTestWithMockData(
            mockData: forageMocks.getMessageFailed,
            response: forageMocks.mockFailureResponse
        )

        // Vault responds with (incomplete) "sent_to_proxy" response
        let vaultResponse = VaultResponse(
            statusCode: 200,
            urlResponse: forageMocks.mockSuccessResponse,
            data: forageMocks.getMessageIncomplete,
            error: nil
        )

        do {
            _ = try await awaitResult { completion in
                pollingService.execute(
                    vaultResponse: vaultResponse,
                    request: requestModel,
                    completion: completion
                )
            }
        } catch let error as ForageError {
            guard let firstError = error.errors.first else {
                XCTFail("Expected a ForageError")
                return
            }

            XCTAssertEqual(mockLogger.lastErrorMsg, "Received SQS Error message for capture of Payment testPaymentMethodRef")
            XCTAssertEqual(firstError.code, "ebt_error_51")
            XCTAssertEqual(firstError.httpStatusCode, 400)
        }
    }

    func test_execute_MalformedVaultResponseFromVault() async throws {
        let (pollingService, requestModel) = setupTestWithMockData()

        let malformedVaultResponse = VaultResponse(statusCode: 400, urlResponse: nil, data: nil, error: nil)

        do {
            _ = try await awaitResult { completion in
                pollingService.execute(
                    vaultResponse: malformedVaultResponse,
                    request: requestModel,
                    completion: completion
                )
            }
        } catch let error as ForageError {
            guard let firstError = error.errors.first else {
                XCTFail("Expected a ForageError")
                return
            }

            XCTAssertEqual(mockLogger.lastErrorMsg, "Response from vault proxy was malformed: VaultResponse(statusCode: Optional(400), urlResponse: nil, data: nil, error: nil)")
            XCTAssertEqual(firstError.code, "unknown_server_error")
            XCTAssertEqual(firstError.httpStatusCode, 500)
        }
    }

    // MARK: test_getMessage - success

    func test_getMessage_SuccessCompleted() async throws {
        let (pollingService, requestModel) = setupTestWithMockData(
            mockData: forageMocks.getMessageCompleted,
            response: forageMocks.mockSuccessResponse
        )

        let messageResponseModel = try await awaitResult { completion in
            pollingService.getMessage(contentId: "testContentId", request: requestModel, completion: completion)
        }

        XCTAssertEqual(messageResponseModel.contentId, "d789c086-9c4f-41c3-854a-1c436eee1d63")
        XCTAssertEqual(messageResponseModel.messageType, "0200")
        XCTAssertEqual(messageResponseModel.status, "completed")
        XCTAssertEqual(messageResponseModel.failed, false)
        XCTAssertEqual(messageResponseModel.errors.isEmpty, true)
    }

    // MARK: test_getMessage - error scenarios

    func test_getMessage_Unauthorized() async throws {
        let (pollingService, requestModel) = setupTestWithMockData(
            mockData: forageMocks.getMessageUnauthorized,
            response: forageMocks.mockFailureResponse
        )

        do {
            _ = try await awaitResult { completion in
                pollingService.getMessage(
                    contentId: "testContentId",
                    request: requestModel,
                    completion: completion
                )
            }
            XCTFail("Expected unauthorized error, but got success")
        } catch let error as ForageError {
            guard let firstError = error.errors.first else {
                XCTFail("Expected a ForageError")
                return
            }
            XCTAssertEqual(firstError.code, "missing_merchant_account")
            XCTAssertEqual(firstError.httpStatusCode, 400)
            XCTAssertEqual(firstError.message, "No merchant account FNS number was provided.")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_getMessage_ExpiredCard() async throws {
        let (pollingService, requestModel) = setupTestWithMockData(
            mockData: forageMocks.getMessageExpiredCard,
            response: forageMocks.mockFailureResponse
        )

        do {
            _ = try await awaitResult { completion in
                pollingService.getMessage(
                    contentId: "testContentId",
                    request: requestModel,
                    completion: completion
                )
            }
            XCTFail("Expected unauthorized error, but got success")
        } catch let error as ForageError {
            guard let firstError = error.errors.first else {
                XCTFail("Expected a ForageError")
                return
            }
            XCTAssertEqual(firstError.code, "ebt_error_54")
            XCTAssertEqual(firstError.httpStatusCode, 400)
            XCTAssertEqual(firstError.message, "Expired card - Expired Card")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_getMessage_FailedResponse() async throws {
        let (pollingService, requestModel) = setupTestWithMockData(
            mockData: forageMocks.getMessageFailed,
            response: forageMocks.mockFailureResponse
        )

        do {
            _ = try await awaitResult { completion in
                pollingService.getMessage(
                    contentId: "testContentId",
                    request: requestModel,
                    completion: completion
                )
            }
            XCTFail("Expected unauthorized error, but got success")
        } catch let error as ForageError {
            guard let firstError = error.errors.first else {
                XCTFail("Expected a ForageError")
                return
            }
            XCTAssertEqual(firstError.code, "ebt_error_51")
            XCTAssertEqual(firstError.httpStatusCode, 400)
            XCTAssertEqual(firstError.message, "Received failure response from EBT network")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_getMessage_MalformedResponse() {
        // Received an invalid response (e.g. decode error)
        let (pollingService, requestModel) = setupTestWithMockData(
            mockData: nil,
            response: forageMocks.mockFailureResponse,
            error: forageMocks.generalError
        )

        let expectation = XCTestExpectation(description: "getMessage should fail")

        pollingService.getMessage(
            contentId: "testContentId",
            request: requestModel
        ) { result in
            switch result {
            case .success:
                XCTFail("Expected failure, but got success")
            case let .failure(error):
                XCTAssertNotNil(error)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: test_getMessage - retry logic

    func test_getMessage_CompletesAfterRetries() async throws {
        let (pollingService, requestModel) = setupTestWithMockData(
            // we start with status: "sent_to_proxy" (incomplete)
            // to force retries
            mockData: forageMocks.getMessageIncomplete,
            response: forageMocks.mockSuccessResponse
        )

        let mockedPollingService = pollingService as! WithMockedWaitNextAttempt
        // set a bound to make sure this test case doesn't hang indefinetely if it breaks
        mockedPollingService.maxAttempts = 10

        mockedPollingService.didComplete = {
            // Change to "completed" after 3 retries
            let changeResponseAfterRetries = 3
            if mockedPollingService.numTimesCalledWaitNextAttempt >= changeResponseAfterRetries {
                return true
            }
            return false
        }

        do {
            let message = try await awaitResult { completion in
                mockedPollingService.getMessage(
                    contentId: "test-completed-content-id",
                    request: requestModel,
                    completion: completion
                )
            }
            XCTAssertEqual(message.contentId, "test-completed-content-id")
            XCTAssertEqual(mockedPollingService.numTimesCalledWaitNextAttempt, 3)
        } catch {
            XCTFail("getMessage Failed")
        }
    }

    func test_getMessage_ReachedMaxAttempts() async throws {
        let (pollingService, requestModel) = setupTestWithMockData(
            // we continue to retry until we see status: "completed"
            // but here we permantly set the status to: "sent_to_proxy"
            mockData: forageMocks.getMessageIncomplete,
            response: forageMocks.mockSuccessResponse
        )

        // force reaching max attempts
        (pollingService as! WithMockedWaitNextAttempt).maxAttempts = -1

        do {
            _ = try await awaitResult { completion in
                pollingService.getMessage(
                    contentId: "testContentId",
                    request: requestModel,
                    completion: completion
                )
            }

            XCTFail("Expected failure, but got success")
        } catch let error as ForageError {
            guard let firstError = error.errors.first else {
                XCTFail("Expected a ForageError")
                return
            }
            XCTAssertEqual(firstError.code, "unknown_server_error")
            XCTAssertEqual(firstError.httpStatusCode, 500)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: test_getJitterAmountInSeconds

    func test_getJitterAmountInSeconds() {
        let mockSession = URLSessionMock()
        let pollingService = LivePollingService(
            provider: Provider(mockSession),
            ldManager: MockLDManager()
        )

        let jitterAmount = pollingService.jitterAmountInSeconds()

        XCTAssertNotNil(jitterAmount, "Jitter amount should not be nil")
        XCTAssertTrue(jitterAmount >= -0.025 && jitterAmount <= 0.025)
    }

    // MARK: test_WaitNextAttempt

    func test_WaitNextAttempt_defaultIntervals() {
        let mockSession = URLSessionMock()
        let pollingService = LivePollingService(
            provider: Provider(mockSession),
            ldManager: MockLDManager()
        )

        let failureExpectation = XCTestExpectation(description: "Completion called before delay")
        let successExpectation = XCTestExpectation(description: "Completion called after delay")

        // Mark the expectation as fulfilled only if it failed
        failureExpectation.isInverted = true

        pollingService.waitNextAttempt {
            failureExpectation.fulfill()
            successExpectation.fulfill()
        }

        // Ensure that the failureExpectation wasn't fulfilled in the extremely short period of time
        wait(for: [failureExpectation], timeout: 0.95)
        // Ensure that the successExpectation was fulfilled before the longer period of time
        wait(for: [successExpectation], timeout: 1.05)
    }

    func test_waitNextAttempt_noPollingIntervals() {
        let mockSession = URLSessionMock()

        let failureExpectation = XCTestExpectation(description: "Completion called before delay")
        let successExpectation = XCTestExpectation(description: "Completion called after delay")

        // Mark the expectation as fulfilled only if it failed
        failureExpectation.isInverted = true

        let pollingService = MockPollingService(provider: Provider(mockSession), ldManager: MockLDManager(pollingIntervals: []))

        pollingService.waitNextAttempt {
            failureExpectation.fulfill()
            successExpectation.fulfill()
        }

        // Ensure that the failureExpectation wasn't fulfilled in the extremely short period of time
        wait(for: [failureExpectation], timeout: 0.95)
        // Ensure that the successExpectation was fulfilled before the longer period of time
        wait(for: [successExpectation], timeout: 1.05)
    }

    func test_waitNextAttempt_shorterIntervals() {
        let mockSession = URLSessionMock()

        let failureExpectation = XCTestExpectation(description: "Completion called before delay")
        let successExpectation = XCTestExpectation(description: "Completion called after delay")

        // Mark the expectation as fulfilled only if it failed
        failureExpectation.isInverted = true

        let pollingService = MockPollingService(provider: Provider(mockSession), ldManager: MockLDManager(pollingIntervals: [100]))

        pollingService.waitNextAttempt {
            successExpectation.fulfill()
            failureExpectation.fulfill()
        }

        // Ensure that the failureExpectation wasn't fulfilled in the extremely short period of time
        wait(for: [failureExpectation], timeout: 0.09)
        // Ensure that the successExpectation was fulfilled before the longer period of time
        wait(for: [successExpectation], timeout: 0.11)
    }
}
