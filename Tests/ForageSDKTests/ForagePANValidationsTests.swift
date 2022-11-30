//
//  ForagePANValidationsTests.swift
//  ForageSDK
//
//  Created by Symphony on 28/11/22.
//

import XCTest
@testable import ForageSDK

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
        let expectedResult = StateIIN(state: "ALABAMA", panNumber: "507680", panLength: 16)
        XCTAssertEqual(expectedResult, stateINN)
    }
    
    func test_checkPANLength_givenValidCard_shouldRespectMaxDigits() {
        let stateINN = ForagePANValidations.checkPANLength("507680")
        let expectedResult = 16
        XCTAssertEqual(expectedResult, stateINN?.panLength)
    }
    
    func test_checkPANLength_givenValidCard_shouldRespectMaxDigits_forDifferentCards() {
        let stateINN = ForagePANValidations.checkPANLength("600890")
        let expectedResult = 18
        XCTAssertEqual(expectedResult, stateINN?.panLength)
    }
    
    func test_panNumbers_shouldHaveAllUsaStates() {
        let panNumbers = ForagePANValidations.panNumbers
        let expectedQtdStates = 53
        XCTAssertEqual(expectedQtdStates, panNumbers.count)
    }
}
