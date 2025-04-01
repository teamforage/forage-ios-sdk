//
//  ForageCardCVVTests.swift
//
//
//  Created by Jerimiah on 3/17/25.
//  Copyright © 2025-Present Forage Technology Corporation. All rights reserved.
//

@testable import ForageSDK
import XCTest

final class ForageCardCVVTests: XCTestCase {
    var cardCVVTextField: ForageCardCVV!

    override func setUp() {
        setUpForageSDK()
        cardCVVTextField = ForageCardCVV()
    }

    override func tearDown() {
        cardCVVTextField = nil
    }

    // MARK: - Initialization Tests

    func test_initializationShouldBeEmptyAndValid() {
        XCTAssertNotNil(cardCVVTextField)
        XCTAssertTrue(cardCVVTextField.isEmpty)
        XCTAssertTrue(cardCVVTextField.isValid)
        XCTAssertFalse(cardCVVTextField.isComplete)
    }

    func test_multipleInstancesHaveSeparateState() {
        let validTextField = ForageCardCVV()
        let invalidTextField = ForageCardCVV()

        validTextField.enhancedTextField.text = "123"
        invalidTextField.enhancedTextField.text = "12"
        
        validTextField.name = "validTextField"
        invalidTextField.name = "invalidTextField"

        validTextField.enhancedTextField.textFieldDidChange()
        invalidTextField.enhancedTextField.textFieldDidChange()

        XCTAssertEqual(validTextField.enhancedTextField.text, "123")
        XCTAssertEqual(invalidTextField.enhancedTextField.text, "12")
        
        XCTAssertNotEqual(validTextField.name, invalidTextField.name)

        XCTAssertTrue(validTextField.isValid)
        XCTAssertFalse(invalidTextField.isValid)
        
        XCTAssertNil(validTextField.invalidError)
        XCTAssertEqual(invalidTextField.invalidError as! PaymentSheetError, PaymentSheetError.incomplete)

        XCTAssertTrue(validTextField.isComplete)
        XCTAssertFalse(invalidTextField.isComplete)

        XCTAssertFalse(validTextField.isEmpty)
        XCTAssertFalse(invalidTextField.isEmpty)
    }
    
    func test_validators() {
        XCTAssertNil(cardCVVTextField.invalidError)

        cardCVVTextField.enhancedTextField.text = "12"

        cardCVVTextField.enhancedTextField.textFieldDidChange()

        XCTAssertEqual(cardCVVTextField.enhancedTextField.text, "12")

        XCTAssertFalse(cardCVVTextField.isValid)
        
        XCTAssertEqual(cardCVVTextField.invalidError as! PaymentSheetError, PaymentSheetError.incomplete)

        XCTAssertFalse(cardCVVTextField.isComplete)

        XCTAssertFalse(cardCVVTextField.isEmpty)
    }
    
    func test_textLengthMax() {
        XCTAssertNil(cardCVVTextField.invalidError)

        cardCVVTextField.enhancedTextField.text = "12345"

        cardCVVTextField.enhancedTextField.textFieldDidChange()

        XCTAssertEqual(cardCVVTextField.enhancedTextField.text, "1234")

        XCTAssertTrue(cardCVVTextField.isValid)
        
        XCTAssertNil(cardCVVTextField.invalidError)

        XCTAssertTrue(cardCVVTextField.isComplete)

        XCTAssertFalse(cardCVVTextField.isEmpty)
    }
    
    func test_textField_enterNumericString_shouldReturnTrue() {
        let changesAllowed = cardCVVTextField.textField(UITextField(), shouldChangeCharactersIn: NSRange(), replacementString: "1234")

        XCTAssertTrue(changesAllowed)
    }

    func test_textField_pressBackspace_shouldReturnTrue() {
        let changesAllowed = cardCVVTextField.textField(UITextField(), shouldChangeCharactersIn: NSRange(), replacementString: "")

        XCTAssertTrue(changesAllowed)
    }

    func test_textField_nonNumericStr_shouldReturnFalse() {
        let changesAllowed = cardCVVTextField.textField(UITextField(), shouldChangeCharactersIn: NSRange(), replacementString: "abcdef")

        XCTAssertFalse(changesAllowed)
    }

