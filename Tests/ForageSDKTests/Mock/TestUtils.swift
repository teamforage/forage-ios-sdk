//
//  TestUtils.swift
//
//
//  Created by Danilo Joksimovic on 2023-11-11.
//

@testable import ForageSDK
import Foundation

// ⚠️ Utils should be used judiciously

/// Need to call setUpForageSDK before running most tests
/// Since initializing the SDK is a pre-condition for most SDK interactions
///
/// Because ForageSDK is a singleton,  the sessionToken
/// environment and merchantID should ideally be the same across tests
func setUpForageSDK() {
    ForageSDK.setup(ForageSDK.Config(
        merchantID: "merchantID123",
        sessionToken: "dev_authToken123"
    ))
}
