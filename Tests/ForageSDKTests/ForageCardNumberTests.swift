//
//  ForageCardNumberTests.swift
//
//
//  Created by Jerimiah on 3/17/25.
//  Copyright © 2025-Present Forage Technology Corporation. All rights reserved.
//

@testable import ForageSDK
import XCTest

final class ForageCardNumberTests: XCTestCase {
    var cardNumberTextField: ForageCardNumber!

    override func setUp() {
        setUpForageSDK()
        cardNumberTextField = ForageCardNumber()
    }

    override func tearDown() {
        cardNumberTextField = nil
    }

    // MARK: - Initialization Tests

    func test_initializationShouldBeEmptyAndValid() {
        XCTAssertNotNil(cardNumberTextField)
        XCTAssertTrue(cardNumberTextField.isEmpty)
        XCTAssertTrue(cardNumberTextField.isValid)
        XCTAssertFalse(cardNumberTextField.isComplete)
    }

    func test_multipleInstancesHaveSeparateState() {
        let validTextField = ForageCardNumber()
        let invalidTextField = ForageCardNumber()

        validTextField.enhancedTextField.text = "4242424242424242"
        invalidTextField.enhancedTextField.text = "424242424242"
        
        validTextField.name = "validTextField"
        invalidTextField.name = "invalidTextField"

        validTextField.enhancedTextField.textFieldDidChange()
        invalidTextField.enhancedTextField.textFieldDidChange()

        XCTAssertEqual(validTextField.enhancedTextField.text, "4242 4242 4242 4242")
        XCTAssertEqual(invalidTextField.enhancedTextField.text, "4242 4242 4242")
        
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
        XCTAssertNil(cardNumberTextField.invalidError)

        cardNumberTextField.enhancedTextField.text = "42424242"

        cardNumberTextField.enhancedTextField.textFieldDidChange()

        XCTAssertEqual(cardNumberTextField.enhancedTextField.actualText, "42424242")

        XCTAssertEqual(cardNumberTextField.enhancedTextField.text, "4242 4242")

        XCTAssertFalse(cardNumberTextField.isValid)
        
        XCTAssertEqual(cardNumberTextField.invalidError as! PaymentSheetError, PaymentSheetError.incomplete)

        XCTAssertFalse(cardNumberTextField.isComplete)

        XCTAssertFalse(cardNumberTextField.isEmpty)
        
        cardNumberTextField.enhancedTextField.text = "4242424242424241"

        cardNumberTextField.enhancedTextField.textFieldDidChange()

        XCTAssertEqual(cardNumberTextField.enhancedTextField.actualText, "4242424242424241")

        XCTAssertEqual(cardNumberTextField.enhancedTextField.text, "4242 4242 4242 4241")

        XCTAssertFalse(cardNumberTextField.isValid)
        
        XCTAssertEqual(cardNumberTextField.invalidError as! PaymentSheetError, PaymentSheetError.invalidCardNumber)

        XCTAssertFalse(cardNumberTextField.isComplete)

        XCTAssertFalse(cardNumberTextField.isEmpty)
    }
    
    func test_textLengthMax() {
        XCTAssertNil(cardNumberTextField.invalidError)

        cardNumberTextField.enhancedTextField.text = "424242424242424235"

        cardNumberTextField.enhancedTextField.textFieldDidChange()

        XCTAssertEqual(cardNumberTextField.enhancedTextField.text, "4242 4242 4242 4242")

        XCTAssertTrue(cardNumberTextField.isValid)
        
        XCTAssertNil(cardNumberTextField.invalidError)

        XCTAssertTrue(cardNumberTextField.isComplete)

        XCTAssertFalse(cardNumberTextField.isEmpty)
    }
    
    func test_textField_enterNumericString_shouldReturnTrue() {
        let changesAllowed = cardNumberTextField.textField(UITextField(), shouldChangeCharactersIn: NSRange(), replacementString: "1234")

        XCTAssertTrue(changesAllowed)
    }

    func test_textField_pressBackspace_shouldReturnTrue() {
        let changesAllowed = cardNumberTextField.textField(UITextField(), shouldChangeCharactersIn: NSRange(), replacementString: "")

        XCTAssertTrue(changesAllowed)
    }

    func test_textField_nonNumericStr_shouldReturnFalse() {
        let changesAllowed = cardNumberTextField.textField(UITextField(), shouldChangeCharactersIn: NSRange(), replacementString: "abcdef")

        XCTAssertFalse(changesAllowed)
    }

