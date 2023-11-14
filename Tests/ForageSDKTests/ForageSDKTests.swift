//
//  ForageSDKTests.swift
//
//
//  Created by Danilo Joksimovic on 2023-09-06.
//

import Foundation

import XCTest

@testable import ForageSDK

class MockForageSDK : ForageSDK {
    static var initializedLogger: Bool = false
    static var initializedLaunchDarkly: Bool = false

    override static func initializeLogger(_ environment: Environment) {
        MockForageSDK.initializedLogger = true
    }
    
    override static func initializeLaunchDarkly(_ environment: Environment) {
        MockForageSDK.initializedLaunchDarkly = true
    }
}

final class ForageSDKTests: XCTestCase {
    private func createMockForageConfig() -> ForageSDK.Config {
        return ForageSDK.Config(
            merchantID: "merchantID123",
            sessionToken: "dev_authToken123"
        )
    }
    
    func testInit_shouldInitMerchantId() {
        MockForageSDK.setup(createMockForageConfig())

        XCTAssertEqual(MockForageSDK.shared.merchantID, "merchantID123")
    }
    
    func testInit_shouldInitSessionToken() {
        MockForageSDK.setup(createMockForageConfig())

        XCTAssertEqual(MockForageSDK.shared.sessionToken, "dev_authToken123")
    }
    
    func testInit_shouldInitEnvironment() {
        MockForageSDK.setup(createMockForageConfig())

        XCTAssertEqual(MockForageSDK.shared.environment, Environment.dev)
    }
    
    func testInit_shouldInitializeLogger() {
        MockForageSDK.setup(createMockForageConfig())

        XCTAssertTrue(MockForageSDK.initializedLogger)
    }
    
    func testInit_shouldInitializeLaunchDarkly() {
        MockForageSDK.setup(createMockForageConfig())

        XCTAssertTrue(MockForageSDK.initializedLaunchDarkly)
    }

    func testInit_shouldInitForageService() {
        MockForageSDK.setup(createMockForageConfig())

        XCTAssertNotNil(ForageSDK.shared.service)
    }

    func testSetMerchantID_shouldUpdateSharedMerchantID() {
        MockForageSDK.setup(createMockForageConfig())

        ForageSDK.updateMerchantID("dev_newID456")

        XCTAssertEqual(ForageSDK.shared.merchantID, "dev_newID456")
    }

    func testSetSessionToken_shouldUpdateSharedSessionToken() {
        MockForageSDK.setup(createMockForageConfig())

        ForageSDK.updateSessionToken("newToken456")

        XCTAssertEqual(ForageSDK.shared.sessionToken, "newToken456")
    }
}
