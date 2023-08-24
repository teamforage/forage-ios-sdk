//
//  VgsPINTextField.swift
//  
//
//  Created by Danny Leiser on 7/27/23.
//

import UIKit
import VGSCollectSDK

class VGSTextFieldWrapper: UIView, VaultWrapper {
    
    @IBInspectable public var isEmpty: Bool {
        get { return textField.state.isEmpty }
    }
    
    @IBInspectable public var isValid: Bool {
        get { return textField.state.inputLength == 4 }
    }
    
    @IBInspectable public var isComplete: Bool {
        get { return textField.state.inputLength == 4 }
    }
    
    func clearText() {
        textField.cleanText()
    }
    
    var collector: VaultCollector
    
    var delegate: VaultWrapperDelegate?
    
    var placeholder: String?
    
    var tfTintColor: UIColor?
    
    private let textField: VGSTextField
    
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
        configuration.keyboardType = .numberPad
        configuration.maxInputLength = 4
        configuration.validationRules = rules
        textField.configuration = configuration
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.textAlignment = .center

        textField.anchor(
            top: self.topAnchor,
            leading: self.leadingAnchor,
            bottom: self.bottomAnchor,
            trailing: self.trailingAnchor,
            centerXAnchor: nil,
            padding: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        )
        textField.isSecureTextEntry = true
        
        textField.delegate = self
    }
    
    func setPlaceholderText(_ text: String) {
        textField.placeholder = text
    }
    
    var borderWidth: CGFloat {
        get {
            return textField.borderWidth
        }
        set {
            textField.borderWidth = newValue
        }
    }
    
    var borderRadius: CGFloat {
        get {
            return textField.cornerRadius
        }
        set {
            textField.cornerRadius = newValue
        }
    }
    
    var padding: UIEdgeInsets {
        get {
            return textField.padding
        }
        set {
            textField.padding = newValue
        }
    }
    
    var borderColor: UIColor? {
        get {
            return textField.borderColor
        }
        set {
            textField.borderColor = newValue
        }
    }
    
    override var backgroundColor: UIColor? {
        get {
            return textField.backgroundColor
        }
        set {
            textField.backgroundColor = newValue
        }
    }
    
    func setPlaceholder(_ text: String) {
        textField.placeholder = text
    }

    var textColor: UIColor? {
        get { return textField.textColor }
        set { textField.textColor = newValue }
    }
    
    var font: UIFont? {
        get { return textField.font }
        set { textField.font = newValue }
    }
    
    var textAlignment: NSTextAlignment {
        get { return textField.textAlignment }
        set { textField.textAlignment = newValue }
    }
}

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

extension VGSTextFieldWrapper {
    /// Make `ForagePINTextField` focused.
    @discardableResult override public func becomeFirstResponder() -> Bool {
        return textField.becomeFirstResponder()
    }

    /// Remove focus from `ForagePINTextField`.
    @discardableResult public override func resignFirstResponder() -> Bool {
        return textField.resignFirstResponder()
    }

    /// Check if `ForagePINTextField` is focused.
    override public var isFirstResponder: Bool {
        return textField.isFirstResponder
    }
}