    func test_textField_pressSpace_shouldReturnFalse() {
        let changesAllowed = cardNumberTextField.textField(UITextField(), shouldChangeCharactersIn: NSRange(), replacementString: " ")

        XCTAssertFalse(changesAllowed)
    }
    
    func test_isDirty() {
        
        XCTAssertFalse(cardNumberTextField.isDirty)
        
        cardNumberTextField.becomeFirstResponder()
        XCTAssertFalse(cardNumberTextField.isDirty)
        
        cardNumberTextField.enhancedTextField.textFieldDidChange()
        XCTAssertTrue(cardNumberTextField.isDirty)
    }
    
    func test_isTouched() {
        XCTAssertFalse(cardNumberTextField.isTouched)
        
        cardNumberTextField.becomeFirstResponder()
        XCTAssertFalse(cardNumberTextField.isTouched)
        
        cardNumberTextField.resignFirstResponder()
        XCTAssertTrue(cardNumberTextField.isTouched)
    }
    
    func test_isFirstResponder() {
        XCTAssertFalse(cardNumberTextField.isFirstResponder)
        
        let result = cardNumberTextField.becomeFirstResponder()
        
        XCTAssertEqual(cardNumberTextField.isFirstResponder, result)
    }

    func test_font() {
        let newFont = UIFont.systemFont(ofSize: 14, weight: .regular)
        cardNumberTextField.font = newFont

        let font = cardNumberTextField.font
        XCTAssertEqual(newFont, font)
    }

    func test_tintColor() {
        let tintColor = UIColor.red
        cardNumberTextField.tfTintColor = tintColor

        let tint = cardNumberTextField.tfTintColor
        XCTAssertEqual(tintColor, tint)
    }

    func test_textAlignment() {
        let alignment = NSTextAlignment.center
        cardNumberTextField.textAlignment = alignment

        let textAlignment = cardNumberTextField.textAlignment
        XCTAssertEqual(alignment, textAlignment)
    }

    func test_textColor() {
        let color = UIColor.red
        cardNumberTextField.textColor = color

        let textColor = cardNumberTextField.textColor
        XCTAssertEqual(color, textColor)
    }

    func test_placeholder() {
        let placeholder = "Test placeholder"
        cardNumberTextField.placeholder = placeholder

        XCTAssertEqual(cardNumberTextField.placeholder, placeholder + "*")
        
        cardNumberTextField.placeholder = nil
        XCTAssertEqual(cardNumberTextField.placeholder, "*")
    }

    func test_clearButton() {
        let mode = UITextField.ViewMode.always
        cardNumberTextField.clearButtonMode = mode

        let clearButton = cardNumberTextField.clearButtonMode
        XCTAssertEqual(clearButton, mode)
    }
    
    func test_clearText() {
        cardNumberTextField.enhancedTextField.text = "4242424242424242"
        cardNumberTextField.enhancedTextField.textFieldDidChange()
        
        XCTAssertEqual(cardNumberTextField.enhancedTextField.text, "4242 4242 4242 4242")
        
        cardNumberTextField.clearText()
        
        XCTAssertEqual(cardNumberTextField.enhancedTextField.text, "")
    }

    func test_padding() {
        let padding = UIEdgeInsets(top: 2.0, left: 2.0, bottom: 2.0, right: 2.0)
        cardNumberTextField.padding = padding

        let textPadding = cardNumberTextField.padding
        XCTAssertEqual(textPadding, padding)
    }

    func test_borderWidth() {
        let newBorderWidth = CGFloat(3)
        cardNumberTextField.borderWidth = newBorderWidth
        XCTAssertEqual(newBorderWidth, cardNumberTextField.borderWidth)
    }

    func test_borderColor() {
        let newBorderColor = UIColor.orange
        cardNumberTextField.borderColor = newBorderColor
        XCTAssertEqual(newBorderColor, cardNumberTextField.borderColor)

        cardNumberTextField.borderColor = nil
        XCTAssertEqual(cardNumberTextField.borderColor, .black)
    }

    func test_cornerRadius() {
        let newCornerRadius = CGFloat(4)
        cardNumberTextField.cornerRadius = newCornerRadius
        XCTAssertEqual(newCornerRadius, cardNumberTextField.cornerRadius)
    }

    func test_masksToBounds() {
        let masksToBounds = false
        cardNumberTextField.masksToBounds = masksToBounds
        XCTAssertEqual(masksToBounds, cardNumberTextField.masksToBounds)
    }
}
