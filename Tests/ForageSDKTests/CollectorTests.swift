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
        setUpForageSDK()
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

    // MARK: JSON.convertJsonToDictionary

    func testConvertJsonToDictionary_testEmptyDictionary() {
        let json: JSON = .dictionaryValue([:])
        let result = JSON.convertJsonToDictionary(json)
        XCTAssertTrue(result.isEmpty)
    }

    func testConvertJsonToDictionary_testRawValue() {
        let json: JSON = .dictionaryValue(["key": .rawValue("value")])
        let result = JSON.convertJsonToDictionary(json)
        XCTAssertEqual(result["key"] as? String, "value")
    }

    func testConvertJsonToDictionary_testArrayValue() {
        let json: JSON = .dictionaryValue(["array": .arrayValue([.rawValue("item1"), .rawValue("item2")])])
        let result = JSON.convertJsonToDictionary(json)
        let array = result["array"] as? [String]
        XCTAssertEqual(array, ["item1", "item2"])
    }

    func testConvertJsonToDictionary_testNestedDictionary() {
        let nestedJson: JSON = .dictionaryValue(["nestedKey": .rawValue("nestedValue")])
        let json: JSON = .dictionaryValue(["key": nestedJson])
        let result = JSON.convertJsonToDictionary(json)
        let nestedDict = result["key"] as? [String: Any]
        XCTAssertEqual(nestedDict?["nestedKey"] as? String, "nestedValue")
    }

    func testConvertJsonToDictionary_testNilJSON() {
        let result = JSON.convertJsonToDictionary(nil)
        XCTAssertTrue(result.isEmpty)
    }
}
