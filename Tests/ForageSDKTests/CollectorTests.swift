//
//  CollectorTests.swift
//
//
//  Created by Shardendu Gautam on 6/26/23.
//  © 2023-Present Forage Technology Corporation. All rights reserved.
//

@testable import ForageSDK
import Foundation
import XCTest

class VaultCollectorTests: XCTestCase {
    override func setUp() {
        setUpForageSDK()
    }

    func createMockVaultMonitor() -> TestableResponseMonitor {
        TestableResponseMonitor(metricsLogger: MockLogger())
    }

    // MARK: ForageWrapper

    func testRosettaSubmitter_VaultConfigBaseURL() {
        var config = ForageVaultConfig(environment: .dev)
        XCTAssertEqual(config.vaultBaseURL, "vault.dev.joinforage.app")
        config = ForageVaultConfig(environment: .staging)
        XCTAssertEqual(config.vaultBaseURL, "vault.staging.joinforage.app")
        config = ForageVaultConfig(environment: .sandbox)
        XCTAssertEqual(config.vaultBaseURL, "vault.sandbox.joinforage.app")
        config = ForageVaultConfig(environment: .cert)
        XCTAssertEqual(config.vaultBaseURL, "vault.cert.joinforage.app")
        config = ForageVaultConfig(environment: .prod)
        XCTAssertEqual(config.vaultBaseURL, "vault.joinforage.app")
    }

    func testRosettaSubmitter_GetValidatedPIN() {
        let textElement = UITextField()
        let rosettaSubmitter = CollectorFactory.createRosettaPINSubmitter(environment: .sandbox, textElement: textElement)

        // valid pin, should return pin
        textElement.text = "1234"
        var result = rosettaSubmitter.getValidatedPIN()
        XCTAssertEqual(result, "1234")

        // too short, should return nil
        textElement.text = "12"
        result = rosettaSubmitter.getValidatedPIN()
        XCTAssertNil(result)

        // includes non-numeric characters, should return nil
        textElement.text = "ab12"
        result = rosettaSubmitter.getValidatedPIN()
        XCTAssertNil(result)
    }

    func testRosettaSubmitter_SetCustomHeaders_HeaderKey() {
        let textElement = UITextField()
        let rosettaSubmitter = CollectorFactory.createRosettaPINSubmitter(environment: Environment.sandbox, textElement: textElement)

        let headers = ["HeaderKey": "HeaderValue"]
        rosettaSubmitter.setCustomHeaders(headers: headers)

        XCTAssertEqual(rosettaSubmitter.customHeaders["HeaderKey"], "HeaderValue")
    }

    func testRosettaSubmitter_BuildRequestBody_Error() {
        let rosettaSubmitter = CollectorFactory.createRosettaPINSubmitter(environment: .sandbox, textElement: UITextField())
        XCTAssertThrowsError(try rosettaSubmitter.buildRequestBody(with: ["card_number_token": ""]))
    }

    func testRosettaSubmitter_BuildRequestBody_Success() throws {
        let rosettaSubmitter = CollectorFactory.createRosettaPINSubmitter(environment: .sandbox, textElement: UITextField())
        let data = ["card_number_token": "1,2,3"]
        let body = try rosettaSubmitter.buildRequestBody(with: data)
        XCTAssertEqual(body, ["card_number_token": "3"])
    }

