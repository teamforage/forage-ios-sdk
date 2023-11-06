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
    func testInit_shouldInitializeLogger() {
        ForageSDK.setup(ForageSDK.Config(
            merchantID: "merchantID123",
            sessionToken: "authToken123"
        ))

        XCTAssertNotNil(ForageSDK.shared.logger)
    }

    func testInit_shouldInitLiveForageService() {
        ForageSDK.setup(ForageSDK.Config(
            merchantID: "merchantID123",
            sessionToken: "authToken123"
        ))

        XCTAssertNotNil(ForageSDK.shared.service)
    }

    func testSetMerchantID_shouldUpdateSharedMerchantID() {
        ForageSDK.setup(ForageSDK.Config(
            merchantID: "merchantID123",
            sessionToken: "authToken123"
        ))

        ForageSDK.updateMerchantID("newID456")

        XCTAssertEqual(ForageSDK.shared.merchantID, "newID456")
    }

    func testSetSessionToken_shouldUpdateSharedSessionToken() {
        ForageSDK.setup(ForageSDK.Config(
            merchantID: "merchantID123",
            sessionToken: "authToken123"
        ))

        ForageSDK.updateSessionToken("newToken456")

        XCTAssertEqual(ForageSDK.shared.sessionToken, "newToken456")
    }
}