    func test_textField_pressSpace_shouldReturnFalse() {
        let changesAllowed = cardCVVTextField.textField(UITextField(), shouldChangeCharactersIn: NSRange(), replacementString: " ")

        XCTAssertFalse(changesAllowed)
    }
    
    func test_isDirty() {
        
        XCTAssertFalse(cardCVVTextField.isDirty)
        
        cardCVVTextField.becomeFirstResponder()
        XCTAssertFalse(cardCVVTextField.isDirty)
        
        cardCVVTextField.enhancedTextField.textFieldDidChange()
        XCTAssertTrue(cardCVVTextField.isDirty)
    }
    
    func test_isTouched() {
        XCTAssertFalse(cardCVVTextField.isTouched)
        
        cardCVVTextField.becomeFirstResponder()
        XCTAssertFalse(cardCVVTextField.isTouched)
        
        cardCVVTextField.resignFirstResponder()
        XCTAssertTrue(cardCVVTextField.isTouched)
    }
    
    func test_isFirstResponder() {
        XCTAssertFalse(cardCVVTextField.isFirstResponder)
        
        let result = cardCVVTextField.becomeFirstResponder()
        
        XCTAssertEqual(cardCVVTextField.isFirstResponder, result)
    }

    func test_font() {
        let newFont = UIFont.systemFont(ofSize: 14, weight: .regular)
        cardCVVTextField.font = newFont

        let font = cardCVVTextField.font
        XCTAssertEqual(newFont, font)
    }

    func test_tintColor() {
        let tintColor = UIColor.red
        cardCVVTextField.tfTintColor = tintColor

        let tint = cardCVVTextField.tfTintColor
        XCTAssertEqual(tintColor, tint)
    }

    func test_textAlignment() {
        let alignment = NSTextAlignment.center
        cardCVVTextField.textAlignment = alignment

        let textAlignment = cardCVVTextField.textAlignment
        XCTAssertEqual(alignment, textAlignment)
    }

    func test_textColor() {
        let color = UIColor.red
        cardCVVTextField.textColor = color

        let textColor = cardCVVTextField.textColor
        XCTAssertEqual(color, textColor)
    }

    func test_placeholder() {
        let placeholder = "Test placeholder"
        cardCVVTextField.placeholder = placeholder

        XCTAssertEqual(cardCVVTextField.placeholder, placeholder + "*")
        
        cardCVVTextField.placeholder = nil
        XCTAssertEqual(cardCVVTextField.placeholder, "*")
    }

    func test_clearButton() {
        let mode = UITextField.ViewMode.always
        cardCVVTextField.clearButtonMode = mode

        let clearButton = cardCVVTextField.clearButtonMode
        XCTAssertEqual(clearButton, mode)
    }
    
    func test_clearText() {
        cardCVVTextField.enhancedTextField.text = "123"
        cardCVVTextField.enhancedTextField.textFieldDidChange()
        
        XCTAssertEqual(cardCVVTextField.enhancedTextField.text, "123")
        
        cardCVVTextField.clearText()
        
        XCTAssertEqual(cardCVVTextField.enhancedTextField.text, "")
    }

    func test_padding() {
        let padding = UIEdgeInsets(top: 2.0, left: 2.0, bottom: 2.0, right: 2.0)
        cardCVVTextField.padding = padding

        let textPadding = cardCVVTextField.padding
        XCTAssertEqual(textPadding, padding)
    }

    func test_borderWidth() {
        let newBorderWidth = CGFloat(3)
        cardCVVTextField.borderWidth = newBorderWidth
        XCTAssertEqual(newBorderWidth, cardCVVTextField.borderWidth)
    }

    func test_borderColor() {
        let newBorderColor = UIColor.orange
        cardCVVTextField.borderColor = newBorderColor
        XCTAssertEqual(newBorderColor, cardCVVTextField.borderColor)

        cardCVVTextField.borderColor = nil
        XCTAssertEqual(cardCVVTextField.borderColor, .black)
    }

    func test_cornerRadius() {
        let newCornerRadius = CGFloat(4)
        cardCVVTextField.cornerRadius = newCornerRadius
        XCTAssertEqual(newCornerRadius, cardCVVTextField.cornerRadius)
    }

    func test_masksToBounds() {
        let masksToBounds = false
        cardCVVTextField.masksToBounds = masksToBounds
        XCTAssertEqual(masksToBounds, cardCVVTextField.masksToBounds)
    }
}
