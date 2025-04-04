//
//  RosettaPINTextField.swift
//
//
//  Created by Evan Freeze on 6/6/24.
//  Copyright © 2024-Present Forage Technology Corporation. All rights reserved.
//

import Combine
import UIKit

class RosettaPINTextField: UIView, VaultWrapper, UITextFieldDelegate {
    // MARK: - Properties

    private var _isEmpty = true
    @IBInspectable public var isEmpty: Bool { _isEmpty }

    private var _isValid = false
    @IBInspectable public var isValid: Bool { _isValid }

    private var _isComplete = false
    @IBInspectable public var isComplete: Bool { _isComplete }

    private let textField: UITextField
    private var inputWidthConstraint: NSLayoutConstraint?
    private var inputHeightConstraint: NSLayoutConstraint?

    var delegate: VaultWrapperDelegate?
    var collector: VaultCollector
    var placeholder: String?
    var tfTintColor: UIColor?
    var padding = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

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
        textField = UITextField()
        collector = CollectorFactory.createRosettaPINSubmitter(environment: ForageSDK.shared.environment, textElement: textField)
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        textField = UITextField()
        collector = CollectorFactory.createRosettaPINSubmitter(environment: ForageSDK.shared.environment, textElement: textField)
        super.init(coder: aDecoder)
        commonInit()
    }

    // MARK: - UITextFieldDelegate protocol methods

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentValue = textField.text ?? ""
        guard let valueRange = Range(range, in: currentValue) else { return false }
        let newValue = currentValue.replacingCharacters(in: valueRange, with: string)
        let isOnlyNumeric = newValue.allSatisfy(\.isNumber)
        let isFourOrFewer = newValue.count <= 4
        return isOnlyNumeric && isFourOrFewer
    }

    // MARK: - Private API

    private func commonInit() {
        addSubview(textField)
        textField.delegate = self
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.keyboardType = UIKeyboardType.numberPad
        textField.isSecureTextEntry = true
        textField.textAlignment = .center
        textField.anchor(
            top: topAnchor,
            leading: leadingAnchor,
            bottom: bottomAnchor,
            trailing: trailingAnchor,
            centerXAnchor: nil,
            padding: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        )
        inputWidthConstraint = textField.widthAnchor.constraint(greaterThanOrEqualToConstant: 342)
        inputWidthConstraint?.isActive = true
        inputHeightConstraint = textField.heightAnchor.constraint(greaterThanOrEqualToConstant: 36)
        inputHeightConstraint?.isActive = true
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        textField.addTarget(self, action: #selector(editingBegan), for: .editingDidBegin)
        textField.addTarget(self, action: #selector(editingEnded), for: .editingDidEnd)
    }

    @objc func textFieldDidChange(_ textField: UITextField) {
        _isEmpty = !textField.hasText
        _isValid = textField.text?.count == 4 && (textField.text?.allSatisfy(\.isNumber) ?? false)
        _isComplete = _isValid
        delegate?.textFieldDidChange(self)
    }

    @objc func editingBegan(_ textField: UITextField) {
        delegate?.firstResponderDidChange(self)
    }

    @objc func editingEnded(_ textField: UITextField) {
        delegate?.firstResponderDidChange(self)
    }

    func clearText() {
        DispatchQueue.main.async {
            self.textField.text = ""
        }
    }

    var borderWidth: CGFloat {
        get { textField.layer.borderWidth }
        set { textField.layer.borderWidth = newValue }
    }

    var cornerRadius: CGFloat {
        get { textField.layer.cornerRadius }
        set { textField.layer.cornerRadius = newValue }
    }

    var masksToBounds: Bool {
        get { textField.layer.masksToBounds }
        set { textField.layer.masksToBounds = newValue }
    }

    var borderColor: UIColor? {
        get {
            guard let cgColor = textField.layer.borderColor else { return nil }
            return UIColor(cgColor: cgColor)
        }
        set { textField.layer.borderColor = newValue?.cgColor }
    }

    override var backgroundColor: UIColor? {
        get {
            guard let cgColor = textField.layer.backgroundColor else { return nil }
            return UIColor(cgColor: cgColor)
        }
        set { textField.layer.backgroundColor = newValue?.cgColor }
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

// MARK: - UIResponder methods

extension RosettaPINTextField {
    @discardableResult override public func becomeFirstResponder() -> Bool {
        textField.becomeFirstResponder()
    }

    @discardableResult override public func resignFirstResponder() -> Bool {
        textField.resignFirstResponder()
    }

    override public var isFirstResponder: Bool {
        textField.isFirstResponder
    }
}
