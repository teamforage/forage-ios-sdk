//
//  ForageSDKTests.swift
//  
//
//  Created by Danilo Joksimovic on 2023-08-30.
//

import XCTest

@testable import ForageSDK

final class ForageSDKTests: XCTestCase {
    override func setUp() {
        // need to call
        ForageSDK.setup(ForageSDK.Config(merchantID: "merchant123", sessionToken: "sandbox_auth123"))
    }
    
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
    
    func testSetup_calledOnce_shouldSetConfig() {
        ForageSDK.setup(ForageSDK.Config(
            merchantID: "merchantID123",
            sessionToken: "staging_authToken123"
        ))
        
        XCTAssertEqual(ForageSDK.shared.environment.rawValue, "staging")
        XCTAssertEqual(ForageSDK.shared.merchantID, "merchantID123")
        XCTAssertEqual(ForageSDK.shared.sessionToken, "staging_authToken123")
    }
    
    func testSetup_calledTwice_shouldUpdateConfig() {
        ForageSDK.setup(ForageSDK.Config(
            merchantID: "merchantID123",
            sessionToken: "staging_authToken123"
        ))
        
        XCTAssertEqual(ForageSDK.shared.environment.rawValue, "staging")
        XCTAssertEqual(ForageSDK.shared.merchantID, "merchantID123")
        XCTAssertEqual(ForageSDK.shared.sessionToken, "staging_authToken123")
        
        ForageSDK.setup(ForageSDK.Config(
            merchantID: "newMerchantID456",
            sessionToken: "sandbox_newToken123"
        ))
        
        XCTAssertEqual(ForageSDK.shared.environment.rawValue, "sandbox")
        XCTAssertEqual(ForageSDK.shared.merchantID, "newMerchantID456")
        XCTAssertEqual(ForageSDK.shared.sessionToken, "sandbox_newToken123")
    }
}
