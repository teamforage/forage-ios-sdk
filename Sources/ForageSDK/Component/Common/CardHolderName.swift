//
//  CardHolderName.swift
//  ForageSDK
//
//  Created by Jerimiah on 3/6/25.
//  © 2025 Forage Technology Corporation. All rights reserved.
//

import UIKit

class CardHolderName: FloatingTextField, ObservableState, Validatable {
    var invalidError: (any Error)?
    
    var validators: [(String) throws -> (Bool)] = [{
        if $0.isEmpty {
            throw PaymentSheetError.incomplete
        }
        return true
    }]
    
    // MARK: - Properties

    private var wasBackspacePressed = false

    /// A delegate that informs the client about the state of the entered card-holder name (validation, focus)
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
        defer {
            wasBackspacePressed = false
            forageDelegate?.textFieldDidChange(self)
        }

        guard let text = text else { return }
        
        isComplete = validateText(text)
        isEmpty = text.isEmpty

        if !text.isEmpty {
            addClearButton(isVisible: true)
        } else {
            addClearButton(isVisible: false)
            becomeFirstResponder()
        }
    }
}
