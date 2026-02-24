//
//  Maskable.swift
//  ForageSDK
//
//  Created by Jerimiah on 3/13/25.
//  © 2025 Forage Technology Corporation. All rights reserved.
//

import UIKit

// protocol to facilitate masking the text in a UITextField
protocol Maskable: UITextField {
    /// property to store the unmasked text separate from the masked text
    var actualText: String { get set }
    
    /// Mask numbers with the "#" character. e.g. maskPattern of "##/##" would mask input text like 0825 to "08/25".
    var maskPattern: String { get }
    
    var wasBackspacePressed: Bool { get }
    
    func removeMask(from maskedText: String) -> String
    func getMaskedText(for unmaskedText: String) -> String
    func applyMask(to unmaskedText: String) -> Void
    func isNextCharacterMaskTemplate(offset cursorOffset: NSInteger) -> Bool
    func setNewCursorPosition(_ newPositionOffset: NSInteger)
}

extension Maskable {
    /// default function to reverse the masking of text based on the maskPattern property
    func removeMask(from maskedText: String) -> String {
        var unMaskedText = ""
        var insertionIndex = maskedText.startIndex
        
        for char in maskPattern {
            if insertionIndex >= maskedText.endIndex {
                break
            }
            if char == "#" {
                repeat {
                    if maskedText[insertionIndex].isNumber {
                        unMaskedText.append(maskedText[insertionIndex])
                        insertionIndex = maskedText.index(after: insertionIndex)
                        break
                    }
                    insertionIndex = maskedText.index(after: insertionIndex)
                } while insertionIndex < maskedText.endIndex
            } else if char == maskedText[insertionIndex] {
                insertionIndex = maskedText.index(after: insertionIndex)
            }
        }
        return unMaskedText
    }
    
    /// default function to mask the provided text based on the maskPattern property
    func getMaskedText(for unmaskedText: String) -> String {
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
    
    /// default function to apply the mask to the current displayed text in a UITextField
    func applyMask(to unmaskedText: String) {
        actualText = unmaskedText
        
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
            && isNextCharacterMaskTemplate(offset: cursorOffset) {
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
    
    /// default function to determine if the next character in the UITextField is a maskPattern template field
    func isNextCharacterMaskTemplate(offset cursorOffset: NSInteger) -> Bool {
        cursorOffset > 0 && maskPattern[safe: cursorOffset - 1] != "#"
    }

    /// default function to set the cursor position to a new position
    func setNewCursorPosition(_ newPositionOffset: NSInteger) {
        if let newPosition = position(from: beginningOfDocument, offset: newPositionOffset) {
            selectedTextRange = textRange(from: newPosition, to: newPosition)
        }
    }
}
