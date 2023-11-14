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
    func testInit_shouldInitializeLogger() {
        MockForageSDK.setup(ForageSDK.Config(
            merchantID: "merchantID123",
            sessionToken: "authToken123"
        ))

        XCTAssertTrue(MockForageSDK.initializedLogger)
    }
    
    func testInit_shouldInitializeLaunchDarkly() {
        MockForageSDK.setup(ForageSDK.Config(
            merchantID: "merchantID123",
            sessionToken: "authToken123"
        ))

        XCTAssertTrue(MockForageSDK.initializedLaunchDarkly)
    }

    func testInit_shouldInitForageService() {
        MockForageSDK.setup(ForageSDK.Config(
            merchantID: "merchantID123",
            sessionToken: "authToken123"
        ))

        XCTAssertNotNil(ForageSDK.shared.service)
    }

    func testSetMerchantID_shouldUpdateSharedMerchantID() {
        MockForageSDK.setup(ForageSDK.Config(
            merchantID: "merchantID123",
            sessionToken: "authToken123"
        ))

        ForageSDK.updateMerchantID("newID456")

        XCTAssertEqual(ForageSDK.shared.merchantID, "newID456")
    }

    func testSetSessionToken_shouldUpdateSharedSessionToken() {
        MockForageSDK.setup(ForageSDK.Config(
            merchantID: "merchantID123",
            sessionToken: "authToken123"
        ))

        ForageSDK.updateSessionToken("newToken456")

        XCTAssertEqual(ForageSDK.shared.sessionToken, "newToken456")
    }
}
