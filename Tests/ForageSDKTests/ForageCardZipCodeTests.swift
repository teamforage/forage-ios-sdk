//
//  ForageCardZipCodeTests.swift
//
//
//  Created by Jerimiah on 3/17/25.
//  Copyright © 2025-Present Forage Technology Corporation. All rights reserved.
//

@testable import ForageSDK
import XCTest

final class ForageCardZipCodeTests: XCTestCase {
    var cardAZipCodeTextField: ForageCardZipCode!

    override func setUp() {
        setUpForageSDK()
        cardAZipCodeTextField = ForageCardZipCode()
    }

    override func tearDown() {
        cardAZipCodeTextField = nil
    }

    // MARK: - Initialization Tests

    func test_initializationShouldBeEmptyAndValid() {
        XCTAssertNotNil(cardAZipCodeTextField)
        XCTAssertTrue(cardAZipCodeTextField.isEmpty)
        XCTAssertTrue(cardAZipCodeTextField.isValid)
        XCTAssertFalse(cardAZipCodeTextField.isComplete)
    }

    func test_multipleInstancesHaveSeparateState() {
        let validTextField = ForageCardZipCode()
        let invalidTextField = ForageCardZipCode()

        validTextField.enhancedTextField.text = "12345"
        invalidTextField.enhancedTextField.text = "123"
        
        validTextField.name = "validTextField"
        invalidTextField.name = "invalidTextField"

        validTextField.enhancedTextField.textFieldDidChange()
        invalidTextField.enhancedTextField.textFieldDidChange()

        XCTAssertEqual(validTextField.enhancedTextField.text, "12345")
        XCTAssertEqual(invalidTextField.enhancedTextField.text, "123")
        
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
        XCTAssertNil(cardAZipCodeTextField.invalidError)

        cardAZipCodeTextField.enhancedTextField.text = "12"

        cardAZipCodeTextField.enhancedTextField.textFieldDidChange()

        XCTAssertEqual(cardAZipCodeTextField.enhancedTextField.text, "12")

        XCTAssertFalse(cardAZipCodeTextField.isValid)
        
        XCTAssertEqual(cardAZipCodeTextField.invalidError as! PaymentSheetError, PaymentSheetError.incomplete)

        XCTAssertFalse(cardAZipCodeTextField.isComplete)

        XCTAssertFalse(cardAZipCodeTextField.isEmpty)
        
        cardAZipCodeTextField.enhancedTextField.text = "12345"

        cardAZipCodeTextField.enhancedTextField.textFieldDidChange()
        
        XCTAssertEqual(cardAZipCodeTextField.enhancedTextField.text, "12345")

        XCTAssertTrue(cardAZipCodeTextField.isValid)
        
        XCTAssertNil(cardAZipCodeTextField.invalidError)

        XCTAssertTrue(cardAZipCodeTextField.isComplete)
        
        cardAZipCodeTextField.enhancedTextField.text = "1234567"

        cardAZipCodeTextField.enhancedTextField.textFieldDidChange()
        
        XCTAssertEqual(cardAZipCodeTextField.enhancedTextField.text, "12345-67")

        XCTAssertFalse(cardAZipCodeTextField.isValid)
        
        XCTAssertEqual(cardAZipCodeTextField.invalidError as! PaymentSheetError, PaymentSheetError.incomplete)

        XCTAssertFalse(cardAZipCodeTextField.isComplete)
        
        cardAZipCodeTextField.enhancedTextField.text = "123456789"

        cardAZipCodeTextField.enhancedTextField.textFieldDidChange()
        
        XCTAssertEqual(cardAZipCodeTextField.enhancedTextField.text, "12345-6789")
        
        XCTAssertTrue(cardAZipCodeTextField.isValid)
        
        XCTAssertNil(cardAZipCodeTextField.invalidError)

        XCTAssertTrue(cardAZipCodeTextField.isComplete)
    }
    
    func test_textLengthMax() {
        XCTAssertNil(cardAZipCodeTextField.invalidError)

        cardAZipCodeTextField.enhancedTextField.text = "12345-67891"

        cardAZipCodeTextField.enhancedTextField.textFieldDidChange()

        XCTAssertEqual(cardAZipCodeTextField.enhancedTextField.text, "12345-6789")

        XCTAssertTrue(cardAZipCodeTextField.isValid)
        
        XCTAssertNil(cardAZipCodeTextField.invalidError)

        XCTAssertTrue(cardAZipCodeTextField.isComplete)

        XCTAssertFalse(cardAZipCodeTextField.isEmpty)
    }
    
    func test_textField_enterNumericString_shouldReturnTrue() {
        let changesAllowed = cardAZipCodeTextField.textField(UITextField(), shouldChangeCharactersIn: NSRange(), replacementString: "1234")

        XCTAssertTrue(changesAllowed)
    }

    func test_textField_pressBackspace_shouldReturnTrue() {
        let changesAllowed = cardAZipCodeTextField.textField(UITextField(), shouldChangeCharactersIn: NSRange(), replacementString: "")

        XCTAssertTrue(changesAllowed)
    }

