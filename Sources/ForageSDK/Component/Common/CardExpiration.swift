//
//  CardExpiration.swift
//  ForageSDK
//
//  Created by Jerimiah on 2/26/25.
//  © 2025 Forage Technology Corporation. All rights reserved.
//

import UIKit

class CardExpiration: FloatingTextField, ObservableState, Maskable, Validatable {
    // MARK: - Properties
    
    /// Maskable properties
    var actualText: String = ""
    private(set) var maskPattern: String = "##/##"
    private(set) var wasBackspacePressed = false
    
    /// Validatable properties
    var invalidError: (any Error)?
    var validators: [(String) throws -> (Bool)] = []

    /// A delegate that informs the client about the state of the entered expiration (validation, focus)
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
        validators = [textLengthValidator, isNotExpiredValidator]
    }
    
    private func textLengthValidator(_ text: String) throws -> Bool {
        if text.count < 5 {
            throw PaymentSheetError.incomplete
        }
        
        return text.count >= 5
    }
    
    private func isNotExpiredValidator(_ dateString: String) throws -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.setLocalizedDateFormatFromTemplate("MM/yy")
        
        let date = Date()
        
        let expDate = dateFormatter.date(from: dateString)
        let currentDateString = dateFormatter.string(from: date)
        let currDate = dateFormatter.date(from: currentDateString)
        
        if let expirationDate = expDate, let currentDate = currDate {
            if currentDate > expirationDate {
                throw PaymentSheetError.invalidDate
            }
            
            return currentDate <= expirationDate
        }
        
        throw PaymentSheetError.invalidDate
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
        
        let maskedText = getMaskedText(for: newUnmaskedText)
        isComplete = validateText(maskedText)
        
        applyMask(to: newUnmaskedText)

        if !text.isEmpty {
            addClearButton(isVisible: true)
        } else {
            addClearButton(isVisible: false)
            becomeFirstResponder()
        }
    }
}
