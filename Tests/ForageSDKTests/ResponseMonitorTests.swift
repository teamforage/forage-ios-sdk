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
    var logKind: ForageLogKind?
    
    override internal func error(_ message: String, error: Error?, attributes: [String: Encodable]? = nil) {
        loggedErrors.append(LogEntry(message: message, attributes: attributes))
    }
    
    override internal func info(_ message: String, attributes: [String: Encodable]? = nil) {
        loggedInfos.append(LogEntry(message: message, attributes: attributes))
    }
    
    override func setLogKind(_ logKind: ForageLogKind) -> ForageLogger {
        self.logKind = logKind
        return self
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
    
    func testInit_shouldSetLogKind() {
        let mockMetricsLogger = MockMetricsLogger()
        _ = TestableResponseMonitor(metricsLogger: mockMetricsLogger)

        XCTAssertEqual(mockMetricsLogger.logKind!.rawValue, "metric")
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
        XCTAssertEqual(loggedAttributes.path, "/test/path")
        XCTAssertEqual(loggedAttributes.method, .get)
        XCTAssertEqual(loggedAttributes.code, 200)
        XCTAssertNotNil(loggedAttributes.responseTimeMs, "The response time should be calculated")
        XCTAssertGreaterThanOrEqual(loggedAttributes.responseTimeMs!, 100.0, "The response time should be at least 100 ms due to the simulated delay")
    }
    
    func testLogWithResponseAttributes_whenMissingAttributes_shouldLogError() {
        let mockMetricsLogger = MockMetricsLogger()
        let monitor = VaultProxyResponseMonitor.newMeasurement(vault: .btVaultType, action: .balanceCheck)
        
        let attributes = ResponseAttributes(
            responseTimeMs: nil,
            path: "/vault/test",
            method: .post,
            code: 201
        )
        
        monitor.logWithResponseAttributes(metricsLogger: mockMetricsLogger, responseAttributes: attributes)
        
        XCTAssertEqual(mockMetricsLogger.loggedErrors.count, 1, "There should be one logged error")
        XCTAssertEqual(mockMetricsLogger.loggedInfos.count, 0, "There should be no logged infos")

        let loggedError = mockMetricsLogger.loggedErrors.first!
        XCTAssertEqual(loggedError.message, "Incomplete or missing response attributes. Could not log metric.")
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
