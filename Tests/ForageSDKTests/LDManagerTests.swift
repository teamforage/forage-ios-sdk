//
//  LDManagerTests.swift
//  
//
//  Created by Danilo Joksimovic on 2023-09-01.
//

import XCTest

@testable import ForageSDK
@testable import LaunchDarkly

class MockLogger : NoopLogger {
    var lastInfoMsg: String = ""
    var lastErrorMsg: String = ""

    required init(_ config: ForageLoggerConfig? = nil) {
        super.init(config)
    }
    
    override func info(_ message: String, attributes: [String : Encodable]?) {
        lastInfoMsg = message
    }
    
    override func error(_ message: String, error: Error?, attributes: [String : Encodable]?) {
        lastErrorMsg = message
    }
}

class MockLDClient : LDClientProtocol {
    var vaultPercentage: Double
    
    init(vaultPercentage: Double) {
        self.vaultPercentage = vaultPercentage
    }
    
    init(vaultType: VaultType) {
        self.vaultPercentage = vaultType == VaultType.vgsVaultType ? 0 : 100
        print("Setting vault percentage to: \(self.vaultPercentage)")
    }
    
    func doubleVariationWrapper(forKey key: String, defaultValue: Double) -> Double {
        print("Evalutate fake vault percentage \(vaultPercentage)!")
        return vaultPercentage
    }
}

final class LDManagerTests: XCTestCase {
    // MARK: Test LDManager.getVaultType
    
    func testGetVaultType_WhenLDClientIsNil_ShouldReturnVGSVaultType() {
        let result = LDManager.shared.getVaultType(ldClient: nil, fromCache: false)
        XCTAssertEqual(result, VaultType.vgsVaultType)
    }
    
    func testGetVaultType_WhenVaultTypeIsAlreadySet_ShouldReturnCachedValue() {
        print("Testing \(self.name)...")
        let mockLDClient = MockLDClient(vaultType: VaultType.btVaultType)
        let firstVaultType = LDManager.shared.getVaultType(ldClient: mockLDClient, fromCache: false)
        
        let vgsMockLdClient = MockLDClient(vaultType: VaultType.vgsVaultType)
        let secondVaultType = LDManager.shared.getVaultType(
            ldClient: vgsMockLdClient,
            fromCache: true
        )
        
        XCTAssertEqual(firstVaultType, VaultType.btVaultType)
        // should still be Basis Theory
        XCTAssertEqual(secondVaultType, VaultType.btVaultType)
    }
    
    func testGetVaultType_VariationGreaterThanRandom_ShouldReturnBTVaultType() {
        print("Testing \(self.name)...")
        
        let mockLDClient = MockLDClient(vaultPercentage: 2)
        let mockRandomGenerator = { return 1.00 }
        
        print("Moss: \(mockRandomGenerator() < 2)")
        
        let result = LDManager.shared.getVaultType(
            ldClient: mockLDClient,
            genRandomDouble: mockRandomGenerator,
            fromCache: false
        )
        XCTAssertEqual(result, VaultType.btVaultType)
    }
    
    func testGetVaultType_VariationLessThanRandom_ShouldReturnVGSVaultType() {
        let mockLDClient = MockLDClient(vaultPercentage: 2)
        let mockRandomGenerator = { return 3.00 }
        
        let result = LDManager.shared.getVaultType(
            ldClient: mockLDClient,
            genRandomDouble: mockRandomGenerator,
            fromCache: false
        )
        XCTAssertEqual(result, VaultType.vgsVaultType)
    }
    
    // Test when ldClient.variation() returns a value equal to the random percent
    // Assuming you can mock or control the random number generation
    func testGetVaultType_VariationEqualToRandom_ShouldReturnVGSVaultType() {
        let mockLDClient = MockLDClient(vaultPercentage: 50)
        let mockRandomGenerator = { return 50.00 }
        
        let result = LDManager.shared.getVaultType(
            ldClient: mockLDClient,
            genRandomDouble: mockRandomGenerator,
            fromCache: false
        )
        XCTAssertEqual(result, VaultType.vgsVaultType)
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
