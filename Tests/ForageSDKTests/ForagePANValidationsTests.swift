//
//  ForagePANValidationsTests.swift
//  ForageSDK
//
//  Created by Tiago Oliveira on 28/11/22.
//  © 2023-Present Forage Technology Corporation. All rights reserved.
//

@testable import ForageSDK
import XCTest

final class ForagePANValidationsTests: XCTestCase {
    func test_checkPANLength_withLessThen6digits_shouldReturnNil() {
        let stateINN = ForagePANValidations.checkPANLength("12345")
        XCTAssertNil(stateINN)
    }

    func test_checkPANLength_withInvalid6digitsPan_shouldReturnNil() {
        let stateINN = ForagePANValidations.checkPANLength("123456")
        XCTAssertNil(stateINN)
    }

    func test_checkPANLength_withValid6digitsPan_shouldReturnState() {
        let stateINN = ForagePANValidations.checkPANLength("507680")
        let expectedResult = StateIIN(state: .alabama, iin: "507680", panLengths: [16])
        XCTAssertEqual(expectedResult, stateINN)
    }

    func test_checkPANLength_givenValidCard_shouldRespectMaxDigits() {
        let stateINN = ForagePANValidations.checkPANLength("507680")
        let expectedResult = [16]
        XCTAssertEqual(expectedResult, stateINN?.panLengths)
    }

    func test_checkPANLength_givenMainCard_shouldSupport16and19DigitCards() {
        let stateINN = ForagePANValidations.checkPANLength("507703")
        let expectedResult = [16, 19]
        XCTAssertEqual(expectedResult, stateINN?.panLengths)
        XCTAssertEqual(USState.maine, stateINN?.state)
    }

    func test_checkPANLength_givenValidCard_shouldRespectMaxDigits_forDifferentCards() {
        let stateINN = ForagePANValidations.checkPANLength("600890")
        let expectedResult = [18]
        XCTAssertEqual(expectedResult, stateINN?.panLengths)
    }

    func test_panNumbers_shouldHaveAllUsaStates() {
        let panNumbers = ForagePANValidations.panNumbers
        let expectedQtdStates = 52
        XCTAssertEqual(expectedQtdStates, panNumbers.count)
    }
}
