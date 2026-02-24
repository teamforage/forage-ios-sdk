//
//  ForageCardHolderNameTests.swift
//
//
//  Created by Jerimiah on 3/17/25.
//  © 2025 Forage Technology Corporation. All rights reserved.
//

@testable import ForageSDK
import XCTest

final class ForageCardHolderNameTests: XCTestCase {
    var cardHolderNameTextField: ForageCardHolderName!

    override func setUp() {
        setUpForageSDK()
        cardHolderNameTextField = ForageCardHolderName()
    }

    override func tearDown() {
        cardHolderNameTextField = nil
    }

    // MARK: - Initialization Tests

    func test_initializationShouldBeEmptyAndValid() {
        XCTAssertNotNil(cardHolderNameTextField)
        XCTAssertTrue(cardHolderNameTextField.isEmpty)
        XCTAssertTrue(cardHolderNameTextField.isValid)
        XCTAssertFalse(cardHolderNameTextField.isComplete)
    }

    func test_multipleInstancesHaveSeparateState() {
        let validTextField = ForageCardHolderName()
        let invalidTextField = ForageCardHolderName()

        validTextField.enhancedTextField.text = "Ted Lasso"
        invalidTextField.enhancedTextField.text = ""
        
        validTextField.name = "validTextField"
        invalidTextField.name = "invalidTextField"

        validTextField.enhancedTextField.textFieldDidChange()
        invalidTextField.enhancedTextField.textFieldDidChange()

        XCTAssertEqual(validTextField.enhancedTextField.text, "Ted Lasso")
        XCTAssertEqual(invalidTextField.enhancedTextField.text, "")
        
        XCTAssertNotEqual(validTextField.name, invalidTextField.name)

        XCTAssertTrue(validTextField.isValid)
        XCTAssertFalse(invalidTextField.isValid)
        
        XCTAssertNil(validTextField.invalidError)
        XCTAssertEqual(invalidTextField.invalidError as! PaymentSheetError, PaymentSheetError.incomplete)

        XCTAssertTrue(validTextField.isComplete)
        XCTAssertFalse(invalidTextField.isComplete)

        XCTAssertFalse(validTextField.isEmpty)
        XCTAssertTrue(invalidTextField.isEmpty)
    }
    
    func test_isDirty() {
        
        XCTAssertFalse(cardHolderNameTextField.isDirty)
        
        cardHolderNameTextField.becomeFirstResponder()
        XCTAssertFalse(cardHolderNameTextField.isDirty)
        
        cardHolderNameTextField.enhancedTextField.textFieldDidChange()
        XCTAssertTrue(cardHolderNameTextField.isDirty)
    }
    
    func test_isTouched() {
        XCTAssertFalse(cardHolderNameTextField.isTouched)
        
        cardHolderNameTextField.becomeFirstResponder()
        XCTAssertFalse(cardHolderNameTextField.isTouched)
        
        cardHolderNameTextField.resignFirstResponder()
        XCTAssertTrue(cardHolderNameTextField.isTouched)
    }
    
    func test_isFirstResponder() {
        XCTAssertFalse(cardHolderNameTextField.isFirstResponder)
        
        let result = cardHolderNameTextField.becomeFirstResponder()
        
        XCTAssertEqual(cardHolderNameTextField.isFirstResponder, result)
    }

    func test_font() {
        let newFont = UIFont.systemFont(ofSize: 14, weight: .regular)
        cardHolderNameTextField.font = newFont

        let font = cardHolderNameTextField.font
        XCTAssertEqual(newFont, font)
    }

    func test_tintColor() {
        let tintColor = UIColor.red
        cardHolderNameTextField.tfTintColor = tintColor

        let tint = cardHolderNameTextField.tfTintColor
        XCTAssertEqual(tintColor, tint)
    }

    func test_textAlignment() {
        let alignment = NSTextAlignment.center
        cardHolderNameTextField.textAlignment = alignment

        let textAlignment = cardHolderNameTextField.textAlignment
        XCTAssertEqual(alignment, textAlignment)
    }

    func test_textColor() {
        let color = UIColor.red
        cardHolderNameTextField.textColor = color

        let textColor = cardHolderNameTextField.textColor
        XCTAssertEqual(color, textColor)
    }

    func test_placeholder() {
        let placeholder = "Test placeholder"
        cardHolderNameTextField.placeholder = placeholder

        XCTAssertEqual(cardHolderNameTextField.placeholder, placeholder + "*")
        
        cardHolderNameTextField.placeholder = nil
        XCTAssertEqual(cardHolderNameTextField.placeholder, "*")
    }

    func test_clearButton() {
        let mode = UITextField.ViewMode.always
        cardHolderNameTextField.clearButtonMode = mode

        let clearButton = cardHolderNameTextField.clearButtonMode
        XCTAssertEqual(clearButton, mode)
    }

    func test_padding() {
        let padding = UIEdgeInsets(top: 2.0, left: 2.0, bottom: 2.0, right: 2.0)
        cardHolderNameTextField.padding = padding

        let textPadding = cardHolderNameTextField.padding
        XCTAssertEqual(textPadding, padding)
    }

    func test_borderWidth() {
        let newBorderWidth = CGFloat(3)
        cardHolderNameTextField.borderWidth = newBorderWidth
        XCTAssertEqual(newBorderWidth, cardHolderNameTextField.borderWidth)
    }

    func test_borderColor() {
        let newBorderColor = UIColor.orange
        cardHolderNameTextField.borderColor = newBorderColor
        XCTAssertEqual(newBorderColor, cardHolderNameTextField.borderColor)
        
        cardHolderNameTextField.borderColor = nil
        XCTAssertEqual(cardHolderNameTextField.borderColor, .black)
    }

    func test_cornerRadius() {
        let newCornerRadius = CGFloat(4)
        cardHolderNameTextField.cornerRadius = newCornerRadius
        XCTAssertEqual(newCornerRadius, cardHolderNameTextField.cornerRadius)
    }

    func test_masksToBounds() {
        let masksToBounds = false
        cardHolderNameTextField.masksToBounds = masksToBounds
        XCTAssertEqual(masksToBounds, cardHolderNameTextField.masksToBounds)
    }
}
