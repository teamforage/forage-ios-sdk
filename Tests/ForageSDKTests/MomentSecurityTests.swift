//
//  MomentSecurityTests.swift
//  ForageSDKTests
//
//  © 2025 Forage Technology Corporation. All rights reserved.
//

@testable import ForageSDK
import XCTest

final class MomentSecurityTests: XCTestCase {
    private let momentURL = URL(string: "https://custom-checkout.dev.joinforage.app/payment/collect-pin?paymentRef=abc")!
    private let localMomentURL = URL(string: "http://localhost:3000/payment/collect-pin?paymentRef=abc")!

    // MARK: Messages from the page

    func testShouldAcceptMessage_givenTheMomentsMainFrame_shouldAccept() {
        XCTAssertTrue(MomentSecurity.shouldAcceptMessage(
            isMainFrame: true, scheme: "https", host: "custom-checkout.dev.joinforage.app", port: 0, momentURL: momentURL
        ))
        XCTAssertTrue(MomentSecurity.shouldAcceptMessage(
            isMainFrame: true, scheme: "http", host: "localhost", port: 3000, momentURL: localMomentURL
        ))
    }

    func testShouldAcceptMessage_givenAnIframe_shouldIgnoreIt() {
        // e.g. the PIN field's vault iframe, which can post to the handler on iOS 13
        XCTAssertFalse(MomentSecurity.shouldAcceptMessage(
            isMainFrame: false, scheme: "https", host: "vault.example.com", port: 0, momentURL: momentURL
        ))
        // even an iframe on the moment's own origin
        XCTAssertFalse(MomentSecurity.shouldAcceptMessage(
            isMainFrame: false, scheme: "https", host: "custom-checkout.dev.joinforage.app", port: 0, momentURL: momentURL
        ))
    }

    func testShouldAcceptMessage_givenAnotherOrigin_shouldIgnoreIt() {
        let otherOrigins: [(scheme: String, host: String, port: Int)] = [
            ("https", "evil.example.com", 0),
            ("http", "custom-checkout.dev.joinforage.app", 0),
            ("https", "custom-checkout.dev.joinforage.app", 8443),
            ("https", "custom-checkout.dev.joinforage.app.evil.example.com", 0),
        ]
        for origin in otherOrigins {
            XCTAssertFalse(
                MomentSecurity.shouldAcceptMessage(
                    isMainFrame: true, scheme: origin.scheme, host: origin.host, port: origin.port, momentURL: momentURL
                ),
                "\(origin)"
            )
        }
    }

    // MARK: Navigation

    func testShouldAllowNavigation_givenTheMainFrameOnTheMomentsOrigin_shouldAllow() {
        XCTAssertTrue(MomentSecurity.shouldAllowNavigation(
            targetsMainFrame: true,
            to: URL(string: "https://custom-checkout.dev.joinforage.app/payment/collect-pin?paymentRef=other"),
            momentURL: momentURL
        ))
    }

    func testShouldAllowNavigation_givenTheMainFrameLeavingTheMomentsOrigin_shouldBlock() {
        XCTAssertFalse(MomentSecurity.shouldAllowNavigation(
            targetsMainFrame: true, to: URL(string: "https://evil.example.com/"), momentURL: momentURL
        ))
        XCTAssertFalse(MomentSecurity.shouldAllowNavigation(
            targetsMainFrame: true, to: nil, momentURL: momentURL
        ))
    }

    func testShouldAllowNavigation_givenANewWindow_shouldBlock() {
        XCTAssertFalse(MomentSecurity.shouldAllowNavigation(
            targetsMainFrame: nil, to: momentURL, momentURL: momentURL
        ))
    }

    func testShouldAllowNavigation_givenAnIframe_shouldAllow() {
        XCTAssertTrue(MomentSecurity.shouldAllowNavigation(
            targetsMainFrame: false, to: URL(string: "https://vault.example.com/pin"), momentURL: momentURL
        ))
    }

    // MARK: Sending the session token

    func testCanSendInitialize_givenThePageIsOnTheMomentsOrigin_shouldAllow() {
        XCTAssertTrue(MomentSecurity.canSendInitialize(currentURL: momentURL, momentURL: momentURL))
    }

    func testCanSendInitialize_givenThePageIsSomewhereElse_shouldNotSendTheToken() {
        XCTAssertFalse(MomentSecurity.canSendInitialize(
            currentURL: URL(string: "https://evil.example.com/"), momentURL: momentURL
        ))
        XCTAssertFalse(MomentSecurity.canSendInitialize(currentURL: nil, momentURL: momentURL))
    }
}
