//
//  Environment.swift
//  
//
//  Created by Danilo Joksimovic on 2023-08-23.
//

import Foundation


internal func isUnitTesting() -> Bool {
    return ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
}
