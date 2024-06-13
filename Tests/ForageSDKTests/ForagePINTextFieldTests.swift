//
//  ForagePINTextFieldTests.swift
//  ForageSDK
//
//  Created by Tiago Oliveira on 28/11/22.
//  Copyright © 2023-Present Forage Technology Corporation. All rights reserved.
//

@testable import ForageSDK
import VGSCollectSDK
import XCTest

final class ForagePINTextFieldTests: XCTestCase {
    var observableState: ObservableState?
    var foragePinTextField: ForagePINTextField!

    override func setUp() {
        setUpForageSDK()
        observableState = nil
        foragePinTextField = ForagePINTextField()
    }

    class mockState: ObservableState {
        var _isFirstResponder = false
        var isFirstResponder: Bool {
            _isFirstResponder
        }

        var _isEmpty = false
        var isEmpty: Bool {
            _isEmpty
        }

        var _isValid = false
        var isValid: Bool {
            _isValid
        }

        var _isComplete = false
        var isComplete: Bool {
            _isComplete
        }

        init(isFirstResponder: Bool, isEmpty: Bool, isValid: Bool, isComplete: Bool) {
            _isFirstResponder = isFirstResponder
            _isEmpty = isEmpty
            _isValid = isValid
            _isComplete = isComplete
        }
    }

