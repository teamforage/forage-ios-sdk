//
//  CollectorTests.swift
//
//
//  Created by Shardendu Gautam on 6/26/23.
//  Copyright © 2023-Present Forage Technology Corporation. All rights reserved.
//

@testable import ForageSDK
import BasisTheoryElements
import Foundation
import VGSCollectSDK
import XCTest

class VaultCollectorTests: XCTestCase {
    override func setUp() {
        ForageSDK.setup(ForageSDK.Config(
            merchantID: "merchantID123",
            sessionToken: "authToken123"
        ))
    }

    func testVGSCollectWrapper_SetCustomHeaders_HeaderKey() {
        let vgsWrapper = CollectorFactory.createVGS(environment: Environment.sandbox)

        let headers = ["HeaderKey": "HeaderValue"]
        let xKey = ["vgsXKey": "VgsXKeyValue"]
        vgsWrapper.setCustomHeaders(headers: headers, xKey: xKey)

        XCTAssertEqual(vgsWrapper.vgsCollect.customHeaders?["HeaderKey"], "HeaderValue")
    }

    func testVGSCollectWrapper_SetCustomHeaders_XKey() {
        let vgsWrapper = CollectorFactory.createVGS(environment: Environment.sandbox)

        let headers = ["HeaderKey": "HeaderValue"]
        let xKey = ["vgsXKey": "VgsXKeyValue"]
        vgsWrapper.setCustomHeaders(headers: headers, xKey: xKey)

        XCTAssertEqual(vgsWrapper.vgsCollect.customHeaders?["X-KEY"], "VgsXKeyValue")
    }

    func testBasisTheoryWrapper_SetCustomHeaders_HeaderKey() {
        let textElement = TextElementUITextField()
        let basisTheoryWrapper = CollectorFactory.createBasisTheory(environment: Environment.sandbox, textElement: textElement)

        let headers = ["HeaderKey": "HeaderValue"]
        let xKey = ["btXKey": "btXKeyValue"]
        basisTheoryWrapper.setCustomHeaders(headers: headers, xKey: xKey)

        XCTAssertEqual(basisTheoryWrapper.customHeaders["HeaderKey"], "HeaderValue")
    }

    func testBasisTheoryWrapper_SetCustomHeaders_XKey() {
        let textElement = TextElementUITextField()
        let basisTheoryWrapper = CollectorFactory.createBasisTheory(environment: Environment.sandbox, textElement: textElement)

        let headers = ["HeaderKey": "HeaderValue"]
        let xKey = ["btXKey": "btXKeyValue"]
        basisTheoryWrapper.setCustomHeaders(headers: headers, xKey: xKey)

        XCTAssertEqual(basisTheoryWrapper.customHeaders["X-KEY"], "btXKeyValue")
    }

    func testBasisTheoryWrapper_GetPaymentMethodToken() throws {
        let textElement = TextElementUITextField()
        let basisTheoryWrapper = CollectorFactory.createBasisTheory(environment: Environment.sandbox, textElement: textElement)

        let token = "123456,789012"
        let resultToken = try basisTheoryWrapper.getPaymentMethodToken(paymentMethodToken: token)
        XCTAssertEqual(resultToken, "789012")
    }
}
