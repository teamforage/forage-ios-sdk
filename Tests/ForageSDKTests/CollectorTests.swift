//
//  CollectorTests.swift
//
//
//  Created by Shardendu Gautam on 6/26/23.
//  Copyright © 2023-Present Forage Technology Corporation. All rights reserved.
//

@testable import ForageSDK
import BasisTheoryElements
import Foundation
import VGSCollectSDK
import XCTest

class VaultCollectorTests: XCTestCase {
    override func setUp() {
        setUpForageSDK()
    }
    
    func createMockVaultMonitor() -> TestableResponseMonitor {
        TestableResponseMonitor(metricsLogger: MockLogger())
    }
    
    // MARK: VGSWrapper

    func testVGSCollectWrapper_SetCustomHeaders_HeaderKey() {
        let vgsWrapper = CollectorFactory.createVGS(environment: Environment.sandbox)

        let headers = ["HeaderKey": "HeaderValue"]
        let xKey = ["vgsXKey": "VgsXKeyValue"]
        vgsWrapper.setCustomHeaders(headers: headers, xKey: xKey)

        XCTAssertEqual(vgsWrapper.vgsCollect.customHeaders?["HeaderKey"], "HeaderValue")
    }

    func testVGSCollectWrapper_SetCustomHeaders_XKey() {
        let vgsWrapper = CollectorFactory.createVGS(environment: Environment.sandbox)

        let headers = ["HeaderKey": "HeaderValue"]
        let xKey = ["vgsXKey": "VgsXKeyValue"]
        vgsWrapper.setCustomHeaders(headers: headers, xKey: xKey)

        XCTAssertEqual(vgsWrapper.vgsCollect.customHeaders?["X-KEY"], "VgsXKeyValue")
    }

    func testVGSCollectWrapper_handleResponse_vgsError() {
        let config = VGSCollectConfig(id: "identifier", environment: .sandbox)
        let logger = MockLogger()
        let vgsWrapper = VGSCollectWrapper(config: config, logger: logger)

        let vgsError = CommonErrors.UNKNOWN_SERVER_ERROR

        vgsWrapper.handleResponse(code: 500, data: nil, error: vgsError, measurement: createMockVaultMonitor()) { (result: MockDecodableModel?, error: ForageError?) in
            XCTAssertNil(result)
            XCTAssertEqual(error, CommonErrors.UNKNOWN_SERVER_ERROR)
            XCTAssertEqual(logger.lastCriticalMessage, "VGS proxy failed with an error")
        }
    }

    func testVGSCollectWrapper_handleResponse_noData() {
        let config = VGSCollectConfig(id: "identifier", environment: .sandbox)
        let logger = MockLogger()
        let vgsWrapper = VGSCollectWrapper(config: config, logger: logger)

        vgsWrapper.handleResponse(code: 500, data: nil, error: nil, measurement: createMockVaultMonitor()) { (result: MockDecodableModel?, error: ForageError?) in
            XCTAssertNil(result)
            XCTAssertEqual(error, CommonErrors.UNKNOWN_SERVER_ERROR)
            XCTAssertEqual(logger.lastCriticalMessage, "VGS failed to respond with a data object")
        }
    }

