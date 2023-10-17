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
    var pollingIntervals: LDValue?
    var vaultPercentage: Double
    
    init(vaultPercentage: Double = 0.0, pollingIntervals: LDValue? = nil) {
        self.vaultPercentage = vaultPercentage
        self.pollingIntervals = pollingIntervals
    }

    init(vaultType: VaultType) {
        self.vaultPercentage = vaultType == VaultType.vgsVaultType ? 0 : 100
    }
    
    func doubleVariationWrapper(forKey key: String, defaultValue: Double) -> Double {
        return vaultPercentage
    }
    
    func jsonVariationWrapper(forKey key: String, defaultValue: LDValue) -> LDValue {
        return pollingIntervals ?? defaultValue
    }
}

final class LDManagerTests: XCTestCase {
    // MARK: Test LDManager.getVaultType
    
    func testGetVaultType_WhenLDClientIsNil_ShouldReturnVGSVaultType() {
        let result = LDManager.shared.getVaultType(ldClient: nil, fromCache: false)
        XCTAssertEqual(result, VaultType.vgsVaultType)
    }
    
    func testGetVaultType_WhenVaultTypeIsAlreadySet_ShouldReturnCachedValue() {
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
        let mockLDClient = MockLDClient(vaultPercentage: 2)
        let mockRandomGenerator = { return 1.00 }
                
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
    
    func testGetPollingIntervals_ReturnsDefaultVal() {
        let mockLDClient = MockLDClient()
        
        let result = LDManager.shared.getPollingIntervals(
            ldClient: mockLDClient
        )
        let defatulVal: [Int] = []
        XCTAssertEqual(result, defatulVal)
    }
    
    func testGetPollingIntervals_InvalidFlagValueReturnsDefault() {
        // Structure of the flag value is incorrect! The object should be:
        // { "intervals": [1000] }
        // Instead it is:
        // { "intervals": 1000 }
        let mockLDClient = MockLDClient(pollingIntervals: LDValue(dictionaryLiteral: ("intervals", 1000)))
        
        let result = LDManager.shared.getPollingIntervals(
            ldClient: mockLDClient
        )
        let defatulVal: [Int] = []
        XCTAssertEqual(result, defatulVal)
    }
    
    func testGetPollingIntervals_ValidFlagValueIsReturned() {
        let defVal = LDValue(dictionaryLiteral: ("intervals", [250, 250, 500, 500, 1000]))
        let mockLDClient = MockLDClient(pollingIntervals: defVal)
        
        let result = LDManager.shared.getPollingIntervals(
            ldClient: mockLDClient
        )
        let expectedValue: [Int] = [250, 250, 500, 500, 1000]
        XCTAssertEqual(result, expectedValue)
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