    func test_forageElementDelegate_focusDidChange() {
        let expectedIsFirstResponder = true
        let expectedIsEmpty = false
        let expectedIsValid = true
        let expectedIsComplete = false

        foragePinTextField.delegate = self
        foragePinTextField.delegate?.focusDidChange(
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
        let expectedIsFirstResponder = false
        let expectedIsEmpty = true
        let expectedIsValid = false
        let expectedIsComplete = true

        foragePinTextField.delegate = self
        foragePinTextField.delegate?.textFieldDidChange(
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

    func test_BackgroundColor() {
        // Test ForagePINTextField background color
        foragePinTextField.backgroundColor = .lightGray
        XCTAssertEqual(foragePinTextField.backgroundColor, .lightGray)

        // Test VGSTextFieldWrapper background color
        let vgsTextFieldWrapper = VGSTextFieldWrapper()
        vgsTextFieldWrapper.backgroundColor = .lightGray
        XCTAssertEqual(vgsTextFieldWrapper.backgroundColor, .lightGray)

        // Test BasisTheoryTextFieldWrapper background color
        let btTextFieldWrapper = BasisTheoryTextFieldWrapper()
        btTextFieldWrapper.backgroundColor = .lightGray
        XCTAssertEqual(btTextFieldWrapper.backgroundColor, .lightGray)

        // Test BasisTheoryTextFieldWrapper background color = nil
        btTextFieldWrapper.backgroundColor = nil
        XCTAssertEqual(btTextFieldWrapper.backgroundColor, nil)
        
        // Test ForageTextFieldWrapper background color
        let forageTextFieldWrapper = ForageTextFieldWrapper()
        forageTextFieldWrapper.backgroundColor = .lightGray
        XCTAssertEqual(forageTextFieldWrapper.backgroundColor, .lightGray)
        
        // Test ForageTextFieldWrapper background color = nil
        forageTextFieldWrapper.backgroundColor = nil
        XCTAssertEqual(forageTextFieldWrapper.backgroundColor, nil)
    }

    func test_CornerRadius() {
        // Test ForagePINTextField border radius
        foragePinTextField.cornerRadius = 10
        XCTAssertEqual(foragePinTextField.cornerRadius, 10)

        // Test VGSTextFieldWrapper border radius
        let vgsTextFieldWrapper = VGSTextFieldWrapper()
        vgsTextFieldWrapper.cornerRadius = 10
        XCTAssertEqual(vgsTextFieldWrapper.cornerRadius, 10)

        // Test BasisTheoryTextFieldWrapper corner radius
        let btTextFieldWrapper = BasisTheoryTextFieldWrapper()
        btTextFieldWrapper.cornerRadius = 10
        XCTAssertEqual(btTextFieldWrapper.cornerRadius, 10)
        
        // Test ForageTextFieldWrapper corner radius
        let forageTextFieldWrapper = ForageTextFieldWrapper()
        forageTextFieldWrapper.cornerRadius = 10
        XCTAssertEqual(forageTextFieldWrapper.cornerRadius, 10)
    }

    func test_MasksToBounds() {
        let foragePinTextField = ForagePINTextField()
        let newVal = false
        foragePinTextField.masksToBounds = newVal
        XCTAssertEqual(foragePinTextField.masksToBounds, newVal)

        let vgsTextFieldWrapper = VGSTextFieldWrapper()
        vgsTextFieldWrapper.masksToBounds = newVal
        XCTAssertEqual(vgsTextFieldWrapper.masksToBounds, newVal)

        let btTextFieldWrapper = BasisTheoryTextFieldWrapper()
        btTextFieldWrapper.masksToBounds = newVal
        XCTAssertEqual(btTextFieldWrapper.masksToBounds, newVal)
        
        let forageTextFieldWrapper = ForageTextFieldWrapper()
        forageTextFieldWrapper.masksToBounds = newVal
        XCTAssertEqual(forageTextFieldWrapper.masksToBounds, newVal)
    }

    func test_borderColor() {
        let borderColor = UIColor.black
        foragePinTextField.borderColor = borderColor

        let color = foragePinTextField.borderColor
        XCTAssertEqual(color, borderColor)

        // Test BasisTheoryTextFieldWrapper border color
        let btTextFieldWrapper = BasisTheoryTextFieldWrapper()
        btTextFieldWrapper.borderColor = .blue
        XCTAssertEqual(btTextFieldWrapper.borderColor, .blue)

        // Test BasisTheoryTextFieldWrapper border color = .none
        btTextFieldWrapper.borderColor = .none
        XCTAssertEqual(btTextFieldWrapper.borderColor, nil)
        
        // Test ForageTextFieldWrapper border color
        let forageTextFieldWrapper = ForageTextFieldWrapper()
        forageTextFieldWrapper.borderColor = .blue
        XCTAssertEqual(forageTextFieldWrapper.borderColor, .blue)
        
        // Test ForageTextFieldWrapper border color = .none
        forageTextFieldWrapper.borderColor = .none
        XCTAssertEqual(forageTextFieldWrapper.borderColor, nil)
    }

    func test_borderWidth() {
        let borderWidth = 0.1
        foragePinTextField.borderWidth = borderWidth

        let width = foragePinTextField.borderWidth
        XCTAssertEqual(width, borderWidth)

        // Test VGSTextFieldWrapper border width
        let vgsTextFieldWrapper = VGSTextFieldWrapper()
        vgsTextFieldWrapper.borderWidth = 10
        XCTAssertEqual(vgsTextFieldWrapper.borderWidth, 10)

        // Test BasisTheoryTextFieldWrapper border width
        let btTextFieldWrapper = BasisTheoryTextFieldWrapper()
        btTextFieldWrapper.borderWidth = 10
        XCTAssertEqual(btTextFieldWrapper.borderWidth, 10)
        
        // Test ForageTextFieldWrapper border width
        let forageTextFieldWrapper = ForageTextFieldWrapper()
        forageTextFieldWrapper.borderWidth = 10
        XCTAssertEqual(forageTextFieldWrapper.borderWidth, 10)
    }

    func test_tintColor() {
        let tintColor = UIColor.red
        foragePinTextField.tfTintColor = tintColor

        let tint = foragePinTextField.tfTintColor
        XCTAssertEqual(tintColor, tint)
    }

    func test_textAlignment() {
        let alignment = NSTextAlignment.center
        foragePinTextField.textAlignment = alignment

        let textAlignment = foragePinTextField.textAlignment
        XCTAssertEqual(alignment, textAlignment)

        // Test VGSTextFieldWrapper text alignment
        let vgsTextFieldWrapper = VGSTextFieldWrapper()
        vgsTextFieldWrapper.textAlignment = .center
        XCTAssertEqual(vgsTextFieldWrapper.textAlignment, .center)

        // Test BasisTheoryTextFieldWrapper text alignment
        let btTextFieldWrapper = BasisTheoryTextFieldWrapper()
        btTextFieldWrapper.textAlignment = .center
        XCTAssertEqual(btTextFieldWrapper.textAlignment, .center)
        
        // Test ForageTextFieldWrapper text alignment
        let forageTextFieldWrapper = ForageTextFieldWrapper()
        forageTextFieldWrapper.textAlignment = .center
        XCTAssertEqual(forageTextFieldWrapper.textAlignment, .center)
    }

    func test_padding() {
        // Test VGSTextFieldWrapper padding
        let vgsTextFieldWrapper = VGSTextFieldWrapper()
        vgsTextFieldWrapper.padding = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        XCTAssertEqual(vgsTextFieldWrapper.padding, UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
        
        // Test ForageTextFieldWrapper padding
        let forageTextFieldWrapper = ForageTextFieldWrapper()
        forageTextFieldWrapper.padding = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        XCTAssertEqual(forageTextFieldWrapper.padding, UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
    }

    func test_font() {
        let newFont = UIFont.systemFont(ofSize: 14, weight: .regular)
        foragePinTextField.font = newFont

        let font = foragePinTextField.font
        XCTAssertEqual(newFont, font)

        // Test BasisTheoryTextFieldWrapper font
        let btTextFieldWrapper = BasisTheoryTextFieldWrapper()
        let btFont = UIFont.systemFont(ofSize: 20, weight: .bold)
        btTextFieldWrapper.font = btFont
        XCTAssertEqual(btTextFieldWrapper.font, btFont)
        
        // Test ForageTextFieldWrapper font
        let forageTextFieldWrapper = ForageTextFieldWrapper()
        let forageFont = UIFont.systemFont(ofSize: 20, weight: .bold)
        forageTextFieldWrapper.font = forageFont
        XCTAssertEqual(forageTextFieldWrapper.font, btFont)
    }

    func test_textColor() {
        let color = UIColor.red
        foragePinTextField.textColor = color

        let textColor = foragePinTextField.textColor
        XCTAssertEqual(color, textColor)

        // Test BasisTheoryTextFieldWrapper text color
        let btTextFieldWrapper = BasisTheoryTextFieldWrapper()
        btTextFieldWrapper.textColor = .blue
        XCTAssertEqual(btTextFieldWrapper.textColor, .blue)
        
        // Test ForageTextFieldWrapper text color
        let forageTextFieldWrapper = ForageTextFieldWrapper()
        forageTextFieldWrapper.textColor = .blue
        XCTAssertEqual(forageTextFieldWrapper.textColor, .blue)
    }

    func test_placeholder() {
        let placeholder = "Test placeholder"
        foragePinTextField.placeholder = placeholder

        let textPlaceholder = foragePinTextField.placeholder
        XCTAssertEqual(textPlaceholder, placeholder)
    }

    func test_clearText() {
        // VGS
        let vgsTextFieldWrapper = VGSTextFieldWrapper()
        vgsTextFieldWrapper.clearText()
        vgsTextFieldWrapper.clearText()

        // assert that it does not cause crash and resets status fields!
        XCTAssertEqual(vgsTextFieldWrapper.isComplete, false)
        XCTAssertEqual(vgsTextFieldWrapper.isEmpty, true)
        XCTAssertEqual(vgsTextFieldWrapper.isValid, false)

        // Basis Theory
        let btTextFieldWrapper = BasisTheoryTextFieldWrapper()
        btTextFieldWrapper.clearText()
        btTextFieldWrapper.clearText()

        // assert that it does not cause crash and resets status fields!
        XCTAssertEqual(btTextFieldWrapper.isComplete, false)
        XCTAssertEqual(btTextFieldWrapper.isEmpty, true)
        XCTAssertEqual(btTextFieldWrapper.isValid, false)
        
        // Forage
        let forageTextFieldWrapper = ForageTextFieldWrapper()
        forageTextFieldWrapper.clearText()
        forageTextFieldWrapper.clearText()

        // assert that it does not cause crash and resets status fields!
        XCTAssertEqual(forageTextFieldWrapper.isComplete, false)
        XCTAssertEqual(forageTextFieldWrapper.isEmpty, true)
        XCTAssertEqual(forageTextFieldWrapper.isValid, false)
    }

    // because we force clearText to run on the main thread!
    func test_clientCallsClearText_onBackgroundThread_doesNotCrash() {
        let vgsTextFieldWrapper = VGSTextFieldWrapper()
        let btTextFieldWrapper = BasisTheoryTextFieldWrapper()
        let forageTextFieldWrapper = ForageTextFieldWrapper()

        let expectation = XCTestExpectation(description: "should clear text without crashing")

        DispatchQueue.global(qos: .userInitiated).async {
            vgsTextFieldWrapper.clearText()
            vgsTextFieldWrapper.clearText()

            btTextFieldWrapper.clearText()
            btTextFieldWrapper.clearText()
            
            forageTextFieldWrapper.clearText()
            forageTextFieldWrapper.clearText()

            DispatchQueue.main.async {
                XCTAssertFalse(vgsTextFieldWrapper.isComplete)
                XCTAssertFalse(btTextFieldWrapper.isComplete)
                XCTAssertFalse(forageTextFieldWrapper.isComplete)

                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 3.0)
    }
    
    func test_RosettaPINTextField_rejectsNonNumbers() {
        let forageTextFieldWrapper = ForageTextFieldWrapper()
        let result = forageTextFieldWrapper.textField(UITextField(), shouldChangeCharactersIn: NSRange(), replacementString: "a")
        XCTAssertEqual(result, false)
    }
    
    func test_RosettaPINTextField_allowsNumbers() {
        let forageTextFieldWrapper = ForageTextFieldWrapper()
        let result = forageTextFieldWrapper.textField(UITextField(), shouldChangeCharactersIn: NSRange(), replacementString: "1")
        XCTAssertEqual(result, true)
    }
    
    func test_RosettaPINTextField_rejectsOverFourDigits() {
        let forageTextFieldWrapper = ForageTextFieldWrapper()
        let result = forageTextFieldWrapper.textField(UITextField(), shouldChangeCharactersIn: NSRange(), replacementString: "12345")
        XCTAssertEqual(result, false)
    }
    
    func test_RosettaPINTextField_allowsFourDigits() {
        let forageTextFieldWrapper = ForageTextFieldWrapper()
        let result = forageTextFieldWrapper.textField(UITextField(), shouldChangeCharactersIn: NSRange(), replacementString: "1234")
        XCTAssertEqual(result, true)
    }
}

extension ForagePINTextFieldTests: ForageElementDelegate {
    func focusDidChange(_ state: ObservableState) {
        observableState = state
    }

    func textFieldDidChange(_ state: ObservableState) {
        observableState = state
    }
}
