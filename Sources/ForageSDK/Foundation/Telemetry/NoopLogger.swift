//
//  NoopLogger.swift
//
//
//  Created by Danilo Joksimovic on 2023-09-01.
//  Copyright © 2023-Present Forage Technology Corporation. All rights reserved.
//

import Foundation

/// Silent logger that doesn't do anything!
class NoopLogger: ForageLogger {
    func getTraceID() -> String {
        ""
    }

    required init(_ config: ForageLoggerConfig? = ForageLoggerConfig(environment: .sandbox)) {
        // noop
    }

    func addContext(_ newContext: ForageLogContext) -> ForageLogger {
        self
    }

    func setLogKind(_ logKind: ForageLogKind) -> ForageLogger {
        self
    }

    func setPrefix(_ prefix: String) -> ForageLogger {
        self
    }

    func notice(_ message: String, attributes: [String: Encodable]?) {
        // noop
    }

    func info(_ message: String, attributes: [String: Encodable]?) {
        // noop
    }

    func warn(_ message: String, error: Error?, attributes: [String: Encodable]?) {
        // noop
    }

    func error(_ message: String, error: Error?, attributes: [String: Encodable]?) {
        // noop
    }

    func critical(_ message: String, error: Error?, attributes: [String: Encodable]?) {
        // noop
    }
}
