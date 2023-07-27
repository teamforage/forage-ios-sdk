//
//  File.swift
//  
//
//  Created by Danny Leiser on 7/27/23.
//

import UIKit
import VGSCollectSDK

class VGSTextFieldWrapper: UIView, PINVaultTextField, VGSTextFieldDelegate{
    func cleanText() {
        textField.cleanText()
    }
    
    var collector: VaultCollector
    
    var delegate: PINVaultTextFieldDelegate?
    
    var placeholder: String?
    
    var tfTintColor: UIColor?
    
    private let textField: VGSTextField
    
    override init(frame: CGRect) {
        textField = VGSTextField()
        collector = CollectorFactory.createVGS(environment: ForageSDK.shared.environment)
        super.init(frame: frame)
        
        commonInit()
    }
    
    func vgsTextFieldDidChange(_ textField: VGSTextField) {
        delegate?.textFieldDidChange(self)
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

        textField.anchor(
            top: self.topAnchor,
            leading: self.leadingAnchor,
            bottom: self.bottomAnchor,
            trailing: self.trailingAnchor,
            centerXAnchor: nil,
            padding: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        )
        
        textField.delegate = self
    }
    
    func isValid() -> Bool {
        return textField.state.inputLength == 4
    }
    
    func setPlaceholderText(_ text: String) {
        textField.placeholder = text
    }
    
    
    func setTranslatesAutoresizingMaskIntoConstraints(_ flag: Bool) {
        textField.translatesAutoresizingMaskIntoConstraints = flag
    }
    
    var autocorrectionType: UITextAutocorrectionType {
        get {
            return textField.autocorrectionType
        }
        set {
            textField.autocorrectionType = newValue
        }
    }
    
    var borderWidth: CGFloat {
        get {
            return textField.borderWidth
        }
        set {
            textField.borderWidth = newValue
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
    
    
    func setAccessibilityIdentifier(_ identifier: String) {
        textField.accessibilityIdentifier = identifier
    }
    
    func setIsAccessibilityElement(_ flag: Bool) {
        textField.isAccessibilityElement = flag
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
    
    var isSecureTextEntry: Bool {
        get { return textField.isSecureTextEntry }
        set { textField.isSecureTextEntry = newValue }
    }
    
    var textAlignment: NSTextAlignment {
        get { return textField.textAlignment }
        set { textField.textAlignment = newValue }
    }
}
