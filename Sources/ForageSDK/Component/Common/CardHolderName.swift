//
//  CardHolderName.swift
//  ForageSDK
//
//  Created by Jerimiah on 3/6/25.
//  Copyright © 2025-Present Forage Technology Corporation. All rights reserved.
//

import UIKit

class CardHolderName: FloatingTextField, ObservableState {
    // MARK: - Properties

    private var wasBackspacePressed = false

    /// A delegate that informs the client about the state of the entered card-holder name (validation, focus)
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

    // MARK: - Text Field Actions

    override func deleteBackward() {
        wasBackspacePressed = true
        super.deleteBackward()
    }

    @objc func textFieldDidChange() {
        defer { wasBackspacePressed = false }
        defer { forageDelegate?.textFieldDidChange(self) }

        guard let text = text else { return }
        
        self.isComplete = !text.isEmpty
        self.isEmpty = text.isEmpty

        if !text.isEmpty {
            addClearButton(isVisible: true)
        } else {
            addClearButton(isVisible: false)
            becomeFirstResponder()
        }
    }
}