    func testVGSCollectWrapper_handleResponse_forageServiceError() {
        let config = VGSCollectConfig(id: "identifier", environment: .sandbox)
        let logger = MockLogger()
        let vgsWrapper = VGSCollectWrapper(config: config, logger: logger)

        let forageErrorData = """
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

        vgsWrapper.handleResponse(code: 429, data: forageErrorData, error: nil, measurement: createMockVaultMonitor()) { (result: MockDecodableModel?, error: ForageError?) in
            XCTAssertNil(result)
            XCTAssertEqual(error, THROTTLE_ERROR)
        }
    }

    func testVGSCollectWrapper_handleResponse_204Success() {
        let config = VGSCollectConfig(id: "identifier", environment: .sandbox)
        let logger = MockLogger()
        let vgsWrapper = VGSCollectWrapper(config: config, logger: logger)

        vgsWrapper.handleResponse(code: 204, data: "".data(using: .utf8)!, error: nil, measurement: createMockVaultMonitor()) { (result: MockDecodableModel?, error: ForageError?) in
            XCTAssertNil(result)
            XCTAssertNil(error)
        }
    }

    func testVGSCollectWrapper_handleResponse_success() {
        let config = VGSCollectConfig(id: "identifier", environment: .sandbox)
        let logger = MockLogger()
        let vgsWrapper = VGSCollectWrapper(config: config, logger: logger)

        let validData = """
        {
            "id": "12345"
        }
        """.data(using: .utf8)!

        let expectedModel = MockDecodableModel(id: "12345")
        vgsWrapper.handleResponse(code: 200, data: validData, error: nil, measurement: createMockVaultMonitor()) { (result: MockDecodableModel?, error: ForageError?) in
            XCTAssertNil(error)
            XCTAssertEqual(result, expectedModel)
        }
    }

    func testVGSCollectWrapper_handleResponse_invalidResponseStructure() {
        let config = VGSCollectConfig(id: "identifier", environment: .sandbox)
        let logger = MockLogger()
        let vgsWrapper = VGSCollectWrapper(config: config, logger: logger)

        let invalidData = """
        {
            "this": "is invalid"
        }
        """.data(using: .utf8)!

        vgsWrapper.handleResponse(code: 200, data: invalidData, error: nil, measurement: createMockVaultMonitor()) { (result: MockDecodableModel?, error: ForageError?) in
            XCTAssertNil(result)
            XCTAssertEqual(error, CommonErrors.UNKNOWN_SERVER_ERROR)
            XCTAssertEqual(logger.lastCriticalMessage, "Failed to decode VGS response data.")
        }
    }
    
    // MARK: BasisTheoryWrapper

    func testBasisTheoryWrapper_SetCustomHeaders_HeaderKey() {
        let textElement = TextElementUITextField()
        let basisTheoryWrapper = CollectorFactory.createBasisTheory(environment: Environment.sandbox, textElement: textElement)

        let headers = ["HeaderKey": "HeaderValue"]
        let xKey = ["btXKey": "btXKeyValue"]
        basisTheoryWrapper.setCustomHeaders(headers: headers, xKey: xKey)

        XCTAssertEqual(basisTheoryWrapper.customHeaders["HeaderKey"], "HeaderValue")
    }

    func testBasisTheoryWrapper_SetCustomHeaders_XKey() {
        let textElement = TextElementUITextField()
        let basisTheoryWrapper = CollectorFactory.createBasisTheory(environment: Environment.sandbox, textElement: textElement)

        let headers = ["HeaderKey": "HeaderValue"]
        let xKey = ["btXKey": "btXKeyValue"]
        basisTheoryWrapper.setCustomHeaders(headers: headers, xKey: xKey)

        XCTAssertEqual(basisTheoryWrapper.customHeaders["X-KEY"], "btXKeyValue")
    }

    func testBasisTheoryWrapper_GetPaymentMethodToken() throws {
        let textElement = TextElementUITextField()
        let basisTheoryWrapper = CollectorFactory.createBasisTheory(environment: Environment.sandbox, textElement: textElement)

        let token = "123456,789012"
        let resultToken = try basisTheoryWrapper.getPaymentMethodToken(paymentMethodToken: token)
        XCTAssertEqual(resultToken, "789012")
    }

    func testBasisTheoryWrapper_handleResponse_btError() {
        let textElement = TextElementUITextField()
        let config = BasisTheoryConfig(publicKey: "key1", proxyKey: "key2")
        let logger = MockLogger()
        let basisTheoryWrapper = BasisTheoryWrapper(textElement: textElement, basisTheoryconfig: config, logger: logger)
        let response = HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: 500, httpVersion: nil, headerFields: nil)

        let testBTError = CommonErrors.UNKNOWN_SERVER_ERROR

        basisTheoryWrapper.handleResponse(response: response, data: nil, error: testBTError, measurement: createMockVaultMonitor()) { (result: MockDecodableModel?, error: ForageError?) in
            XCTAssertNil(result)
            XCTAssertEqual(error, CommonErrors.UNKNOWN_SERVER_ERROR)
            XCTAssertEqual(logger.lastCriticalMessage, "Basis Theory proxy failed with an error")
        }
    }

    func testBasisTheoryWrapper_handleResponse_noData() {
        let textElement = TextElementUITextField()
        let config = BasisTheoryConfig(publicKey: "key1", proxyKey: "key2")
        let logger = MockLogger()
        let basisTheoryWrapper = BasisTheoryWrapper(textElement: textElement, basisTheoryconfig: config, logger: logger)
        let response = HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: 500, httpVersion: nil, headerFields: nil)

        basisTheoryWrapper.handleResponse(response: response, data: nil, error: nil, measurement: createMockVaultMonitor()) { (result: MockDecodableModel?, error: ForageError?) in
            XCTAssertNil(result)
            XCTAssertEqual(error, CommonErrors.UNKNOWN_SERVER_ERROR)
            XCTAssertEqual(logger.lastCriticalMessage, "Basis Theory failed to respond with a data object")
        }
    }

    func testBasisTheoryWrapper_handleResponse_proxyError() {
        let textElement = TextElementUITextField()
        let config = BasisTheoryConfig(publicKey: "key1", proxyKey: "key2")
        let logger = MockLogger()
        let basisTheoryWrapper = BasisTheoryWrapper(textElement: textElement, basisTheoryconfig: config, logger: logger)
        let response = HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: 500, httpVersion: nil, headerFields: nil)

        // THIS IS NOT THE CORRECT FORMAT. Swap all `rawValue` types for `elementValueReference`, an internal BT type that we can't replicate or access.
        // This mock is just for testing purposes
        let mockData = JSON.dictionaryValue([
            "proxy_error": JSON.dictionaryValue([
                "errors": JSON.dictionaryValue([
                    "error": JSON.arrayValue([
                        JSON.rawValue("")
                    ])
                ])
            ]),
            "title": JSON.rawValue(""),
            "status": JSON.rawValue(""),
            "detail": JSON.rawValue("")
        ])

        basisTheoryWrapper.handleResponse(response: response, data: mockData, error: nil, measurement: createMockVaultMonitor()) { (result: MockDecodableModel?, error: ForageError?) in
            XCTAssertNil(result)
            XCTAssertEqual(error, CommonErrors.UNKNOWN_SERVER_ERROR)
            XCTAssertEqual(logger.lastCriticalMessage, "Basis Theory proxy script failed")
        }
    }

    func testBasisTheoryWrapper_handleResponse_204Success() {
        let textElement = TextElementUITextField()
        let config = BasisTheoryConfig(publicKey: "key1", proxyKey: "key2")
        let logger = MockLogger()
        let basisTheoryWrapper = BasisTheoryWrapper(textElement: textElement, basisTheoryconfig: config, logger: logger)
        let response = HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: 204, httpVersion: nil, headerFields: nil)

        // BT returns an empty dict
        let mockData = JSON.dictionaryValue([:])

        basisTheoryWrapper.handleResponse(response: response, data: mockData, error: nil, measurement: createMockVaultMonitor()) { (result: MockDecodableModel?, error: ForageError?) in
            XCTAssertNil(result)
            XCTAssertNil(error)
        }
    }

    func testBasisTheoryWrapper_handleResponse_429Error() {
        let textElement = TextElementUITextField()
        let config = BasisTheoryConfig(publicKey: "key1", proxyKey: "key2")
        let logger = MockLogger()
        let basisTheoryWrapper = BasisTheoryWrapper(textElement: textElement, basisTheoryconfig: config, logger: logger)
        let response = HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: 429, httpVersion: nil, headerFields: nil)

        let mockData = JSON.dictionaryValue([
            "path": JSON.rawValue("test/path"),
            "errors": JSON.arrayValue([
                JSON.dictionaryValue([
                    "code": JSON.rawValue("too_many_requests"),
                    "message": JSON.rawValue("Request was throttled, please try again later.")
                ])
            ])
        ])

        basisTheoryWrapper.handleResponse(response: response, data: mockData, error: nil, measurement: createMockVaultMonitor()) { (result: MockDecodableModel?, error: ForageError?) in
            XCTAssertNil(result)
            XCTAssertEqual(error, THROTTLE_ERROR)
        }
    }

    func testBasisTheoryWrapper_handleResponse_invalidData() {
        let textElement = TextElementUITextField()
        let config = BasisTheoryConfig(publicKey: "key1", proxyKey: "key2")
        let logger = MockLogger()
        let basisTheoryWrapper = BasisTheoryWrapper(textElement: textElement, basisTheoryconfig: config, logger: logger)
        let response = HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: 429, httpVersion: nil, headerFields: nil)

        let mockData = JSON.dictionaryValue([
            "this": JSON.rawValue("Is an invalid structure!")
        ])

        basisTheoryWrapper.handleResponse(response: response, data: mockData, error: nil, measurement: createMockVaultMonitor()) { (result: MockDecodableModel?, error: ForageError?) in
            XCTAssertNil(result)
            XCTAssertEqual(error, CommonErrors.UNKNOWN_SERVER_ERROR)
            XCTAssertEqual(logger.lastCriticalMessage, "Received an unknown response structure from Basis Theory")
        }
    }

    func testBasisTheoryWrapper_handleResponse_validData() {
        let textElement = TextElementUITextField()
        let config = BasisTheoryConfig(publicKey: "key1", proxyKey: "key2")
        let logger = MockLogger()
        let basisTheoryWrapper = BasisTheoryWrapper(textElement: textElement, basisTheoryconfig: config, logger: logger)
        let response = HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: 429, httpVersion: nil, headerFields: nil)

        let mockData = JSON.dictionaryValue([
            "id": JSON.rawValue("12345")
        ])

        basisTheoryWrapper.handleResponse(response: response, data: mockData, error: nil, measurement: createMockVaultMonitor()) { (result: MockDecodableModel?, error: ForageError?) in
            XCTAssertNil(error)
            XCTAssertEqual(result, MockDecodableModel(id: "12345"))
        }
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
    
    func testRosettaSubmitter_GetVaultType() {
        let rosettaSubmitter = CollectorFactory.createRosettaPINSubmitter(environment: .sandbox, textElement: UITextField())
        let vaultType = rosettaSubmitter.getVaultType()
        XCTAssertEqual(vaultType, VaultType.forage)
    }
    
    func testRosettaSubmitter_SetCustomHeaders_HeaderKey() {
        let textElement = UITextField()
        let rosettaSubmitter = CollectorFactory.createRosettaPINSubmitter(environment: Environment.sandbox, textElement: textElement)

        let headers = ["HeaderKey": "HeaderValue"]
        let xKey = [String: String]()
        rosettaSubmitter.setCustomHeaders(headers: headers, xKey: xKey)

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
        XCTAssertFalse(request.allHTTPHeaderFields?.contains(where: { (key: String, value: String) in
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
        
        let expectation = self.expectation(description: "Completion handler called")
        
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
        
        let expectation = self.expectation(description: "Completion handler called")
        
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

        let expectation = self.expectation(description: "Completion handler called")
        
        rosettaSubmitter.sendData(path: "/test/path", vaultAction: .balanceCheck, extraData: ["card_number_token": "1,2,3"]) { (result: MockDecodableModel?, error: ForageError?) in
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
        XCTAssertFalse(session.lastRequest?.allHTTPHeaderFields?.contains(where: { (key: String, value: String) in
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

    // MARK: JSON.convertJsonToDictionary

    func testConvertJsonToDictionary_testEmptyDictionary() {
        let json: JSON = .dictionaryValue([:])
        let result = JSON.convertJsonToDictionary(json)
        XCTAssertTrue(result.isEmpty)
    }

    func testConvertJsonToDictionary_testRawValue() {
        let json: JSON = .dictionaryValue(["key": .rawValue("value")])
        let result = JSON.convertJsonToDictionary(json)
        XCTAssertEqual(result["key"] as? String, "value")
    }

    func testConvertJsonToDictionary_testArrayValue() {
        let json: JSON = .dictionaryValue(["array": .arrayValue([.rawValue("item1"), .rawValue("item2")])])
        let result = JSON.convertJsonToDictionary(json)
        let array = result["array"] as? [String]
        XCTAssertEqual(array, ["item1", "item2"])
    }

    func testConvertJsonToDictionary_testNestedDictionary() {
        let nestedJson: JSON = .dictionaryValue(["nestedKey": .rawValue("nestedValue")])
        let json: JSON = .dictionaryValue(["key": nestedJson])
        let result = JSON.convertJsonToDictionary(json)
        let nestedDict = result["key"] as? [String: Any]
        XCTAssertEqual(nestedDict?["nestedKey"] as? String, "nestedValue")
    }

    func testConvertJsonToDictionary_testNilJSON() {
        let result = JSON.convertJsonToDictionary(nil)
        XCTAssertTrue(result.isEmpty)
    }
}
