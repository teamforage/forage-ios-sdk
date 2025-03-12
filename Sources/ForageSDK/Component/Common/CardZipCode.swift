//
//  CardZipCode.swift
//  ForageSDK
//
//  Created by Jerimiah on 2/26/25.
//  Copyright © 2025-Present Forage Technology Corporation. All rights reserved.
//

import UIKit

class CardZipCode: FloatingTextField, ObservableState {
    // MARK: - Properties

    private var wasBackspacePressed = false

    /// A delegate that informs the client about the state of the entered zip code (validation, focus)
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

    private func setup() {
        autocorrectionType = .no
        addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }
    
    // MARK: Methods
    
    /// checks validation of text
    private func validateText(_ text: String) {
        defer {
            isEmpty = text.isEmpty
            forageDelegate?.textFieldDidChange(self)
        }
        
        isValid = text.count >= 5
        isComplete = text.count >= 5
    }

    // MARK: - Text Field Actions

    override func deleteBackward() {
        wasBackspacePressed = true
        super.deleteBackward()
    }

    @objc func textFieldDidChange() {
        defer { wasBackspacePressed = false }

        guard var newText = text else { return }
        
        newText = String(newText.prefix(5))
        
        validateText(newText)
        
        text = newText

        if !newText.isEmpty {
            addClearButton(isVisible: true)
        } else {
            addClearButton(isVisible: false)
            becomeFirstResponder()
        }
    }
}
