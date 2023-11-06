//
//  MaskedUITextFieldTests.swift
//
//
//  Created by Danilo Joksimovic on 2023-08-14.
//

@testable import ForageSDK
import XCTest

final class MaskedUITextFieldTests: XCTestCase {
    var maskedTextField: MaskedUITextField!

    override func setUp() {
        ForageSDK.setup(ForageSDK.Config(merchantID: "merchant123", sessionToken: "sandbox_auth123"))
        // .setup() currently doesn't allow us to update the environment
        ForageSDK.shared.environment = .sandbox
        maskedTextField = MaskedUITextField()
    }

    override func tearDown() {
        maskedTextField = nil
    }

    // MARK: - Initialization Tests

    func test_initialization_shouldBeEmptyAndValid() {
        XCTAssertNotNil(maskedTextField)
        XCTAssertTrue(maskedTextField.isEmpty)
        XCTAssertTrue(maskedTextField.isValid)
        XCTAssertFalse(maskedTextField.isComplete)
    }

    // MARK: - Validation Tests

    func testValidation_valid16DigitCard_shouldBeValid() {
        maskedTextField.text = "50770812 3456 7890"
        maskedTextField.textFieldDidChange()

        XCTAssertFalse(maskedTextField.isEmpty)
        XCTAssertTrue(maskedTextField.isValid)
        XCTAssertTrue(maskedTextField.isComplete)
        XCTAssertEqual(maskedTextField.actualPAN, "5077081234567890")
    }

    func testValidation_partiallyIdentifying16DigitCard_shouldBeValid() {
        maskedTextField.text = "50770812 3456 78"
        maskedTextField.textFieldDidChange()

        XCTAssertFalse(maskedTextField.isEmpty)
        XCTAssertTrue(maskedTextField.isValid)
        XCTAssertFalse(maskedTextField.isComplete)
        XCTAssertEqual(maskedTextField.actualPAN, "50770812345678")
    }

    func testValidation_identifyingIIN_shouldBeValid() {
        maskedTextField.text = "12345"
        maskedTextField.textFieldDidChange()

        XCTAssertFalse(maskedTextField.isEmpty)
        XCTAssertTrue(maskedTextField.isValid)
        XCTAssertFalse(maskedTextField.isComplete)
        XCTAssertEqual(maskedTextField.actualPAN, "12345")
    }

    func testValidation_invalidIIN_shouldBeInvalid() {
        maskedTextField.text = "123412"
        maskedTextField.textFieldDidChange()

        XCTAssertFalse(maskedTextField.isEmpty)
        XCTAssertFalse(maskedTextField.isValid)
        XCTAssertFalse(maskedTextField.isComplete)
        XCTAssertEqual(maskedTextField.actualPAN, "123412")
    }

    func testValidation_validCardWithExtraDigits_shouldBeInvalid() {
        let expectedPAN = "5077081234567890"
        maskedTextField.text = expectedPAN
        maskedTextField.textFieldDidChange()

        // Check for valid state
        XCTAssertFalse(maskedTextField.isEmpty)
        XCTAssertFalse(maskedTextField.isFirstResponder)
        XCTAssertTrue(maskedTextField.isValid)
        XCTAssertTrue(maskedTextField.isComplete)

        // Try to exceed the max length of this valid card
        maskedTextField.text = "50770812345678901"

        // Check that we didn't let the card go past max length and that we are still valid
        XCTAssertFalse(maskedTextField.isEmpty)
        XCTAssertFalse(maskedTextField.isFirstResponder)
        XCTAssertTrue(maskedTextField.isValid)
        XCTAssertTrue(maskedTextField.isComplete)
        XCTAssertEqual(maskedTextField.actualPAN, expectedPAN)
    }

    // MARK: - Validation with special cards

    func testValidation_specialButProd_shouldBeInvalidAndIncomplete() {
        ForageSDK.shared.environment = .prod
        maskedTextField.text = "4444444444444454"
        maskedTextField.textFieldDidChange()

        XCTAssertFalse(maskedTextField.isEmpty)
        XCTAssertFalse(maskedTextField.isValid)
        XCTAssertFalse(maskedTextField.isComplete)
        XCTAssertEqual(maskedTextField.actualPAN, "4444444444444454")
    }

    func testValidation_specialInsufficientFundsCard_shouldBeValid() {
        maskedTextField.text = "4444444444444451"
        maskedTextField.textFieldDidChange()

        XCTAssertFalse(maskedTextField.isEmpty)
        XCTAssertTrue(maskedTextField.isValid)
        XCTAssertTrue(maskedTextField.isComplete)
        XCTAssertEqual(maskedTextField.actualPAN, "4444444444444451")
    }

    func testValidation_specialInvalidCardNum_shouldBeValid() {
        maskedTextField.text = "5555555555555514"
        maskedTextField.textFieldDidChange()

        XCTAssertFalse(maskedTextField.isEmpty)
        XCTAssertTrue(maskedTextField.isValid)
        XCTAssertTrue(maskedTextField.isComplete)
        XCTAssertEqual(maskedTextField.actualPAN, "5555555555555514")
    }

