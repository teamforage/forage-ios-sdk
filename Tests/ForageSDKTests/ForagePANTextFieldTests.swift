//
//  ForagePANTextFieldTests.swift
//  ForageSDK
//
//  Created by Symphony on 28/11/22.
//

import XCTest
@testable import ForageSDK

final class ForagePANTextFieldTests: XCTestCase {
    
    override func setUp() {
        ForageSDK.setup(ForageSDK.Config(environment: .sandbox))
    }
    
    var cardStatus: CardStatus = .invalid
    
    func test_givenValidCard_shouldReturnValid() {
        let foragePanTextField = ForagePANTextField()
        foragePanTextField.delegate = self
        _ = foragePanTextField.textField(UITextField(), shouldChangeCharactersIn: NSRange(), replacementString: "5076801234123412")
        XCTAssertEqual(CardStatus.valid, cardStatus)
    }
    
    func test_givenValidCard_withMoreDigits_shouldReturnInvalid() {
        let foragePanTextField = ForagePANTextField()
        foragePanTextField.delegate = self
        _ = foragePanTextField.textField(UITextField(), shouldChangeCharactersIn: NSRange(), replacementString: "50768012341234123")
        XCTAssertEqual(CardStatus.invalid, cardStatus)
    }
    
    func test_givenInvalidCard_shouldReturnInvalid() {
        let foragePanTextField = ForagePANTextField()
        foragePanTextField.delegate = self
        _ = foragePanTextField.textField(UITextField(), shouldChangeCharactersIn: NSRange(), replacementString: "123412")
        XCTAssertEqual(CardStatus.invalid, cardStatus)
    }
    
    func test_givenInvalidCard_shouldReturnIdentifying() {
        let foragePanTextField = ForagePANTextField()
        foragePanTextField.delegate = self
        _ = foragePanTextField.textField(UITextField(), shouldChangeCharactersIn: NSRange(), replacementString: "50768012341234")
        XCTAssertEqual(CardStatus.identifying, cardStatus)
    }
}

extension ForagePANTextFieldTests: ForagePANTextFieldDelegate {
    func panNumberStatus(_ view: UIView, cardStatus: CardStatus) {
        self.cardStatus = cardStatus
    }
}
