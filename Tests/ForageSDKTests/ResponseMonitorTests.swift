//
//  ResponseMonitorTests.swift
//  
//
//  Created by Danilo Joksimovic on 2023-08-29.
//

import XCTest

@testable import ForageSDK

class MockMetricsLogger: DatadogLogger {
    struct LogEntry {
        let message: String
        let attributes: [String: Encodable]?
    }
    
    var loggedErrors: [LogEntry] = []
    var loggedInfos: [LogEntry] = []
    
    override internal func error(_ message: String, error: Error?, attributes: [String: Encodable]? = nil) {
        loggedErrors.append(LogEntry(message: message, attributes: attributes))
    }
    
    override internal func info(_ message: String, attributes: [String: Encodable]? = nil) {
        loggedInfos.append(LogEntry(message: message, attributes: attributes))
    }
}

class TestableResponseMonitor: ResponseMonitor {
    var lastLoggedAttributes: ResponseAttributes?
    
    override internal func logWithResponseAttributes(metricsLogger: ForageLogger?, responseAttributes: ResponseAttributes) {
        lastLoggedAttributes = responseAttributes
    }
}

final class ResponseMonitorTests: XCTestCase {
    override func setUp() {
        ForageSDK.setup(ForageSDK.Config(environment: .sandbox))
        ForageSDK.shared.service = nil
    }
    
    func testLogResult_shouldCalculateDuration() {
        let mockMetricsLogger = MockMetricsLogger()
        let testableMonitor = TestableResponseMonitor(metricsLogger: mockMetricsLogger)
        
        testableMonitor.setPath("/test/path")
            .setMethod(.get)
            .setHttpStatusCode(200)
            .start()
        // Simulate some network delay
        Thread.sleep(forTimeInterval: 0.1)
        testableMonitor.end()
        
        testableMonitor.logResult()
        
        XCTAssertEqual(mockMetricsLogger.loggedErrors.count, 0, "There should be no logged errors")
        
        // Verify through exposed testable attributes
        let loggedAttributes = testableMonitor.lastLoggedAttributes!
        XCTAssertEqual(loggedAttributes.path, "/test/path", "The path should be set")
        XCTAssertEqual(loggedAttributes.method, .get, "The HTTP method should be set")
        XCTAssertEqual(loggedAttributes.code, 200, "The HTTP status code should be set")
        XCTAssertNotNil(loggedAttributes.responseTimeMs, "The response time should be calculated")
        XCTAssertGreaterThanOrEqual(loggedAttributes.responseTimeMs!, 100.0, "The response time should be at least 100 ms due to the simulated delay")
    }
    
    func testLogWithResponseAttributes_shouldLogWithAttributes() {
        let mockMetricsLogger = MockMetricsLogger()
        let monitor = VaultProxyResponseMonitor.newMeasurement(vault: .btVaultType, action: .balanceCheck)
        
        let attributes = ResponseAttributes(
            responseTimeMs: 123.45,
            path: "/vault/test",
            method: .post,
            code: 201
        )
        
        monitor.logWithResponseAttributes(metricsLogger: mockMetricsLogger, responseAttributes: attributes)
        
        // Add assertions
        XCTAssertEqual(mockMetricsLogger.loggedErrors.count, 0, "There should be no logged errors")
        XCTAssertEqual(mockMetricsLogger.loggedInfos.count, 1, "There should be one logged info")
        
        let loggedInfo = mockMetricsLogger.loggedInfos.first!
        let loggedAttributes = loggedInfo.attributes!
        XCTAssertEqual(loggedInfo.message, "Received response from basis_theory proxy")
        XCTAssertEqual(loggedAttributes["vault_type"] as? String, "basis_theory")
        XCTAssertEqual(loggedAttributes["action"] as? String, "balance")
        XCTAssertEqual(loggedAttributes["path"] as? String, "/vault/test")
        XCTAssertEqual(loggedAttributes["method"] as? String, "POST")
        XCTAssertEqual(loggedAttributes["http_status"] as? Int, 201)
        XCTAssertEqual(loggedAttributes["response_time_ms"] as? Double, 123.45)
    }
}
