//
//  CardZipCode.swift
//  ForageSDK
//
//  Created by Jerimiah on 2/26/25.
//  Copyright © 2025-Present Forage Technology Corporation. All rights reserved.
//

import UIKit

class CardZipCode: FloatingTextField, ObservableState, Validatable, Maskable {
    var actualText: String = ""
    
    var maskPattern: String = "#####-####"
    
    // MARK: - Properties
    
    var invalidError: (any Error)?
    
    var validators: [(String) throws -> (Bool)] = []

    internal var wasBackspacePressed = false

    /// A delegate that informs the client about the state of the entered zip code (validation, focus)
    public weak var forageDelegate: ForageElementDelegate? {
        didSet {
            delegate = forageDelegate as? UITextFieldDelegate
        }
    }

    @IBInspectable public private(set) var isEmpty = true
    @IBInspectable public internal(set) var isValid = true
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
        validators = [textLengthValidator]
    }
    
    private func textLengthValidator(_ text: String) throws -> Bool {
        if text.count < 5 {
            throw PaymentSheetError.incomplete
        } else if text.count > 5 && text.count < 9 {
            throw PaymentSheetError.incomplete
        }
        
        return true
    }

    // MARK: - Text Field Actions

    override func deleteBackward() {
        wasBackspacePressed = true
        super.deleteBackward()
    }

    @objc func textFieldDidChange() {
        defer {
            wasBackspacePressed = false
            isEmpty = text?.isEmpty ?? true
            forageDelegate?.textFieldDidChange(self)
        }

        guard let text = text else { return }
        
        let newUnmaskedText = removeMask(from: text)
        
        isComplete = validateText(newUnmaskedText)
        
        applyMask(to: newUnmaskedText)

        if !text.isEmpty {
            addClearButton(isVisible: true)
        } else {
            addClearButton(isVisible: false)
            becomeFirstResponder()
        }
    }
}