    func testValidation_specialExpiredCardNum_shouldBeValid() {
        maskedTextField.text = "5555555555555554"
        maskedTextField.textFieldDidChange()

        XCTAssertFalse(maskedTextField.isEmpty)
        XCTAssertTrue(maskedTextField.isValid)
        XCTAssertTrue(maskedTextField.isComplete)
        XCTAssertEqual(maskedTextField.actualPAN, "5555555555555554")
    }

    func testValidation_completeSpecial9999Card_shouldBeValid() {
        maskedTextField.text = "9999 1234 1111 1111"
        maskedTextField.textFieldDidChange()

        XCTAssertFalse(maskedTextField.isEmpty)
        XCTAssertTrue(maskedTextField.isValid)
        XCTAssertTrue(maskedTextField.isComplete)
        XCTAssertEqual(maskedTextField.actualPAN, "9999123411111111")
    }

    func testValidation_partialSpecial9999Card_shouldBeValidButIncomplete() {
        maskedTextField.text = "9999 1234"
        maskedTextField.textFieldDidChange()

        XCTAssertFalse(maskedTextField.isEmpty)
        XCTAssertTrue(maskedTextField.isValid)
        XCTAssertFalse(maskedTextField.isComplete)
        XCTAssertEqual(maskedTextField.actualPAN, "99991234")
    }

    func testValidation_zeroEbtCashCard() {
        maskedTextField.text = "6543 2123 1234 1234"
        maskedTextField.textFieldDidChange()

        XCTAssertFalse(maskedTextField.isEmpty)
        XCTAssertTrue(maskedTextField.isValid)
        XCTAssertTrue(maskedTextField.isComplete)
        XCTAssertEqual(maskedTextField.actualPAN, "6543212312341234")
    }

    // MARK: Masking

    func testMasking_valid16DigitCard_shouldApply16Mask() {
        maskedTextField.text = "50770812 3456 7890"
        maskedTextField.textFieldDidChange()

        XCTAssertEqual(maskedTextField.text, "5077 0812 3456 7890")
        XCTAssertEqual(maskedTextField.actualPAN, "5077081234567890")
    }

    func testMasking_sixDigits_shouldApply16Mask() {
        maskedTextField.text = "123456"
        maskedTextField.textFieldDidChange()

        XCTAssertEqual(maskedTextField.text, "1234 56")
        XCTAssertEqual(maskedTextField.actualPAN, "123456")
    }

    func testMasking_lessThanSixDigits_shouldNotApplyMask() {
        maskedTextField.text = "12345"
        maskedTextField.textFieldDidChange()

        XCTAssertEqual(maskedTextField.text, "12345")
        XCTAssertEqual(maskedTextField.actualPAN, "12345")
    }

    func testMasking_16DigitInProgress_shouldApply16Mask() {
        maskedTextField.text = "507708 1"
        maskedTextField.textFieldDidChange()

        XCTAssertEqual(maskedTextField.text, "5077 081")
        XCTAssertEqual(maskedTextField.actualPAN, "5077081")
    }

    func testMasking_invalid16Digit_shouldApplyNoIINMatchMask() {
        maskedTextField.text = "1234567812345678"
        maskedTextField.textFieldDidChange()

        XCTAssertEqual(maskedTextField.text, "1234 5678 1234 5678")
        XCTAssertEqual(maskedTextField.actualPAN, "1234567812345678")
    }

    func testMasking_invalid17Digit_shouldApplyNoIINMatchMask() {
        maskedTextField.text = "12345678123456781"
        maskedTextField.textFieldDidChange()

        XCTAssertEqual(maskedTextField.text, "1234 5678 1234 5678 1")
        XCTAssertEqual(maskedTextField.actualPAN, "12345678123456781")
    }

    func testMasking_invalid18Digit_shouldApplyNoIINMatchMask() {
        maskedTextField.text = "123456781234567812"
        maskedTextField.textFieldDidChange()

        XCTAssertEqual(maskedTextField.text, "1234 5678 1234 5678 12")
        XCTAssertEqual(maskedTextField.actualPAN, "123456781234567812")
    }

    func testMasking_invalid19Digit_shouldApplyNoIINMatchMask() {
        maskedTextField.text = "1234567812345678123"
        maskedTextField.textFieldDidChange()

        XCTAssertEqual(maskedTextField.text, "1234 5678 1234 5678 123")
        XCTAssertEqual(maskedTextField.actualPAN, "1234567812345678123")
    }

    func testMasking_valid18Digit_shouldApply18Mask() {
        maskedTextField.text = "600890123456789012"
        maskedTextField.textFieldDidChange()

        XCTAssertEqual(maskedTextField.text, "600890 1234 56789 01 2")
        XCTAssertEqual(maskedTextField.actualPAN, "600890123456789012")
    }

