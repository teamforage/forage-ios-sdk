//
//  ForagePANTextFieldTests.swift
//  ForageSDK
//
//  Created by Symphony on 28/11/22.
//

import XCTest
@testable import ForageSDK

final class ForagePANTextFieldTests: XCTestCase {
    
    var observableState: ObservableState?
    
    class mockState: ObservableState {
        var _isFirstResponder = false
        var isFirstResponder: Bool {
            get {
                return _isFirstResponder
            }
        }
        
        var _isEmpty = false
        var isEmpty: Bool {
            get {
                return _isEmpty
            }
        }
        
        var _isValid = false
        var isValid: Bool {
            get {
                return _isValid
            }
        }
        
        var _isComplete = false
        var isComplete: Bool {
            get {
                return _isComplete
            }
        }
        
        init(isFirstResponder: Bool, isEmpty: Bool, isValid: Bool, isComplete: Bool) {
            self._isFirstResponder = isFirstResponder
            self._isEmpty = isEmpty
            self._isValid = isValid
            self._isComplete = isComplete
        }
    }
    
    override func setUp() {
        ForageSDK.setup(ForageSDK.Config(environment: .sandbox))
        observableState = nil
    }
    
    func test_givenValidCard_shouldReturnValid() {
        let foragePanTextField = ForagePANTextField()
        foragePanTextField.delegate = self
        
        _ = foragePanTextField.textField(UITextField(), shouldChangeCharactersIn: NSRange(), replacementString: "5076801234123412")
        
        XCTAssertFalse(foragePanTextField.isEmpty)
        XCTAssertFalse(foragePanTextField.isFirstResponder)
        XCTAssertTrue(foragePanTextField.isValid)
        XCTAssertTrue(foragePanTextField.isComplete)
    }
    
    func test_givenValidCard_withMoreDigits_shouldReturnInvalid() {
        let foragePanTextField = ForagePANTextField()
        foragePanTextField.delegate = self
        
        // Add a valid card
        _ = foragePanTextField.textField(UITextField(), shouldChangeCharactersIn: NSRange(), replacementString: "5076801234123412")
        
        // Check for valid state
        XCTAssertFalse(foragePanTextField.isEmpty)
        XCTAssertFalse(foragePanTextField.isFirstResponder)
        XCTAssertTrue(foragePanTextField.isValid)
        XCTAssertTrue(foragePanTextField.isComplete)
        
        // Try to exceed the max length of this valid card
        _ = foragePanTextField.textField(UITextField(), shouldChangeCharactersIn: NSRange(), replacementString: "50768012341234123")
        
        // Check that we didn't let the card go past max length and that we are still valid
        XCTAssertFalse(foragePanTextField.isEmpty)
        XCTAssertFalse(foragePanTextField.isFirstResponder)
        XCTAssertTrue(foragePanTextField.isValid)
        XCTAssertTrue(foragePanTextField.isComplete)
    }
    
    func test_givenTooFewDigits_shouldBeValid() {
        let foragePanTextField = ForagePANTextField()
        foragePanTextField.delegate = self
        
        _ = foragePanTextField.textField(UITextField(), shouldChangeCharactersIn: NSRange(), replacementString: "12341")
        
        XCTAssertFalse(foragePanTextField.isEmpty)
        XCTAssertFalse(foragePanTextField.isFirstResponder)
        XCTAssertTrue(foragePanTextField.isValid)
        XCTAssertFalse(foragePanTextField.isComplete)
        
    }
    
    func test_givenInvalidCard_shouldReturnInvalid() {
        let foragePanTextField = ForagePANTextField()
        foragePanTextField.delegate = self
        
        _ = foragePanTextField.textField(UITextField(), shouldChangeCharactersIn: NSRange(), replacementString: "123412")
        
        XCTAssertFalse(foragePanTextField.isEmpty)
        XCTAssertFalse(foragePanTextField.isFirstResponder)
        XCTAssertFalse(foragePanTextField.isValid)
        XCTAssertFalse(foragePanTextField.isComplete)
        
    }
    
    func test_givenInvalidCard_shouldReturnIdentifying() {
        let foragePanTextField = ForagePANTextField()
        foragePanTextField.delegate = self
        
        _ = foragePanTextField.textField(UITextField(), shouldChangeCharactersIn: NSRange(), replacementString: "50768012341234")
        
        XCTAssertFalse(foragePanTextField.isEmpty)
        XCTAssertFalse(foragePanTextField.isFirstResponder)
        XCTAssertTrue(foragePanTextField.isValid)
        XCTAssertFalse(foragePanTextField.isComplete)
        
    }
    
