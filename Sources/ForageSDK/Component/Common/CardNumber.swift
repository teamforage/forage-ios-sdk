//
//  CardNumber.swift
//  ForageSDK
//
//  Created by Jerimiah on 3/6/25.
//  © 2025 Forage Technology Corporation. All rights reserved.
//

import UIKit

class CardNumber: FloatingTextField, ObservableState, Maskable, Validatable {
    // MARK: - Properties
    
    /// Maskable Properties
    var actualText: String = ""
    private(set) var maskPattern: String = "#### #### #### ####"
    private(set) var wasBackspacePressed = false
    
    /// Validatable properties
    public internal(set) var invalidError: (any Error)?
    public private(set) var validators: [(String) throws -> (Bool)] = []

    /// A delegate that informs the client about the state (validation, focus)
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
        validators = [textLengthValidator, luhnsCheckValidator]
    }
    
    private func textLengthValidator(_ text: String) throws -> Bool {
        if text.count < 16 {
            throw PaymentSheetError.incomplete
        }
        return true
    }
    
    private func luhnsCheckValidator(_ cardNumber: String) throws -> Bool {
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

        if !((sumEven + sumOdd) % 10 == 0) {
            throw PaymentSheetError.invalidCardNumber
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
