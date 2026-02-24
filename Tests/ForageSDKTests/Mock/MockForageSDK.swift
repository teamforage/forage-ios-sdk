//
//  MockForageSDK.swift
//
//
//  Created by Danilo Joksimovic on 2023-12-14.
//

@testable import ForageSDK

class MockForageSDK: ForageSDK {
    static var initializedLogger: Bool = false

    override static func initializeLogger(_ environment: Environment) {
        MockForageSDK.initializedLogger = true
    }
}