    func test_textField_nonNumericStr_shouldReturnFalse() {
        let changesAllowed = cardAZipCodeTextField.textField(UITextField(), shouldChangeCharactersIn: NSRange(), replacementString: "abcdef")

        XCTAssertFalse(changesAllowed)
    }

    func test_textField_pressSpace_shouldReturnFalse() {
        let changesAllowed = cardAZipCodeTextField.textField(UITextField(), shouldChangeCharactersIn: NSRange(), replacementString: " ")

        XCTAssertFalse(changesAllowed)
    }
    
    func test_isDirty() {
        
        XCTAssertFalse(cardAZipCodeTextField.isDirty)
        
        cardAZipCodeTextField.becomeFirstResponder()
        XCTAssertFalse(cardAZipCodeTextField.isDirty)
        
        cardAZipCodeTextField.enhancedTextField.textFieldDidChange()
        XCTAssertTrue(cardAZipCodeTextField.isDirty)
    }
    
    func test_isTouched() {
        XCTAssertFalse(cardAZipCodeTextField.isTouched)
        
        cardAZipCodeTextField.becomeFirstResponder()
        XCTAssertFalse(cardAZipCodeTextField.isTouched)
        
        cardAZipCodeTextField.resignFirstResponder()
        XCTAssertTrue(cardAZipCodeTextField.isTouched)
    }
    
    func test_isFirstResponder() {
        XCTAssertFalse(cardAZipCodeTextField.isFirstResponder)
        
        let result = cardAZipCodeTextField.becomeFirstResponder()
        
        XCTAssertEqual(cardAZipCodeTextField.isFirstResponder, result)
    }

    func test_font() {
        let newFont = UIFont.systemFont(ofSize: 14, weight: .regular)
        cardAZipCodeTextField.font = newFont

        let font = cardAZipCodeTextField.font
        XCTAssertEqual(newFont, font)
    }

    func test_tintColor() {
        let tintColor = UIColor.red
        cardAZipCodeTextField.tfTintColor = tintColor

        let tint = cardAZipCodeTextField.tfTintColor
        XCTAssertEqual(tintColor, tint)
    }

    func test_textAlignment() {
        let alignment = NSTextAlignment.center
        cardAZipCodeTextField.textAlignment = alignment

        let textAlignment = cardAZipCodeTextField.textAlignment
        XCTAssertEqual(alignment, textAlignment)
    }

    func test_textColor() {
        let color = UIColor.red
        cardAZipCodeTextField.textColor = color

        let textColor = cardAZipCodeTextField.textColor
        XCTAssertEqual(color, textColor)
    }

    func test_placeholder() {
        let placeholder = "Test placeholder"
        cardAZipCodeTextField.placeholder = placeholder

        XCTAssertEqual(cardAZipCodeTextField.placeholder, placeholder + "*")
        
        cardAZipCodeTextField.placeholder = nil
        XCTAssertEqual(cardAZipCodeTextField.placeholder, "*")
    }

    func test_clearButton() {
        let mode = UITextField.ViewMode.always
        cardAZipCodeTextField.clearButtonMode = mode

        let clearButton = cardAZipCodeTextField.clearButtonMode
        XCTAssertEqual(clearButton, mode)
    }
    
    func test_clearText() {
        cardAZipCodeTextField.enhancedTextField.text = "123"
        cardAZipCodeTextField.enhancedTextField.textFieldDidChange()
        
        XCTAssertEqual(cardAZipCodeTextField.enhancedTextField.text, "123")
        
        cardAZipCodeTextField.clearText()
        
        XCTAssertEqual(cardAZipCodeTextField.enhancedTextField.text, "")
    }

    func test_padding() {
        let padding = UIEdgeInsets(top: 2.0, left: 2.0, bottom: 2.0, right: 2.0)
        cardAZipCodeTextField.padding = padding

        let textPadding = cardAZipCodeTextField.padding
        XCTAssertEqual(textPadding, padding)
    }

    func test_borderWidth() {
        let newBorderWidth = CGFloat(3)
        cardAZipCodeTextField.borderWidth = newBorderWidth
        XCTAssertEqual(newBorderWidth, cardAZipCodeTextField.borderWidth)
    }

    func test_borderColor() {
        let newBorderColor = UIColor.orange
        cardAZipCodeTextField.borderColor = newBorderColor
        XCTAssertEqual(newBorderColor, cardAZipCodeTextField.borderColor)

        cardAZipCodeTextField.borderColor = nil
        XCTAssertEqual(cardAZipCodeTextField.borderColor, .black)
    }

    func test_cornerRadius() {
        let newCornerRadius = CGFloat(4)
        cardAZipCodeTextField.cornerRadius = newCornerRadius
        XCTAssertEqual(newCornerRadius, cardAZipCodeTextField.cornerRadius)
    }

    func test_masksToBounds() {
        let masksToBounds = false
        cardAZipCodeTextField.masksToBounds = masksToBounds
        XCTAssertEqual(masksToBounds, cardAZipCodeTextField.masksToBounds)
    }
}