    func test_forageElementDelegate_focusDidChange() {
        let foragePanTextField = ForagePANTextField()
        
        let expectedIsFirstResponder = true
        let expectedIsEmpty = false
        let expectedIsValid = true
        let expectedIsComplete = false
        
        foragePanTextField.delegate = self
        foragePanTextField.delegate?.focusDidChange(
            mockState(
                isFirstResponder: expectedIsFirstResponder,
                isEmpty: expectedIsEmpty,
                isValid: expectedIsValid,
                isComplete: expectedIsComplete
            )
        )
        
        XCTAssertEqual(expectedIsFirstResponder, observableState?.isFirstResponder)
        XCTAssertEqual(expectedIsEmpty, observableState?.isEmpty)
        XCTAssertEqual(expectedIsValid, observableState?.isValid)
        XCTAssertEqual(expectedIsComplete, observableState?.isComplete)
    }
    
    func test_forageElementDelegate_textFieldDidChange() {
        let foragePanTextField = ForagePANTextField()
        
        let expectedIsFirstResponder = false
        let expectedIsEmpty = true
        let expectedIsValid = false
        let expectedIsComplete = true
        
        foragePanTextField.delegate = self
        foragePanTextField.delegate?.textFieldDidChange(
            mockState(
                isFirstResponder: expectedIsFirstResponder,
                isEmpty: expectedIsEmpty,
                isValid: expectedIsValid,
                isComplete: expectedIsComplete
            )
        )
        
        XCTAssertEqual(expectedIsFirstResponder, observableState?.isFirstResponder)
        XCTAssertEqual(expectedIsEmpty, observableState?.isEmpty)
        XCTAssertEqual(expectedIsValid, observableState?.isValid)
        XCTAssertEqual(expectedIsComplete, observableState?.isComplete)
    }
    
    func test_maskNotAppliedLessThan6Digits() {
        let foragePanTextField = ForagePANTextField()
        let numLessThan6Digits = "12345"
        _ = foragePanTextField.textField(UITextField(), shouldChangeCharactersIn: NSRange(), replacementString: numLessThan6Digits)

        XCTAssertEqual(numLessThan6Digits, foragePanTextField.maskedText)
        XCTAssertEqual(numLessThan6Digits, foragePanTextField.actualText)
    }
    
    func test_16DigitMaskAppliedInvalidNum() {
        let foragePanTextField = ForagePANTextField()
        let invalidNum = "1234567890123456789"
        let invalidNumWithMask = "1234 5678 9012 3456 789"
        _ = foragePanTextField.textField(UITextField(), shouldChangeCharactersIn: NSRange(), replacementString: invalidNum)

        XCTAssertEqual(invalidNumWithMask, foragePanTextField.maskedText)
        XCTAssertEqual(invalidNum, foragePanTextField.actualText)
    }
    
    func test_16DigitMaskAppliedValidNum() {
        let foragePanTextField = ForagePANTextField()
        let validNum = "5076801234567890"
        let validNumWithMask = "5076 8012 3456 7890"
        _ = foragePanTextField.textField(UITextField(), shouldChangeCharactersIn: NSRange(), replacementString: validNum)

        XCTAssertEqual(validNumWithMask, foragePanTextField.maskedText)
        XCTAssertEqual(validNum, foragePanTextField.actualText)
    }
    
    func test_18DigitMaskAppliedValidNum() {
        let foragePanTextField = ForagePANTextField()
        let validNum = "600890123456789012"
        let validNumWithMask = "600890 1234 56789 01 2"
        _ = foragePanTextField.textField(UITextField(), shouldChangeCharactersIn: NSRange(), replacementString: validNum)

        XCTAssertEqual(validNumWithMask, foragePanTextField.maskedText)
        XCTAssertEqual(validNum, foragePanTextField.actualText)
    }
    
    func test_19DigitMaskAppliedValidNum() {
        let foragePanTextField = ForagePANTextField()
        let validNum = "5077031234567890123"
        let validNumWithMask = "507703 1234 5678 901 23"
        _ = foragePanTextField.textField(UITextField(), shouldChangeCharactersIn: NSRange(), replacementString: validNum)

        XCTAssertEqual(validNumWithMask, foragePanTextField.maskedText)
        XCTAssertEqual(validNum, foragePanTextField.actualText)
    }
}

extension ForagePANTextFieldTests: ForageElementDelegate {
    func focusDidChange(_ state: ObservableState) {
        observableState = state
    }
    
    func textFieldDidChange(_ state: ObservableState) {
        observableState = state
    }
}
