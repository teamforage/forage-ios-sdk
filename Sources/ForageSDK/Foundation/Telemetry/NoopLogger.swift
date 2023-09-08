//
//  NoopLogger.swift
//  
//
//  Created by Danilo Joksimovic on 2023-09-01.
//

import Foundation

/// Silent logger that doesn't do anything!
internal class NoopLogger: ForageLogger {
    func getTraceID() -> String {
        return ""
    }
    
    required init(_ config: ForageLoggerConfig? = ForageLoggerConfig(environment: .sandbox)) {
        // noop
    }
    
    func addContext(_ newContext: ForageLogContext) -> ForageLogger {
        return self
    }
    
    func setLogKind(_ logKind: ForageLogKind) -> ForageLogger {
        return self
    }
    
    func setPrefix(_ prefix: String) -> ForageLogger {
        return self
    }
    
    func notice(_ message: String, attributes: [String : Encodable]?) {
        // noop
    }
    
    func info(_ message: String, attributes: [String : Encodable]?) {
        // noop
    }
    
    func warn(_ message: String, error: Error?, attributes: [String : Encodable]?) {
        // noop
    }
    
    func error(_ message: String, error: Error?, attributes: [String : Encodable]?) {
        // noop
    }
    
    func critical(_ message: String, error: Error?, attributes: [String : Encodable]?) {
        // noop
    }
}
