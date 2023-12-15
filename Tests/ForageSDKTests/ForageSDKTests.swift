//
//  ForageSDKTests.swift
//
//
//  Created by Danilo Joksimovic on 2023-09-06.
//

import Foundation

import XCTest

@testable import ForageSDK

final class ForageSDKTests: XCTestCase {
    var mockLogger: MockLogger!

    func setupMockSDK() {
        mockLogger = MockLogger()
        MockForageSDK.setup(ForageSDK.Config(
            merchantID: "merchantID123",
            sessionToken: "dev_authToken123"
        ))
        MockForageSDK.logger = mockLogger
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

        MockForageSDK.updateMerchantID("newID456")

        XCTAssertEqual(mockLogger.lastNoticeMsg, "Updated merchantID to newID456")
        XCTAssertEqual(ForageSDK.shared.merchantID, "newID456")
    }

    func testSetSessionToken_shouldUpdateSharedSessionToken() {
        setupMockSDK()

        MockForageSDK.updateSessionToken("staging_newToken456")

        XCTAssertEqual(MockForageSDK.shared.sessionToken, "staging_newToken456")
        XCTAssertEqual(mockLogger.lastNoticeMsg, "Called updateSessionToken")
        XCTAssertEqual(MockForageSDK.shared.environment, .staging)
    }
}
