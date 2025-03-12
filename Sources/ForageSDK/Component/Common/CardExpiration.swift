//
//  CardExpiration.swift
//  ForageSDK
//
//  Created by Jerimiah on 2/26/25.
//  Copyright © 2025-Present Forage Technology Corporation. All rights reserved.
//

import UIKit

class CardExpiration: FloatingTextField, ObservableState {
    // MARK: - Properties
    
    var actualText: String = ""
    private var maskPattern: String = "##/##"

    private var wasBackspacePressed = false

    /// A delegate that informs the client about the state of the entered expiration (validation, focus)
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
        return maskedText.replacingOccurrences(of: "/", with: "")
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
            && isNextCharacterSlash(offset: cursorOffset) {
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
    
    private func isExpired(_ dateString: String) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.setLocalizedDateFormatFromTemplate("MM/yy")
        
        let date = Date()
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: date)
        let currentMonth = calendar.component(.month, from: date)

        let expDate = dateFormatter.date(from: dateString)
        let currDate = dateFormatter.date(from: String(currentMonth) + "/" + String(currentYear))
        
        if let expirationDate = expDate, let currentDate = currDate {
            return expirationDate < currentDate
        }
        
        return true
    }
    
    /// checks validation of text
    private func validateText(_ text: String) {
        defer {
            isEmpty = text.isEmpty
            forageDelegate?.textFieldDidChange(self)
        }
        
        if text.count < 5 {
            isValid = false
            isComplete = false
            return
        }
        
        if !isExpired(text) {
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
        newUnmaskedText = String(newUnmaskedText.prefix(4))
        
        actualText = newUnmaskedText
        
        let maskedText = getMaskedText(for: newUnmaskedText)
        validateText(maskedText)
        
        applyMask(to: newUnmaskedText)

        if !text.isEmpty {
            addClearButton(isVisible: true)
        } else {
            addClearButton(isVisible: false)
            becomeFirstResponder()
        }
    }

    private func isNextCharacterSlash(offset cursorOffset: NSInteger) -> Bool {
        cursorOffset > 0 && maskPattern[safe: cursorOffset - 1] == "/"
    }

    private func setNewCursorPosition(_ newPositionOffset: NSInteger) {
        if let newPosition = position(from: beginningOfDocument, offset: newPositionOffset) {
            selectedTextRange = textRange(from: newPosition, to: newPosition)
        }
    }
}