    func testRosettaSubmitter_BuildRequest() {
        let rosettaSubmitter = CollectorFactory.createRosettaPINSubmitter(environment: .sandbox, textElement: UITextField())
        rosettaSubmitter.customHeaders = ["Session-Token": "some-session-token", "Something": "Else"]
        let request = rosettaSubmitter.buildRequest(for: "/test/path")

        XCTAssertEqual(request.url, URL(string: "https://vault.sandbox.joinforage.app/proxy/test/path"))
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.allHTTPHeaderFields, [
            "Content-Type": "application/json",
            "Authorization": "some-session-token",
            "Something": "Else"
        ])
        XCTAssertFalse(request.allHTTPHeaderFields?.contains(where: { (key: String, _: String) in
            key == "Session-Token"
        }) ?? true)
    }

    func testRosettaSubmitter_GetPaymentMethodToken_Success() throws {
        let textElement = UITextField()
        let rosettaSubmitter = CollectorFactory.createRosettaPINSubmitter(environment: Environment.sandbox, textElement: textElement)

        let token = "123456,789012,345678"
        let resultToken = try rosettaSubmitter.getPaymentMethodToken(paymentMethodToken: token)
        XCTAssertEqual(resultToken, "345678")
    }

    func testRosettaSubmitter_GetPaymentMethodToken_NoDelimiterError() throws {
        let textElement = UITextField()
        let rosettaSubmitter = CollectorFactory.createRosettaPINSubmitter(environment: Environment.sandbox, textElement: textElement)

        let token = "123456"
        XCTAssertThrowsError(try rosettaSubmitter.getPaymentMethodToken(paymentMethodToken: token))
    }

    func testRosettaSubmitter_GetPaymentMethodToken_NoRosettaError() throws {
        let textElement = UITextField()
        let rosettaSubmitter = CollectorFactory.createRosettaPINSubmitter(environment: Environment.sandbox, textElement: textElement)

        let token = "123456,789012"
        XCTAssertThrowsError(try rosettaSubmitter.getPaymentMethodToken(paymentMethodToken: token))
    }

    func testRosettaSubmitter_GetPaymentMethodToken_EmptyRosettaError() throws {
        let textElement = UITextField()
        let rosettaSubmitter = CollectorFactory.createRosettaPINSubmitter(environment: Environment.sandbox, textElement: textElement)

        let token = "123456,789012,"
        XCTAssertThrowsError(try rosettaSubmitter.getPaymentMethodToken(paymentMethodToken: token))
    }

    func testRosettaSubmitter_sendData_PaymentMethodTokenError() {
        let textElement = UITextField()
        let config = ForageVaultConfig(environment: .sandbox)
        let logger = MockLogger()
        let session = URLSessionMock()
        let rosettaSubmitter = RosettaPINSubmitter(textElement: textElement, forageVaultConfig: config, logger: logger, session: session)

        let expectation = expectation(description: "Completion handler called")

        rosettaSubmitter.sendData(path: "/test/path", vaultAction: .balanceCheck, extraData: ["card_number_token": "1,2"]) { (result: MockDecodableModel?, error: ForageError?) in
            XCTAssertNil(result)
            XCTAssertEqual(error?.code, "unknown_server_error")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1)

        XCTAssertEqual(logger.lastCriticalMessage, "Failed to send data to Rosetta proxy. Rosetta token not found on card")
        XCTAssertNil(session.lastRequest)
    }

    func testRosettaSubmitter_sendData_IncompletePINError() {
        let textElement = UITextField()
        let config = ForageVaultConfig(environment: .sandbox)
        let logger = MockLogger()
        let session = URLSessionMock()
        let rosettaSubmitter = RosettaPINSubmitter(textElement: textElement, forageVaultConfig: config, logger: logger, session: session)

        textElement.text = "12"

        let expectation = expectation(description: "Completion handler called")

        rosettaSubmitter.sendData(path: "/test/path", vaultAction: .balanceCheck, extraData: ["card_number_token": "1,2,3"]) { (result: MockDecodableModel?, error: ForageError?) in
            XCTAssertNil(result)
            XCTAssertEqual(error?.code, "user_error")
            XCTAssertEqual(error?.httpStatusCode, 400)
            XCTAssertEqual(error?.message, "Invalid EBT Card PIN entered. Please enter your 4-digit PIN.")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1)

        XCTAssertNil(session.lastRequest)
    }

    func testRosettaSubmitter_sendData_VaultProxyCallSuccess() {
        let textElement = UITextField()
        let config = ForageVaultConfig(environment: .sandbox)
        let logger = MockLogger()
        let session = URLSessionMock()
        let rosettaSubmitter = RosettaPINSubmitter(textElement: textElement, forageVaultConfig: config, logger: logger, session: session)

        rosettaSubmitter.customHeaders = [
            "Session-Token": "test session token",
            "Merchant-Account": "mid/test-merchant-id"
        ]
        textElement.text = "1234"

        let expectation = expectation(description: "Completion handler called")

        rosettaSubmitter.sendData(path: "/test/path", vaultAction: .balanceCheck, extraData: ["card_number_token": "1,2,3"]) { (_: MockDecodableModel?, _: ForageError?) in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)

        let url = URL(string: "https://vault.sandbox.joinforage.app/proxy/test/path")!
        let expectedBody = ["card_number_token": "3", "pin": "1234"]
        let actualBody = try! JSONSerialization.jsonObject(with: (session.lastRequest?.httpBody)!) as! [String: String]

        XCTAssertEqual(session.lastRequest?.url, url)
        XCTAssertEqual(session.lastRequest?.httpMethod, "POST")
        XCTAssertEqual(actualBody, expectedBody)
        XCTAssertEqual(session.lastRequest?.allHTTPHeaderFields, [
            "Content-Type": "application/json",
            "Authorization": "test session token",
            "Merchant-Account": "mid/test-merchant-id"
        ])
        XCTAssertFalse(session.lastRequest?.allHTTPHeaderFields?.contains(where: { (key: String, _: String) in
            key == "Session-Token"
        }) ?? true)
    }

    func testRosettaSubmitter_handleResponse_rosettaError() {
        let textElement = UITextField()
        let config = ForageVaultConfig(environment: .sandbox)
        let logger = MockLogger()
        let rosettaSubmitter = RosettaPINSubmitter(textElement: textElement, forageVaultConfig: config, logger: logger)
        let response = HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: 500, httpVersion: nil, headerFields: nil)
        let measurement = createMockVaultMonitor()
        let testRosettaError = CommonErrors.UNKNOWN_SERVER_ERROR

        // this is called by sendData, so we have to simulate that since we're only calling handleResponse in this test
        measurement.start()

        rosettaSubmitter.handleResponse(response: response, data: nil, error: testRosettaError, measurement: measurement) { (result: MockDecodableModel?, error: ForageError?) in
            XCTAssertNil(result)
            XCTAssertEqual(error, CommonErrors.UNKNOWN_SERVER_ERROR)
            XCTAssertEqual(logger.lastErrorMsg, "Rosetta proxy failed with an error")
        }

        XCTAssertNotNil(measurement.lastLoggedAttributes?.responseTimeMs)
        XCTAssertEqual(measurement.lastLoggedAttributes?.code, 500)
    }

    func testRosettaSubmitter_handleResponse_noData() {
        let textElement = UITextField()
        let config = ForageVaultConfig(environment: .sandbox)
        let logger = MockLogger()
        let measurement = createMockVaultMonitor()
        let rosettaSubmitter = RosettaPINSubmitter(textElement: textElement, forageVaultConfig: config, logger: logger)
        let response = HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: 500, httpVersion: nil, headerFields: nil)

        // this is called by sendData, so we have to simulate that since we're only calling handleResponse in this test
        measurement.start()

        rosettaSubmitter.handleResponse(response: response, data: nil, error: nil, measurement: measurement) { (result: MockDecodableModel?, error: ForageError?) in
            XCTAssertNil(result)
            XCTAssertEqual(error, CommonErrors.UNKNOWN_SERVER_ERROR)
            XCTAssertEqual(logger.lastCriticalMessage, "Rosetta failed to respond with a data object")
        }

        XCTAssertNotNil(measurement.lastLoggedAttributes?.responseTimeMs)
        XCTAssertEqual(measurement.lastLoggedAttributes?.code, 500)
    }

    func testRosettaSubmitter_handleResponse_204Success() {
        let textElement = UITextField()
        let config = ForageVaultConfig(environment: .sandbox)
        let logger = MockLogger()
        let measurement = createMockVaultMonitor()
        let rosettaSubmitter = RosettaPINSubmitter(textElement: textElement, forageVaultConfig: config, logger: logger)
        let response = HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: 204, httpVersion: nil, headerFields: nil)

        // this is called by sendData, so we have to simulate that since we're only calling handleResponse in this test
        measurement.start()

        let mockData = "".data(using: .utf8)!

        rosettaSubmitter.handleResponse(response: response, data: mockData, error: nil, measurement: measurement) { (result: MockDecodableModel?, error: ForageError?) in
            XCTAssertNil(result)
            XCTAssertNil(error)
        }

        XCTAssertNotNil(measurement.lastLoggedAttributes?.responseTimeMs)
        XCTAssertEqual(measurement.lastLoggedAttributes?.code, 204)
    }

    func testRosettaSubmitter_handleResponse_429Error() {
        let textElement = UITextField()
        let config = ForageVaultConfig(environment: .sandbox)
        let logger = MockLogger()
        let measurement = createMockVaultMonitor()
        let rosettaSubmitter = RosettaPINSubmitter(textElement: textElement, forageVaultConfig: config, logger: logger)
        let response = HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: 429, httpVersion: nil, headerFields: nil)

        // this is called by sendData, so we have to simulate that since we're only calling handleResponse in this test
        measurement.start()

        let mockData = """
        {
            "path": "test/path",
            "errors": [
                {
                    "code": "too_many_requests",
                    "message": "Request was throttled, please try again later."
                }
            ]
        }
        """.data(using: .utf8)!

        rosettaSubmitter.handleResponse(response: response, data: mockData, error: nil, measurement: measurement) { (result: MockDecodableModel?, error: ForageError?) in
            XCTAssertNil(result)
            XCTAssertEqual(error, THROTTLE_ERROR)
        }

        XCTAssertNotNil(measurement.lastLoggedAttributes?.responseTimeMs)
        XCTAssertEqual(measurement.lastLoggedAttributes?.code, 429)
    }

    func testRosettaSubmitter_handleResponse_invalidData() {
        let textElement = UITextField()
        let config = ForageVaultConfig(environment: .sandbox)
        let logger = MockLogger()
        let measurement = createMockVaultMonitor()
        let rosettaSubmitter = RosettaPINSubmitter(textElement: textElement, forageVaultConfig: config, logger: logger)
        let response = HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: 500, httpVersion: nil, headerFields: nil)

        // this is called by sendData, so we have to simulate that since we're only calling handleResponse in this test
        measurement.start()

        let mockData = """
        {
            "this": "is invalid"
        }
        """.data(using: .utf8)!

        rosettaSubmitter.handleResponse(response: response, data: mockData, error: nil, measurement: measurement) { (result: MockDecodableModel?, error: ForageError?) in
            XCTAssertNil(result)
            XCTAssertEqual(error, CommonErrors.UNKNOWN_SERVER_ERROR)
            XCTAssertEqual(logger.lastCriticalMessage, "Failed to decode Rosetta response data.")
        }

        XCTAssertNotNil(measurement.lastLoggedAttributes?.responseTimeMs)
        XCTAssertEqual(measurement.lastLoggedAttributes?.code, 500)
    }

    func testRosettaSubmitter_handleResponse_validData() {
        let textElement = UITextField()
        let config = ForageVaultConfig(environment: .sandbox)
        let logger = MockLogger()
        let measurement = createMockVaultMonitor()
        let rosettaSubmitter = RosettaPINSubmitter(textElement: textElement, forageVaultConfig: config, logger: logger)
        let response = HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)

        // this is called by sendData, so we have to simulate that since we're only calling handleResponse in this test
        measurement.start()

        let mockData = """
        {
            "id": "12345"
        }
        """.data(using: .utf8)!

        rosettaSubmitter.handleResponse(response: response, data: mockData, error: nil, measurement: measurement) { (result: MockDecodableModel?, error: ForageError?) in
            XCTAssertNil(error)
            XCTAssertEqual(result, MockDecodableModel(id: "12345"))
        }

        XCTAssertNotNil(measurement.lastLoggedAttributes?.responseTimeMs)
        XCTAssertEqual(measurement.lastLoggedAttributes?.code, 200)
    }
}
