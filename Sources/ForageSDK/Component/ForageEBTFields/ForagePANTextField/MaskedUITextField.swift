//
//  MaskedUITextField.swift
//
//
//  Created by Danilo Joksimovic on 2023-08-14.
//  © 2023-2025 Forage Technology Corporation. All rights reserved.
//

import Foundation
import UIKit

enum MaskPattern: String {
    case unset = "###################"
    case sixteenDigits = "#### #### #### ####"
    case eighteenDigits = "###### #### ##### ## #"
    case nineteenDigits = "###### #### #### ### ##"
    case noIINmatch = "#### #### #### #### ###"
}

class MaskedUITextField: FloatingTextField, ObservableState {
    // MARK: - Properties

    var actualPAN: String = ""

    private var wasBackspacePressed = false

    /// A delegate that informs the client about the state of the entered card number (validation, focus)
    public weak var forageDelegate: ForageElementDelegate? {
        didSet {
            delegate = forageDelegate as? UITextFieldDelegate
        }
    }

    @IBInspectable public private(set) var isEmpty = true
    @IBInspectable public private(set) var isValid = true
    @IBInspectable public private(set) var isComplete = false
    public private(set) var derivedCardInfo: DerivedCardInfo = .init()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        autocorrectionType = .no
        addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }

    // MARK: - Text Field Actions

    override func deleteBackward() {
        wasBackspacePressed = true
        super.deleteBackward()
    }

    @objc func textFieldDidChange() {
        defer { wasBackspacePressed = false }

        guard let text = text else { return }

        // the UITextFieldDelegate ensures the user can enter only numeric inputs
        var newUnmaskedText = text.replacingOccurrences(of: " ", with: "")
        let matchedStateIIN = ForagePANValidations.checkPANLength(newUnmaskedText)

        newUnmaskedText = trimTrailingDigits(newUnmaskedText, stateIIN: matchedStateIIN)

        validateText(newUnmaskedText, stateIIN: matchedStateIIN)

        let maskPattern = determineMaskPattern(for: newUnmaskedText, stateIIN: matchedStateIIN)
        applyMask(newUnmaskedText, maskPattern: maskPattern)

        actualPAN = newUnmaskedText

        if !text.isEmpty {
            addClearButton(isVisible: true)
        } else {
            addClearButton(isVisible: false)
            becomeFirstResponder()
        }
    }

    // MARK: - Text Handling

    private func trimTrailingDigits(_ newUnmaskedText: String, stateIIN: StateIIN?) -> String {
        let maxPanLength = min(
            newUnmaskedText.count,
            stateIIN?.panLengths.max() ?? 19
        )

        return String(newUnmaskedText.prefix(maxPanLength))
    }

    private func validateText(_ newUnmaskedText: String, stateIIN: StateIIN?) {
        defer {
            isEmpty = newUnmaskedText.isEmpty
            forageDelegate?.textFieldDidChange(self) // notify client about latest validation status.
        }

        let isProdEnvironment = ForageSDK.shared.environment == Environment.prod
        if !isProdEnvironment && isSpecialCard(newUnmaskedText) {
            isValid = true
            isComplete = newUnmaskedText.count >= 16 && newUnmaskedText.count <= 19
            derivedCardInfo.usState = nil
            return
        }

        // Prior to seeing 6 digits, the PAN is considered valid but incomplete.
        if newUnmaskedText.count < 6 {
            isValid = true
            isComplete = false
            derivedCardInfo.usState = nil
            return
        }

        if let stateIIN = stateIIN {
            isValid = true
            isComplete = stateIIN.panLengths.contains(newUnmaskedText.count)
            derivedCardInfo.usState = stateIIN.state
            return
        }

        // If 6 or more digits are included and the first 6 digits don't map to a known state
        isValid = false
        isComplete = false
        derivedCardInfo.usState = nil
    }

    private func determineMaskPattern(for newUnmaskedText: String, stateIIN: StateIIN?) -> MaskPattern {
        if newUnmaskedText.count < 6 {
            return MaskPattern.unset
        }
        if let stateIIN = stateIIN {
            if stateIIN.panLengths.contains(16) && stateIIN.panLengths.contains(19) {
                return newUnmaskedText.count <= 16 ? MaskPattern.sixteenDigits : MaskPattern.nineteenDigits
            } else if stateIIN.panLengths.contains(16) {
                return MaskPattern.sixteenDigits
            } else if stateIIN.panLengths.contains(18) {
                return MaskPattern.eighteenDigits
            } else if stateIIN.panLengths.contains(19) {
                return MaskPattern.nineteenDigits
            }
        }
        return MaskPattern.noIINmatch
    }

    private func applyMask(_ newUnmaskedText: String, maskPattern: MaskPattern) {
        // Find the current cursor position
        var cursorOffset = offset(from: beginningOfDocument, to: selectedTextRange!.start)
        let maskedText = getMaskedText(newUnmaskedText, maskPattern: maskPattern)
        let isCursorAtEndOfText = cursorOffset - maskedText.count >= 0

        // when the mask gets set at 6 digits
        if newUnmaskedText.count == 6 && cursorOffset - maskedText.count == -1 {
            // move the cursor forward
            cursorOffset += 1
        }

        if wasBackspacePressed && isCursorAtEndOfText {
            text = maskedText
            return
        }

        // Apply the masked text to the text field with a new character, we use " " string as "any" character
        let maskedTextWithNewChar = getMaskedText(newUnmaskedText + " ", maskPattern: maskPattern)
        text = maskedText

        // Calculate the new cursor position
        if !isCursorAtEndOfText
            && !wasBackspacePressed
            && isNextCharacterGap(offset: cursorOffset, maskPattern: maskPattern) {
            // move cursor an additional step forward
            cursorOffset += 1
        }
        // Check if a whitespace (or other non-placeholder character) was added during the masking
        if isCursorAtEndOfText && maskedTextWithNewChar.count > maskedText.count + 1 {
            // move cursor an additional step forward
            cursorOffset += 1
        }

        setNewCursorPosition(cursorOffset)
    }

    private func wasBackspacePressedOnGap(offset cursorOffset: NSInteger, maskPattern: MaskPattern) -> Bool {
        wasBackspacePressed && cursorOffset > 0 && maskPattern.rawValue[safe: cursorOffset] == " "
    }

    private func isNextCharacterGap(offset cursorOffset: NSInteger, maskPattern: MaskPattern) -> Bool {
        cursorOffset > 0 && maskPattern.rawValue[safe: cursorOffset - 1] == " "
    }

    private func getNextChar(_ maskPattern: MaskPattern, cursorOffset: Int) -> Character? {
        maskPattern.rawValue[safe: cursorOffset]
    }

    private func setNewCursorPosition(_ newPositionOffset: NSInteger) {
        if let newPosition = position(from: beginningOfDocument, offset: newPositionOffset) {
            selectedTextRange = textRange(from: newPosition, to: newPosition)
        }
    }

    private func getMaskedText(_ newUnmaskedText: String, maskPattern: MaskPattern) -> String {
        var result = ""
        var insertionIndex = newUnmaskedText.startIndex

        for char in maskPattern.rawValue {
            if insertionIndex >= newUnmaskedText.endIndex {
                break
            }
            if char == "#" {
                result.append(newUnmaskedText[insertionIndex])
                insertionIndex = newUnmaskedText.index(after: insertionIndex)
            } else {
                result.append(char)
            }
        }
        return result
    }

    /// Determines whether to disable validation for specific card numbers used to trigger exceptions.
    ///
    /// - Parameter newUnmaskedText: The unmasked card number to be checked.
    /// - Returns: `true` if validation should be disabled for the given card number, `false` otherwise.
    private func isSpecialCard(_ newUnmaskedText: String) -> Bool {
        // Special error cards that fail at PIN entry for capture
        if newUnmaskedText.hasPrefix("44444444444444") {
            return true
        }

        // Special error cards that fail at PIN entry for balance check
        if newUnmaskedText.hasPrefix("55555555555555") {
            return true
        }

        // Special cards that pass validation checks without causing any errors
        if newUnmaskedText.hasPrefix("9999") {
            return true
        }

        if newUnmaskedText.hasPrefix("654321") {
            return true
        }

        return false
    }
}
