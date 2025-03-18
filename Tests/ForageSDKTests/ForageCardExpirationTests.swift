//
//  ForageCardExpirationTests.swift
//
//
//  Created by Jerimiah on 3/17/25.
//  Copyright © 2025-Present Forage Technology Corporation. All rights reserved.
//

@testable import ForageSDK
import XCTest

final class ForageCardExpirationTests: XCTestCase {
    var cardExpirationTextField: ForageCardExpiration!

    override func setUp() {
        setUpForageSDK()
        cardExpirationTextField = ForageCardExpiration()
    }

    override func tearDown() {
        cardExpirationTextField = nil
    }

    // MARK: - Initialization Tests

    func test_initializationShouldBeEmptyAndValid() {
        XCTAssertNotNil(cardExpirationTextField)
        XCTAssertTrue(cardExpirationTextField.isEmpty)
        XCTAssertTrue(cardExpirationTextField.isValid)
        XCTAssertFalse(cardExpirationTextField.isComplete)
    }
    
    func test_textField_enterNumericString_shouldReturnTrue() {
        let changesAllowed = cardExpirationTextField.textField(UITextField(), shouldChangeCharactersIn: NSRange(), replacementString: "1234")

        XCTAssertTrue(changesAllowed)
    }

    func test_textField_pressBackspace_shouldReturnTrue() {
        let changesAllowed = cardExpirationTextField.textField(UITextField(), shouldChangeCharactersIn: NSRange(), replacementString: "")

        XCTAssertTrue(changesAllowed)
    }

    func test_textField_nonNumericStr_shouldReturnFalse() {
        let changesAllowed = cardExpirationTextField.textField(UITextField(), shouldChangeCharactersIn: NSRange(), replacementString: "abcdef")

        XCTAssertFalse(changesAllowed)
    }

    func test_textField_pressSpace_shouldReturnFalse() {
        let changesAllowed = cardExpirationTextField.textField(UITextField(), shouldChangeCharactersIn: NSRange(), replacementString: " ")

        XCTAssertFalse(changesAllowed)
    }
    
    func test_isDirty() {
        
        XCTAssertFalse(cardExpirationTextField.isDirty)
        
        cardExpirationTextField.becomeFirstResponder()
        XCTAssertFalse(cardExpirationTextField.isDirty)
        
        cardExpirationTextField.enhancedTextField.textFieldDidChange()
        XCTAssertTrue(cardExpirationTextField.isDirty)
    }
    
    func test_isTouched() {
        XCTAssertFalse(cardExpirationTextField.isTouched)
        
        cardExpirationTextField.becomeFirstResponder()
        XCTAssertFalse(cardExpirationTextField.isTouched)
        
        cardExpirationTextField.resignFirstResponder()
        XCTAssertTrue(cardExpirationTextField.isTouched)
    }
    
    func test_isFirstResponder() {
        XCTAssertFalse(cardExpirationTextField.isFirstResponder)
        
        let result = cardExpirationTextField.becomeFirstResponder()
        
        XCTAssertEqual(cardExpirationTextField.isFirstResponder, result)
    }

    func test_font() {
        let newFont = UIFont.systemFont(ofSize: 14, weight: .regular)
        cardExpirationTextField.font = newFont

        let font = cardExpirationTextField.font
        XCTAssertEqual(newFont, font)
    }

    func test_tintColor() {
        let tintColor = UIColor.red
        cardExpirationTextField.tfTintColor = tintColor

        let tint = cardExpirationTextField.tfTintColor
        XCTAssertEqual(tintColor, tint)
    }

    func test_textAlignment() {
        let alignment = NSTextAlignment.center
        cardExpirationTextField.textAlignment = alignment

        let textAlignment = cardExpirationTextField.textAlignment
        XCTAssertEqual(alignment, textAlignment)
    }

    func test_textColor() {
        let color = UIColor.red
        cardExpirationTextField.textColor = color

        let textColor = cardExpirationTextField.textColor
        XCTAssertEqual(color, textColor)
    }

    func test_placeholder() {
        let placeholder = "Test placeholder"
        cardExpirationTextField.placeholder = placeholder

        XCTAssertEqual(cardExpirationTextField.placeholder, placeholder + "*")
        
        cardExpirationTextField.placeholder = nil
        XCTAssertEqual(cardExpirationTextField.placeholder, "*")
    }

    func test_clearButton() {
        let mode = UITextField.ViewMode.always
        cardExpirationTextField.clearButtonMode = mode

        let clearButton = cardExpirationTextField.clearButtonMode
        XCTAssertEqual(clearButton, mode)
    }
    
    func test_clearText() {
        cardExpirationTextField.enhancedTextField.text = "08/25"
        cardExpirationTextField.enhancedTextField.textFieldDidChange()
        
        XCTAssertEqual(cardExpirationTextField.enhancedTextField.text, "08/25")
        
        cardExpirationTextField.clearText()
        
        XCTAssertEqual(cardExpirationTextField.enhancedTextField.text, "")
    }

    func test_padding() {
        let padding = UIEdgeInsets(top: 2.0, left: 2.0, bottom: 2.0, right: 2.0)
        cardExpirationTextField.padding = padding

        let textPadding = cardExpirationTextField.padding
        XCTAssertEqual(textPadding, padding)
    }

    func test_borderWidth() {
        let newBorderWidth = CGFloat(3)
        cardExpirationTextField.borderWidth = newBorderWidth
        XCTAssertEqual(newBorderWidth, cardExpirationTextField.borderWidth)
    }

    func test_borderColor() {
        let newBorderColor = UIColor.orange
        cardExpirationTextField.borderColor = newBorderColor
        XCTAssertEqual(newBorderColor, cardExpirationTextField.borderColor)

        cardExpirationTextField.borderColor = nil
        XCTAssertEqual(cardExpirationTextField.borderColor, .black)
    }

    func test_cornerRadius() {
        let newCornerRadius = CGFloat(4)
        cardExpirationTextField.cornerRadius = newCornerRadius
        XCTAssertEqual(newCornerRadius, cardExpirationTextField.cornerRadius)
    }

    func test_masksToBounds() {
        let masksToBounds = false
        cardExpirationTextField.masksToBounds = masksToBounds
        XCTAssertEqual(masksToBounds, cardExpirationTextField.masksToBounds)
    }
}
