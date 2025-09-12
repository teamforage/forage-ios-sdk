//
//  EnvironmentTests.swift
//
//
//  Created by Danilo Joksimovic on 2023-08-16.
//

@testable import ForageSDK
import XCTest

final class EnvironmentTests: XCTestCase {
    // MARK: - Environment.hostname mapping tests

    func testHostname_givenDevToken_shouldReturnDevHostname() {
        let actual = Environment(sessionToken: "dev_abcd123")
        XCTAssertEqual(actual.hostname, "api.dev.joinforage.app")
    }

    func testHostname_givenStagingToken_shouldReturnStagingHostname() {
        let actual = Environment(sessionToken: "staging_abcd123")
        XCTAssertEqual(actual.hostname, "api.staging.joinforage.app")
    }

    func testHostname_givenStagingToken_shouldReturnSandboxHostname() {
        let actual = Environment(sessionToken: "sandbox_abcd123")
        XCTAssertEqual(actual.hostname, "api.sandbox.joinforage.app")
    }

    func testHostname_givenProdToken_shouldReturnProdHostname() {
        let actual = Environment(sessionToken: "prod_abcd123")
        XCTAssertEqual(actual.hostname, "api.joinforage.app")
    }

    // MARK: - sessionTokenToEnv tests

    func testSessionTokenToEnv_givenDevToken_shouldReturnDev() {
        let actual = Environment(sessionToken: "dev_abcd123")
        XCTAssertEqual(actual.rawValue, "dev")
    }

    func testSessionTokenToEnv_givenStagingToken_shouldReturnStaging() {
        let actual = Environment(sessionToken: "staging_abcd123")
        XCTAssertEqual(actual.rawValue, "staging")
    }

    func testSessionTokenToEnv_givenSandboxToken_shouldReturnSandbox() {
        let actual = Environment(sessionToken: "sandbox_abcd123")
        XCTAssertEqual(actual.rawValue, "sandbox")
    }

    func testSessionTokenToEnv_givenProdToken_shouldReturnProd() {
        let actual = Environment(sessionToken: "prod_abcd123")
        XCTAssertEqual(actual.rawValue, "prod")
    }

    // MARK: - sessionTokenToEnv invalid token tests

    func testSessionTokenToEnv_givenNil_shouldReturnSandbox() {
        let actual = Environment()
        XCTAssertEqual(actual.rawValue, "sandbox")
    }

    func testSessionTokenToEnv_givenEmpty_shouldReturnSandbox() {
        let actual = Environment(sessionToken: "")
        XCTAssertEqual(actual.rawValue, "sandbox")
    }

    func testSessionTokenToEnv_givenInvalidEnv_shouldReturnSandbox() {
        let actual = Environment(sessionToken: "invalid_abdcefg")
        XCTAssertEqual(actual.rawValue, "sandbox")
    }

    func testSessionTokenToEnv_givenInvalidToken_shouldReturnSandbox() {
        let actual = Environment(sessionToken: "invalid")
        XCTAssertEqual(actual.rawValue, "sandbox")
    }
    
    func testSessionTokenToEnv_givenLocalPrefix_shouldReturnLocal() {
        let actual = Environment(sessionToken: "local_superLocalDude")
        XCTAssertEqual(actual.rawValue, "local")
    }
}
