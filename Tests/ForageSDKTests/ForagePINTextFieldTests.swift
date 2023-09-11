//
//  ForagePINTextFieldTests.swift
//  ForageSDK
//
//  Created by Tiago Oliveira on 28/11/22.
//  Copyright © 2023-Present Forage Technology Corporation. All rights reserved.
//

import XCTest
import VGSCollectSDK
@testable import ForageSDK

final class ForagePINTextFieldTests: XCTestCase {
    
    var observableState: ObservableState?
    var foragePinTextField: ForagePINTextField!
    
    override func setUp() {
        ForageSDK.setup(ForageSDK.Config(
            merchantID: "merchantID123",
            sessionToken: "authToken123"
        ))        
        observableState = nil
        foragePinTextField = ForagePINTextField()
    }
    
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
    }
    
    func test_elementHeight() {
        let newHeight = 200.0
        foragePinTextField.elementHeight = newHeight
        
        let height = foragePinTextField.elementHeight
        XCTAssertEqual(newHeight, height)
    }
    
    func test_inputWidth() {
        let newWidth = 300.0
        foragePinTextField.inputWidth = newWidth

        let width = foragePinTextField.inputWidth
        XCTAssertEqual(newWidth, width)
        
        // Test BasisTheoryTextFieldWrapper input width = default
        let btTextFieldWrapper = BasisTheoryTextFieldWrapper()
        XCTAssertEqual(btTextFieldWrapper.inputWidth, 342)
        
        // Test BasisTheoryTextFieldWrapper input width = custom
        btTextFieldWrapper.inputWidth = 100
        XCTAssertEqual(btTextFieldWrapper.inputWidth, 100)
    }

    func test_inputHeight() {
        let newHeight = 100.0
        foragePinTextField.inputHeight = newHeight

        let height = foragePinTextField.inputHeight
        XCTAssertEqual(newHeight, height)
        
        // Test BasisTheoryTextFieldWrapper input height = default
        let btTextFieldWrapper = BasisTheoryTextFieldWrapper()
        XCTAssertEqual(btTextFieldWrapper.inputHeight, 36)
        
        // Test BasisTheoryTextFieldWrapper input height = custom
        btTextFieldWrapper.inputHeight = 100
        XCTAssertEqual(btTextFieldWrapper.inputHeight, 100)
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
    }
    
    func test_padding() {
        // Test VGSTextFieldWrapper padding
        let vgsTextFieldWrapper = VGSTextFieldWrapper()
        vgsTextFieldWrapper.padding = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        XCTAssertEqual(vgsTextFieldWrapper.padding,  UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
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
    }
    
    func test_placeholder() {
        let placeholder = "Test placeholder"
        foragePinTextField.placeholder = placeholder
        
        let textPlaceholder = foragePinTextField.placeholder
        XCTAssertEqual(textPlaceholder, placeholder)
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