    func testMasking_valid19Digit_shouldApply19Mask() {
        maskedTextField.text = "5077031234567890123"
        maskedTextField.textFieldDidChange()

        XCTAssertEqual(maskedTextField.text, "507703 1234 5678 901 23")
        XCTAssertEqual(maskedTextField.actualPAN, "5077031234567890123")
    }

    func testMasking_validSpecialCard_shouldApplyNoIINMatchMask() {
        maskedTextField.text = "9999123412341234123"
        maskedTextField.textFieldDidChange()

        XCTAssertEqual(maskedTextField.text, "9999 1234 1234 1234 123")
        XCTAssertEqual(maskedTextField.actualPAN, "9999123412341234123")
    }

    // MARK: Masking with backspace

    func testMasking_backspaceAtEnd_shouldRemoveLastChar() {
        maskedTextField.text = "5077031111111111121"
        maskedTextField.textFieldDidChange()

        // move cursor to end of text
        moveCursor(by: maskedTextField.text?.count ?? 19)
        pressBackspace()
        let precedingChar = getPrecedingChar()
        let expectedPAN = "507703 1111 1111 111 2"

        XCTAssertEqual(maskedTextField.text, expectedPAN)
        XCTAssertEqual(precedingChar, "2")
        XCTAssertEqual(maskedTextField.actualPAN, removeWhitespace(from: expectedPAN))
    }

    func testMasking_backspaceChangeIIN_shouldChangeMask() {
        maskedTextField.text = "5077031000000000000"
        maskedTextField.textFieldDidChange()

        // move cursor to end of IIN
        moveCursor(by: 6)
        pressBackspace()
        let precedingChar = getPrecedingChar()
        let expectedPAN = "5077 0100 0000 0000"

        // Now uses New Hampshire 16-digit mask
        XCTAssertEqual(maskedTextField.text, "5077 0100 0000 0000")
        XCTAssertEqual(precedingChar, " ")
        XCTAssertEqual(maskedTextField.actualPAN, removeWhitespace(from: expectedPAN))
    }

    func testMasking_backspaceChangeIntermediateDigit_shouldShiftPAN() {
        maskedTextField.text = "50770392111111111111"
        maskedTextField.textFieldDidChange()

        XCTAssertEqual(maskedTextField.text, "507703 9211 1111 111 11")

        // move cursor to right of first "2" char
        moveCursor(by: 9)
        pressBackspace()
        let precedingChar = getPrecedingChar()

        let expectedPAN = "507703 9111 1111 111 1"

        // did cursor move back to char preceding "2" character
        XCTAssertEqual(precedingChar, "9")
        // did remove the "2" character and shift the PAN
        XCTAssertEqual(maskedTextField.text, expectedPAN)
        XCTAssertEqual(maskedTextField.actualPAN, removeWhitespace(from: expectedPAN))
    }

    func testMasking_backspaceOnGap_shouldOnlyMoveCursor() {
        maskedTextField.text = "50770311111111111111"
        maskedTextField.textFieldDidChange()

        let expectedPAN = "507703 1111 1111 111 11"
        XCTAssertEqual(maskedTextField.text, expectedPAN)

        // move cursor to the immediate right of first gap (" ") char
        moveCursor(by: 7)
        pressBackspace()
        let precedingChar = getPrecedingChar()

        // did cursor move back to char preceding the gap (" ") character
        XCTAssertEqual(precedingChar, "3")
        // did not change display text, only moved the cursor
        XCTAssertEqual(maskedTextField.text, expectedPAN)
        XCTAssertEqual(maskedTextField.actualPAN, removeWhitespace(from: expectedPAN))
    }

    func test_clearButton() {
        maskedTextField.text = ""
        maskedTextField.textFieldDidChange()
        XCTAssertEqual(maskedTextField.rightViewMode.rawValue, 0)

        maskedTextField.text = "1111 1111"
        maskedTextField.textFieldDidChange()
        XCTAssertEqual(maskedTextField.rightViewMode.rawValue, 1)
    }

    func moveCursor(by offset: Int) {
        var cursorOffset = maskedTextField.offset(from: maskedTextField.beginningOfDocument, to: maskedTextField.selectedTextRange!.start)
        cursorOffset += offset

        if let newPosition = maskedTextField.position(from: maskedTextField.beginningOfDocument, offset: cursorOffset) {
            maskedTextField.selectedTextRange = maskedTextField.textRange(from: newPosition, to: newPosition)
        }
    }

    func removeWhitespace(from text: String) -> String {
        text.replacingOccurrences(of: " ", with: "")
    }

    func pressBackspace() {
        maskedTextField.deleteBackward()
        maskedTextField.textFieldDidChange()
    }

    private func getPrecedingChar() -> Character {
        let newCursorOffset = maskedTextField.offset(from: maskedTextField.beginningOfDocument, to: maskedTextField.selectedTextRange!.start)
        let previousIndex = maskedTextField.text!.index(maskedTextField.text!.startIndex, offsetBy: newCursorOffset - 1)
        return maskedTextField.text![previousIndex]
    }
}
