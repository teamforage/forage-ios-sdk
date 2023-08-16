//
//  EnvironmentTests.swift
//  
//
//  Created by Danilo Joksimovic on 2023-08-16.
//

import XCTest
@testable import ForageSDK

final class EnvironmentTests: XCTestCase {
    // MARK: - Environment.hostname mapping tests
    
    func testHostname_givenDevToken_shouldReturnDevHostname() {
        let actual = sessionTokenToEnv("dev_abcd123")
        XCTAssertEqual(actual.hostname, "api.dev.joinforage.app")
    }
    
    func testHostname_givenStagingToken_shouldReturnStagingHostname() {
        let actual = sessionTokenToEnv("staging_abcd123")
        XCTAssertEqual(actual.hostname, "api.staging.joinforage.app")
    }
    
    func testHostname_givenStagingToken_shouldReturnSandboxHostname() {
        let actual = sessionTokenToEnv("sandbox_abcd123")
        XCTAssertEqual(actual.hostname, "api.sandbox.joinforage.app")
    }
    
    func testHostname_givenProdToken_shouldReturnProdHostname() {
        let actual = sessionTokenToEnv("prod_abcd123")
        XCTAssertEqual(actual.hostname, "api.joinforage.app")
    }
    
    // MARK: - sessionTokenToEnv tests
    
    func testSessionTokenToEnv_givenDevToken_shouldReturnDev() {
        let actual = sessionTokenToEnv("dev_abcd123")
        XCTAssertEqual(actual.rawValue, "dev")
    }
    
    func testSessionTokenToEnv_givenStagingToken_shouldReturnStaging() {
        let actual = sessionTokenToEnv("staging_abcd123")
        XCTAssertEqual(actual.rawValue, "staging")
    }
    
    func testSessionTokenToEnv_givenSandboxToken_shouldReturnSandbox() {
        let actual = sessionTokenToEnv("sandbox_abcd123")
        XCTAssertEqual(actual.rawValue, "sandbox")
    }
    
    func testSessionTokenToEnv_givenProdToken_shouldReturnProd() {
        let actual = sessionTokenToEnv("prod_abcd123")
        XCTAssertEqual(actual.rawValue, "prod")
    }
    
    // MARK: - sessionTokenToEnv invalid token tests
    
    func testSessionTokenToEnv_givenNil_shouldReturnSandbox() {
        let actual = sessionTokenToEnv(nil)
        XCTAssertEqual(actual.rawValue, "sandbox")
    }
    
    func testSessionTokenToEnv_givenEmpty_shouldReturnSandbox() {
        let actual = sessionTokenToEnv("")
        XCTAssertEqual(actual.rawValue, "sandbox")
    }
    
    func testSessionTokenToEnv_givenInvalidEnv_shouldReturnSandbox() {
        let actual = sessionTokenToEnv("invalid_abdcefg")
        XCTAssertEqual(actual.rawValue, "sandbox")
    }
    
    func testSessionTokenToEnv_givenInvalidToken_shouldReturnSandbox() {
        let actual = sessionTokenToEnv("invalid")
        XCTAssertEqual(actual.rawValue, "sandbox")
    }
}
