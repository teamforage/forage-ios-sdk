//
//  ForagePANTextFieldTests.swift
//
//
//  Created by Danilo Joksimovic on 2023-08-15.
//

@testable import ForageSDK
import XCTest

final class ForagePANTextFieldTests: XCTestCase {
    var foragePANTextField: ForagePANTextField!

    override func setUp() {
        setUpForageSDK()
        foragePANTextField = ForagePANTextField()
    }

    override func tearDown() {
        foragePANTextField = nil
    }

    // MARK: - Initialization Tests

    func test_initialization_shouldBeEmptyAndValid() {
        XCTAssertNotNil(foragePANTextField)
        XCTAssertTrue(foragePANTextField.isEmpty)
        XCTAssertTrue(foragePANTextField.isValid)
        XCTAssertFalse(foragePANTextField.isComplete)
    }

    func test_multiplePanElements_shouldHaveTheirOwnStates() {
        let validTextField = ForagePANTextField()
        let invalidTextField = ForagePANTextField()

        validTextField.enhancedTextField.text = "5077031234567890123"
        invalidTextField.enhancedTextField.text = "1234123412341234"

        validTextField.enhancedTextField.textFieldDidChange()
        invalidTextField.enhancedTextField.textFieldDidChange()

        XCTAssertEqual(validTextField.enhancedTextField.actualPAN, "5077031234567890123")
        XCTAssertEqual(invalidTextField.enhancedTextField.actualPAN, "1234123412341234")

        XCTAssertEqual(validTextField.enhancedTextField.text, "507703 1234 5678 901 23")
        XCTAssertEqual(invalidTextField.enhancedTextField.text, "1234 1234 1234 1234")

        XCTAssertTrue(validTextField.isValid)
        XCTAssertFalse(invalidTextField.isValid)

        XCTAssertTrue(validTextField.isComplete)
        XCTAssertFalse(invalidTextField.isComplete)

        XCTAssertFalse(validTextField.isEmpty)
        XCTAssertFalse(invalidTextField.isEmpty)

        XCTAssertEqual(validTextField.derivedCardInfo.usState, .maine)
        XCTAssertNil(invalidTextField.derivedCardInfo.usState)
    }
    
    func test_southDakota_shouldBeValidCard() {
        let validTextField = ForagePANTextField()

        validTextField.enhancedTextField.text = "5081321111111111"

        validTextField.enhancedTextField.textFieldDidChange()

        XCTAssertEqual(validTextField.enhancedTextField.actualPAN, "5081321111111111")

        XCTAssertEqual(validTextField.enhancedTextField.text, "5081 3211 1111 1111")

        XCTAssertTrue(validTextField.isValid)

        XCTAssertTrue(validTextField.isComplete)

        XCTAssertFalse(validTextField.isEmpty)
        
        XCTAssertEqual(validTextField.derivedCardInfo.usState, .southDakota)
    }

    func test_textField_enterNumericString_shouldReturnTrue() {
        let changesAllowed = foragePANTextField.textField(UITextField(), shouldChangeCharactersIn: NSRange(), replacementString: "1234")

        XCTAssertTrue(changesAllowed)
    }

    func test_textField_pressBackspace_shouldReturnTrue() {
        let changesAllowed = foragePANTextField.textField(UITextField(), shouldChangeCharactersIn: NSRange(), replacementString: "")

        XCTAssertTrue(changesAllowed)
    }

    func test_textField_nonNumericStr_shouldReturnFalse() {
        let changesAllowed = foragePANTextField.textField(UITextField(), shouldChangeCharactersIn: NSRange(), replacementString: "abcdef")

        XCTAssertFalse(changesAllowed)
    }

    func test_textField_pressSpace_shouldReturnFalse() {
        let changesAllowed = foragePANTextField.textField(UITextField(), shouldChangeCharactersIn: NSRange(), replacementString: " ")

        XCTAssertFalse(changesAllowed)
    }

    func test_font() {
        let newFont = UIFont.systemFont(ofSize: 14, weight: .regular)
        foragePANTextField.font = newFont

        let font = foragePANTextField.font
        XCTAssertEqual(newFont, font)
    }

    func test_tintColor() {
        let tintColor = UIColor.red
        foragePANTextField.tfTintColor = tintColor

        let tint = foragePANTextField.tfTintColor
        XCTAssertEqual(tintColor, tint)
    }

    func test_textAlignment() {
        let alignment = NSTextAlignment.center
        foragePANTextField.textAlignment = alignment

        let textAlignment = foragePANTextField.textAlignment
        XCTAssertEqual(alignment, textAlignment)
    }

    func test_textColor() {
        let color = UIColor.red
        foragePANTextField.textColor = color

        let textColor = foragePANTextField.textColor
        XCTAssertEqual(color, textColor)
    }

    func test_placeholder() {
        let placeholder = "Test placeholder"
        foragePANTextField.placeholder = placeholder

        let textPlaceholder = foragePANTextField.placeholder
        XCTAssertEqual(textPlaceholder, placeholder)
    }

    func test_clearButton() {
        let mode = UITextField.ViewMode.always
        foragePANTextField.clearButtonMode = mode

        let clearButton = foragePANTextField.clearButtonMode
        XCTAssertEqual(clearButton, mode)
    }

    func test_padding() {
        let padding = UIEdgeInsets(top: 2.0, left: 2.0, bottom: 2.0, right: 2.0)
        foragePANTextField.padding = padding

        let textPadding = foragePANTextField.padding
        XCTAssertEqual(textPadding, padding)
    }

    func test_borderWidth() {
        let newBorderWidth = CGFloat(3)
        foragePANTextField.borderWidth = newBorderWidth
        XCTAssertEqual(newBorderWidth, foragePANTextField.borderWidth)
    }

    func test_borderColor() {
        let newBorderColor = UIColor.orange
        foragePANTextField.borderColor = newBorderColor
        XCTAssertEqual(newBorderColor, foragePANTextField.borderColor)
    }

    func test_cornerRadius() {
        let newCornerRadius = CGFloat(4)
        foragePANTextField.cornerRadius = newCornerRadius
        XCTAssertEqual(newCornerRadius, foragePANTextField.cornerRadius)
    }

    func test_masksToBounds() {
        let masksToBounds = false
        foragePANTextField.masksToBounds = masksToBounds
        XCTAssertEqual(masksToBounds, foragePANTextField.masksToBounds)
    }
}
