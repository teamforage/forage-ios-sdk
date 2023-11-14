//
//  ForageSDKTests.swift
//
//
//  Created by Danilo Joksimovic on 2023-09-06.
//

import Foundation

import XCTest

@testable import ForageSDK

class MockForageSDK: ForageSDK {
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
    func setupMockSDK() {
        MockForageSDK.setup(ForageSDK.Config(
            merchantID: "merchantID123",
            sessionToken: "dev_authToken123"
        ))
    }

    func testInit_shouldInitMerchantId() {
        setupMockSDK()

        XCTAssertEqual(MockForageSDK.shared.merchantID, "merchantID123")
    }

    func testInit_shouldInitSessionToken() {
        setupMockSDK()

        XCTAssertEqual(MockForageSDK.shared.sessionToken, "dev_authToken123")
    }

    func testInit_shouldInitializeLogger() {
        setupMockSDK()

        XCTAssertTrue(MockForageSDK.initializedLogger)
    }

    func testInit_shouldInitializeLaunchDarkly() {
        setupMockSDK()

        XCTAssertTrue(MockForageSDK.initializedLaunchDarkly)
    }

    func testInit_shouldInitForageService() {
        setupMockSDK()

        XCTAssertNotNil(ForageSDK.shared.service)
    }

    func testSetMerchantID_shouldUpdateSharedMerchantID() {
        setupMockSDK()

        ForageSDK.updateMerchantID("dev_newID456")

        XCTAssertEqual(ForageSDK.shared.merchantID, "dev_newID456")
    }

    func testSetSessionToken_shouldUpdateSharedSessionToken() {
        setupMockSDK()

        ForageSDK.updateSessionToken("staging_newToken456")

        XCTAssertEqual(ForageSDK.shared.sessionToken, "staging_newToken456")
    }
}
