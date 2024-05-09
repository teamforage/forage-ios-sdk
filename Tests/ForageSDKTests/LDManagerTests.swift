//
//  LDManagerTests.swift
//
//
//  Created by Danilo Joksimovic on 2023-09-01.
//

import XCTest

@testable import ForageSDK
@testable import LaunchDarkly

class MockLDClient: LDClientProtocol {
    var vaultPercentage: Double

    init(vaultPercentage: Double = 0.0) {
        self.vaultPercentage = vaultPercentage
    }

    init(vaultType: VaultType) {
        vaultPercentage = vaultType == VaultType.vgs ? 0 : 100
    }

    func doubleVariationWrapper(forKey key: String, defaultValue: Double) -> Double {
        vaultPercentage
    }
}

final class LDManagerTests: XCTestCase {
    // MARK: Test LDManager.getVaultType

    func testGetVaultType_WhenLDClientIsNil_ShouldReturnVGSVaultType() {
        let result = LDManager.shared.getVaultType(
            ldClient: nil,
            genRandomDouble: LDManager.generateRandomDouble
        )
        XCTAssertEqual(result, VaultType.vgs)
    }

    func testGetVaultType_VariationGreaterThanRandom_ShouldReturnBTVaultType() {
        let mockLDClient = MockLDClient(vaultPercentage: 2)
        let mockRandomGenerator = { 1.00 }

        let result = LDManager.shared.getVaultType(
            ldClient: mockLDClient,
            genRandomDouble: mockRandomGenerator
        )
        XCTAssertEqual(result, VaultType.basisTheory)
    }

    func testGetVaultType_VariationLessThanRandom_ShouldReturnVGSVaultType() {
        let mockLDClient = MockLDClient(vaultPercentage: 2)
        let mockRandomGenerator = { 3.00 }

        let result = LDManager.shared.getVaultType(
            ldClient: mockLDClient,
            genRandomDouble: mockRandomGenerator
        )
        XCTAssertEqual(result, VaultType.vgs)
    }

    // Test when ldClient.variation() returns a value equal to the random percent
    // Assuming you can mock or control the random number generation
    func testGetVaultType_VariationEqualToRandom_ShouldReturnVGSVaultType() {
        let mockLDClient = MockLDClient(vaultPercentage: 50)
        let mockRandomGenerator = { 50.00 }

        let result = LDManager.shared.getVaultType(
            ldClient: mockLDClient,
            genRandomDouble: mockRandomGenerator
        )
        XCTAssertEqual(result, VaultType.vgs)
    }

    // MARK: Test LDManager.Initialize

    func testInitialize_StartsLDClient() {
        let expectation = XCTestExpectation(description: "Completion should be called")
        let mockLogger = MockLogger()

        let mockStartLdClient = { (config: LDConfig, context: LDContext?, completion: (() -> Void)?) in
            // sandbox key:
            XCTAssertEqual(config.mobileKey, "mob-22024b85-05b7-4e24-b290-a071310dfc3d")
            XCTAssertNotNil(context)
            completion?()

            XCTAssertEqual(mockLogger.lastInfoMsg, "Initialized LaunchDarkly client")

            expectation.fulfill()
        }

        let manager = LDManager.shared
        manager.initialize(.sandbox, logger: mockLogger, startLdClient: mockStartLdClient)

        wait(for: [expectation], timeout: 1.0)
    }
}
