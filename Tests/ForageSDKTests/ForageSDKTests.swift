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

    func testSetup_shouldUpdateMerchantIDAndSessionToken() {
        ForageSDK.setup(
            ForageSDK.Config(merchantID: "mid/first", sessionToken: "dev_first_token")
        )

        /// NOTE: We access ForageSDK.shared. to make sure that config updates still work after ``ForageSDK.init`` is invoked
        XCTAssertEqual(ForageSDK.shared.environment, .dev)
        XCTAssertEqual(ForageSDK.shared.merchantID, "mid/first")

        ForageSDK.setup(
            ForageSDK.Config(merchantID: "mid/second", sessionToken: "staging_second_token")
        )

        XCTAssertEqual(ForageSDK.shared.environment, .staging)
        XCTAssertEqual(ForageSDK.shared.merchantID, "mid/second")

        // one more time!
        ForageSDK.setup(
            ForageSDK.Config(merchantID: "mid/third", sessionToken: "sandbox_second_token")
        )

        XCTAssertEqual(ForageSDK.shared.environment, .sandbox)
        XCTAssertEqual(ForageSDK.shared.merchantID, "mid/third")
    }
}
