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
func setUpForageSDK() {
    ForageSDK.setup(ForageSDK.Config(
        merchantID: "merchantID123",
        sessionToken: "authToken123"
    ))
}
