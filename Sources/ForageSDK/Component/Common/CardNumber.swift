//
//  CardNumber.swift
//  ForageSDK
//
//  Created by Jerimiah on 3/6/25.
//  Copyright © 2025-Present Forage Technology Corporation. All rights reserved.
//

import UIKit

class CardNumber: FloatingTextField, ObservableState {
    // MARK: - Properties
    
    var actualText: String = ""
    private var maskPattern: String = "#### #### #### ####"

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

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    // MARK: Methods
    
    private func setup() {
        autocorrectionType = .no
        addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }
    
    private func removeMask(from maskedText: String) -> String {
        return maskedText.replacingOccurrences(of: " ", with: "")
    }
    
    private func getMaskedText(for unmaskedText: String) -> String {
        var maskedText = ""
        var insertionIndex = unmaskedText.startIndex

        for char in maskPattern {
            if insertionIndex >= unmaskedText.endIndex {
                break
            }
            if char == "#" {
                maskedText.append(unmaskedText[insertionIndex])
                insertionIndex = unmaskedText.index(after: insertionIndex)
            } else {
                maskedText.append(char)
            }
        }
        return maskedText
    }
    
    private func applyMask(to unmaskedText: String) {
        // Find the current cursor position
        var cursorOffset = offset(from: beginningOfDocument, to: selectedTextRange!.start)
        let maskedText = getMaskedText(for: unmaskedText)
        let isCursorAtEndOfText = cursorOffset - maskedText.count >= 0

        if wasBackspacePressed && isCursorAtEndOfText {
            text = maskedText
            return
        }

        // Apply the masked text to the text field with a new character, we use " " string as "any" character
        let maskedTextWithNewChar = getMaskedText(for: unmaskedText + " ")
        text = maskedText

        // Calculate the new cursor position
        if !isCursorAtEndOfText
            && !wasBackspacePressed
            && isNextCharacterGap(offset: cursorOffset) {
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
    
    private func luhnsCheck(_ cardNumber: String) -> Bool {
        let reverseCard = cardNumber.reversed().compactMap { Int(String($0)) }
            
            var sumEven = 0
            var sumOdd = 0

            for (index, value) in reverseCard.enumerated() {

                // Sum of even places
                if index % 2 == 0 {
                    sumEven += value
                } else {
                    // Sum of doubled odd places
                    let doubled = value * 2
                    sumOdd += (doubled > 9) ? (doubled - 9) : doubled
                }
            }

            return (sumEven + sumOdd) % 10 == 0
    }
    
    /// checks validation of text
    private func validateText(_ text: String) {
        defer {
            isEmpty = text.isEmpty
            forageDelegate?.textFieldDidChange(self)
        }
        
        // TODO: handle test cards
        if text.count < 16 {
            isValid = false
            isComplete = false
            return
        }
        
        if luhnsCheck(text) {
            isValid = true
            isComplete = true
            return
        }
        
        isValid = false
        isComplete = false
        
    }

    // MARK: - Text Field Actions

    override func deleteBackward() {
        wasBackspacePressed = true
        super.deleteBackward()
    }

    @objc func textFieldDidChange() {
        defer { wasBackspacePressed = false }

        guard let text = text else { return }
        
        var newUnmaskedText = removeMask(from: text)
        newUnmaskedText = String(newUnmaskedText.prefix(16))
        
        validateText(newUnmaskedText)
        
        applyMask(to: newUnmaskedText)
        
        actualText = newUnmaskedText

        if !text.isEmpty {
            addClearButton(isVisible: true)
        } else {
            addClearButton(isVisible: false)
            becomeFirstResponder()
        }
    }

    private func isNextCharacterGap(offset cursorOffset: NSInteger) -> Bool {
        cursorOffset > 0 && maskPattern[safe: cursorOffset - 1] == " "
    }

    private func setNewCursorPosition(_ newPositionOffset: NSInteger) {
        if let newPosition = position(from: beginningOfDocument, offset: newPositionOffset) {
            selectedTextRange = textRange(from: newPosition, to: newPosition)
        }
    }
}
