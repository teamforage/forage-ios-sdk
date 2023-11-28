//
//  VgsPINTextField.swift
//
//
//  Created by Danny Leiser on 7/27/23.
//  Copyright © 2023-Present Forage Technology Corporation. All rights reserved.
//

import UIKit
import VGSCollectSDK

class VGSTextFieldWrapper: UIView, VaultWrapper {
    // MARK: - Properties

    @IBInspectable public var isEmpty: Bool { textField.state.isEmpty }

    @IBInspectable public var isValid: Bool { textField.state.inputLength == 4 }

    @IBInspectable public var isComplete: Bool { textField.state.inputLength == 4 }

    private let textField: VGSTextField
    private var inputWidthConstraint: NSLayoutConstraint?
    private var inputHeightConstraint: NSLayoutConstraint?

    var delegate: VaultWrapperDelegate?
    var collector: VaultCollector
    var placeholder: String?
    var tfTintColor: UIColor?

    var widthConstraint: CGFloat? {
        didSet {
            if let widthConstraint = widthConstraint {
                inputWidthConstraint?.constant = widthConstraint
            }
        }
    }

    var heightConstraint: CGFloat? {
        didSet {
            if let heightConstraint = heightConstraint {
                inputHeightConstraint?.constant = heightConstraint
            }
        }
    }

    // MARK: - Initialization

    override init(frame: CGRect) {
        textField = VGSTextField()
        collector = CollectorFactory.createVGS(environment: ForageSDK.shared.environment)
        super.init(frame: frame)

        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        textField = VGSTextField()
        collector = CollectorFactory.createVGS(environment: ForageSDK.shared.environment)
        super.init(coder: aDecoder)

        commonInit()
    }

    private func commonInit() {
        addSubview(textField)

        var rules = VGSValidationRuleSet()
        rules.add(rule: VGSValidationRulePattern(pattern: "^[0-9]+$", error: VGSValidationErrorType.pattern.rawValue))
        let configuration = VGSConfiguration(collector: (collector as! VGSCollectWrapper).vgsCollect, fieldName: "pin")
        configuration.type = .none
        configuration.keyboardType = .phonePad
        configuration.maxInputLength = 4
        configuration.validationRules = rules
        textField.configuration = configuration
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.textAlignment = .center
        textField.anchor(
            top: topAnchor,
            leading: leadingAnchor,
            bottom: bottomAnchor,
            trailing: trailingAnchor,
            centerXAnchor: nil,
            padding: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        )

        setupWidthHeightConstraints()

        textField.isSecureTextEntry = true
        textField.delegate = self
    }

    // MARK: - Private API

    private func setupWidthHeightConstraints() {
        inputWidthConstraint = textField.widthAnchor.constraint(greaterThanOrEqualToConstant: 342)
        inputWidthConstraint?.isActive = true

        inputHeightConstraint = textField.heightAnchor.constraint(greaterThanOrEqualToConstant: 36)
        inputHeightConstraint?.isActive = true
    }

    // MARK: - Public API

    func clearText() {
        DispatchQueue.main.async {
            self.textField.cleanText()
        }
    }

    var borderWidth: CGFloat {
        get { textField.borderWidth }
        set { textField.borderWidth = newValue }
    }

    var masksToBounds: Bool {
        get { textField.layer.masksToBounds }
        set { textField.layer.masksToBounds = newValue }
    }

    var cornerRadius: CGFloat {
        get { textField.cornerRadius }
        set { textField.cornerRadius = newValue }
    }

    var padding: UIEdgeInsets {
        get { textField.padding }
        set { textField.padding = newValue }
    }

    var borderColor: UIColor? {
        get { textField.borderColor }
        set { textField.borderColor = newValue }
    }

    override var backgroundColor: UIColor? {
        get { textField.backgroundColor }
        set { textField.backgroundColor = newValue }
    }

    var textColor: UIColor? {
        get { textField.textColor }
        set { textField.textColor = newValue }
    }

    var font: UIFont? {
        get { textField.font }
        set { textField.font = newValue }
    }

    var textAlignment: NSTextAlignment {
        get { textField.textAlignment }
        set { textField.textAlignment = newValue }
    }
}

// MARK: - VGSTextFieldDelegate

extension VGSTextFieldWrapper: VGSTextFieldDelegate {
    @objc func vgsTextFieldDidChange(_ textField: VGSTextField) {
        delegate?.textFieldDidChange(self)
    }

    /// This is the VGS event for "field became first responder"
    @objc func vgsTextFieldDidBeginEditing(_ textField: VGSTextField) {
        delegate?.firstResponderDidChange(self)
    }

    /// This is the VGS event for "field resigned first responder"
    @objc func vgsTextFieldDidEndEditing(_ textField: VGSTextField) {
        delegate?.firstResponderDidChange(self)
    }

    /// This is the VGS event for "field resigned first responder" through button press
    @objc func vgsTextFieldDidEndEditingOnReturn(_ textField: VGSTextField) {
        delegate?.firstResponderDidChange(self)
    }
}

// MARK: - UIResponder methods

extension VGSTextFieldWrapper {
    /// Make `ForagePINTextField` focused.
    @discardableResult override public func becomeFirstResponder() -> Bool {
        textField.becomeFirstResponder()
    }

    /// Remove focus from `ForagePINTextField`.
    @discardableResult override public func resignFirstResponder() -> Bool {
        textField.resignFirstResponder()
    }

    /// Check if `ForagePINTextField` is focused.
    override public var isFirstResponder: Bool {
        textField.isFirstResponder
    }
}
