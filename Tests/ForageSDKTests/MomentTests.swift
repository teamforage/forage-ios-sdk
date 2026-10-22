//
//  MomentTests.swift
//  ForageSDKTests
//
//  © 2025 Forage Technology Corporation. All rights reserved.
//

@testable import ForageSDK
import XCTest

final class MomentTests: XCTestCase {
    // MARK: - momentURL

    func testMomentURL_givenEnvironments_shouldUseCustomCheckoutOrigin() {
        let moment = Moment.paymentCollectPin(paymentRef: "abc")
        let expected: [Environment: String] = [
            .prod: "https://custom-checkout.joinforage.app/payment/collect-pin?paymentRef=abc",
            .sandbox: "https://custom-checkout.sandbox.joinforage.app/payment/collect-pin?paymentRef=abc",
            .staging: "https://custom-checkout.staging.joinforage.app/payment/collect-pin?paymentRef=abc",
            .cert: "https://custom-checkout.cert.joinforage.app/payment/collect-pin?paymentRef=abc",
            .dev: "https://custom-checkout.dev.joinforage.app/payment/collect-pin?paymentRef=abc",
            .local: "http://custom-checkout.joinforage.localhost/payment/collect-pin?paymentRef=abc"
        ]

        for (environment, url) in expected {
            XCTAssertEqual(momentURL(for: moment, environment: environment)?.absoluteString, url)
        }
    }

    func testMomentURL_givenParamsThatNeedEncoding_shouldEncodeThem() {
        let url = momentURL(for: .paymentCollectPin(paymentRef: "a&b=c"), environment: .dev)
        XCTAssertEqual(url?.absoluteString, "https://custom-checkout.dev.joinforage.app/payment/collect-pin?paymentRef=a%26b%3Dc")
    }

    func testMomentURL_givenBaseURLOverride_shouldUseItsOrigin() {
        let url = momentURL(
            for: .paymentCollectPin(paymentRef: "abc"),
            environment: .dev,
            baseURLOverride: URL(string: "http://localhost:3000")
        )
        XCTAssertEqual(url?.absoluteString, "http://localhost:3000/payment/collect-pin?paymentRef=abc")
    }

    func testMomentURL_givenBaseURLOverrideOutsideDevAndLocal_shouldIgnoreIt() {
        let moment = Moment.paymentCollectPin(paymentRef: "abc")
        let override = URL(string: "http://localhost:3000")

        XCTAssertEqual(
            momentURL(for: moment, environment: .local, baseURLOverride: override)?.absoluteString,
            "http://localhost:3000/payment/collect-pin?paymentRef=abc"
        )
        for environment: Environment in [.sandbox, .cert, .staging, .prod] {
            XCTAssertEqual(
                momentURL(for: moment, environment: environment, baseURLOverride: override),
                momentURL(for: moment, environment: environment),
                "\(environment)"
            )
        }
    }

    func testMomentURL_givenATokenFromAnUnknownEnvironment_shouldUseSandbox() {
        XCTAssertEqual(
            momentURL(for: .paymentCollectPin(paymentRef: "abc"), environment: Environment(sessionToken: "unknown_abc"))?.absoluteString,
            "https://custom-checkout.sandbox.joinforage.app/payment/collect-pin?paymentRef=abc"
        )
    }

    // MARK: - MomentEvent

    func testMomentEvent_givenKnownTypes_shouldParseThem() {
        XCTAssertEqual(MomentEvent(body: #"{"type":"input_hello"}"#), .hello)
        XCTAssertEqual(MomentEvent(body: #"{"type":"input_ready","usecase":"moment"}"#), .ready)
        XCTAssertEqual(MomentEvent(body: #"{"type":"moment_closed","usecase":"moment"}"#), .closed)
        XCTAssertEqual(MomentEvent(body: #"{"type":"submit_success","usecase":"moment"}"#), .success)
        XCTAssertEqual(MomentEvent(body: #"{"type":"submit_success","payload":{"ref":"abc"}}"#), .success)
    }

    func testMomentEvent_givenSubmitFailure_shouldParseTheForageError() {
        let event = MomentEvent(body: #"{"type":"submit_failure","payload":{"code":"resource_not_found","httpStatusCode":404,"message":"Not found"}}"#)
        XCTAssertEqual(
            event,
            .failure(ForageError.create(code: "resource_not_found", httpStatusCode: 404, message: "Not found"))
        )
    }

    func testMomentEvent_givenSubmitFailureWithoutAForageError_shouldBeUnknownServerError() {
        let event = MomentEvent(body: #"{"type":"submit_failure","payload":"oops"}"#)
        XCTAssertEqual(event, .failure(CommonErrors.UNKNOWN_SERVER_ERROR))
    }

    func testMomentEvent_givenInvalidMessages_shouldIgnoreThem() {
        XCTAssertNil(MomentEvent(body: ["type": "input_hello"]))
        XCTAssertNil(MomentEvent(body: "not json"))
        XCTAssertNil(MomentEvent(body: #"{"type":"something_new"}"#))
        XCTAssertNil(MomentEvent(body: "{}"))
    }

    // MARK: - momentInitializeScript

    func testMomentInitializeScript_shouldCallTheReceiveFunctionWithAJSONString() throws {
        let script = try XCTUnwrap(momentInitializeScript(
            merchantID: "mid/123",
            sessionToken: "dev_abc",
            environment: .dev
        ))

        let prefix = "window.forageSdkReceive("
        let suffix = ");"
        XCTAssertTrue(script.hasPrefix(prefix))
        XCTAssertTrue(script.hasSuffix(suffix))

        // the argument is a JS string literal holding the JSON message
        let literal = String(script.dropFirst(prefix.count).dropLast(suffix.count))
        let json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: Data(literal.utf8), options: [.fragmentsAllowed]) as? String
        )
        let message = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any])
        let payload = try XCTUnwrap(message["payload"] as? [String: String])

        XCTAssertEqual(message["name"] as? String, "initialize_iframe")
        XCTAssertEqual(payload, [
            "merchantId": "mid/123",
            "sessionToken": "dev_abc",
            "env": "dev",
            "usecase": "moment",
            "sdkName": "forage-ios-sdk",
            "sdkVersion": ForageSDK.version
        ])
    }

    func testJavaScriptStringLiteral_givenCharactersThatCouldBreakOut_shouldEscapeThem() {
        XCTAssertEqual(javaScriptStringLiteral(#"a"); alert(1); ("#), #""a\"); alert(1); (""#)
        XCTAssertEqual(javaScriptStringLiteral("a\u{2028}b"), "\"a\\u2028b\"")
    }
}
