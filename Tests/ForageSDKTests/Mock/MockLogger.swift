//
//  MockLogger.swift
//
//
//  Created by Danilo Joksimovic on 2023-11-11.
//
@testable import ForageSDK
import Foundation

class MockLogger: NoopLogger {
    var lastInfoMsg: String = ""
    var lastErrorMsg: String = ""
    var lastCriticalMessage: String = ""
    var lastNoticeMsg: String = ""
    var lastAttributes: [String: Encodable]? = nil

    required init(_ config: ForageLoggerConfig? = nil) {
        super.init(config)
    }

    override func info(_ message: String, attributes: [String: Encodable]?) {
        lastInfoMsg = message
        lastAttributes = attributes
    }

    override func error(_ message: String, error: Error?, attributes: [String: Encodable]?) {
        lastErrorMsg = message
        lastAttributes = attributes
    }

    override func critical(_ message: String, error: Error?, attributes: [String: Encodable]?) {
        lastCriticalMessage = message
        lastAttributes = attributes
    }

    override func notice(_ message: String, attributes: [String: Encodable]?) {
        lastNoticeMsg = message
        lastAttributes = attributes
    }
}
