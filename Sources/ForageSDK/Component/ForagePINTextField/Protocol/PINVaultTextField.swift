//
//  File.swift
//  
//
//  Created by Shardendu Gautam on 6/6/23.
//

import UIKit
import VGSCollectSDK
import BasisTheoryElements

public protocol PINVaultTextField: UIView {
    var placeholder: String? { get set }
    var collector: VaultCollector { get set }
    var textColor: UIColor? { get set }
    var tfTintColor: UIColor? { get set }
    var isSecureTextEntry: Bool { get set }
    var textAlignment: NSTextAlignment { get set }
    var font: UIFont? { get set }
    var borderWidth: CGFloat { get set }
    var borderColor: UIColor? { get set }
    var padding: UIEdgeInsets { get set }
    var autocorrectionType: UITextAutocorrectionType { get set }
    func configure(_ collector: VGSCollect, rules: VGSValidationRuleSet)
    var delegate: PINVaultTextFieldDelegate? { get set }
    func isValid() -> Bool
    func setTranslatesAutoresizingMaskIntoConstraints(_ flag: Bool)
    func setAccessibilityIdentifier(_ identifier: String)
    func setIsAccessibilityElement(_ flag: Bool)
    func setPlaceholderText(_ text: String)
}

class VGSTextFieldWrapper: UIView, PINVaultTextField{
    var collector: VaultCollector
    
    weak var delegate: PINVaultTextFieldDelegate?
    
    var placeholder: String?
    
    var tfTintColor: UIColor?
    
    private let textField: VGSTextField
    
    override init(frame: CGRect) {
        textField = VGSTextField()
        collector = CollectorFactory.createVGS(environment: ForageSDK.shared.environment)
        super.init(frame: frame)
        
        commonInit()
    }
    
    override func didChangeValue(forKey key: String) {
            if key == "text" {
                delegate?.textFieldDidChange(self)
            }
        }
    
    required init?(coder aDecoder: NSCoder) {
        textField = VGSTextField()
        collector = CollectorFactory.createVGS(environment: ForageSDK.shared.environment)
        super.init(coder: aDecoder)
        
        commonInit()
    }
    
    private func commonInit() {
        addSubview(textField)
    }
    
    func isValid() -> Bool {
        return textField.state.inputLength == 4
    }
    
    func configure(_ collector: VGSCollectSDK.VGSCollect, rules: VGSCollectSDK.VGSValidationRuleSet) {
        let configuration = VGSConfiguration(collector: collector, fieldName: "pin")
        configuration.type = .none
        configuration.keyboardType = .numberPad
        configuration.maxInputLength = 4
        configuration.validationRules = rules
        textField.configuration = configuration
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

class BasisTheoryTextFieldWrapper: UIView, PINVaultTextField{
    var collector: VaultCollector
    
    weak var delegate: PINVaultTextFieldDelegate?
    
    func isValid() -> Bool {
        return textField.text?.count == 4
    }
    
    override func didChangeValue(forKey key: String) {
            if key == "text" {
                delegate?.textFieldDidChange(self)
            }
        }
    
    
    var placeholder: String?
    
    var tfTintColor: UIColor?
    
    var verticalConstraint: [NSLayoutConstraint]?
    var horizontalConstraints: [NSLayoutConstraint]?
    
    private let textField: TextElementUITextField
    
    
    override init(frame: CGRect) {
        textField = TextElementUITextField()
        collector = CollectorFactory.createBasisTheory(environment: ForageSDK.shared.environment)
        super.init(frame: frame)
        
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        textField = TextElementUITextField()
        collector = CollectorFactory.createBasisTheory(environment: ForageSDK.shared.environment)
        super.init(coder: aDecoder)
        
        commonInit()
    }
    
    private func commonInit() {
        addSubview(textField)
    }
    
    func configure(_ collector: VGSCollectSDK.VGSCollect, rules: VGSCollectSDK.VGSValidationRuleSet) {
        
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
            return textField.layer.borderWidth
        }
        set {
            textField.layer.borderWidth = newValue
        }
    }
    
    var padding = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0) {
            didSet { setMainPaddings() }
        }
    
    var borderColor: UIColor? {
        get {
            guard let cgcolor = textField.layer.borderColor else {
                return nil
            }
            return UIColor(cgColor: cgcolor)
        }
        set {
            textField.layer.borderColor = newValue?.cgColor
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
    
    func setMainPaddings() {
        if let verticalConstraint = verticalConstraint {
            NSLayoutConstraint.deactivate(verticalConstraint)
        }
        
        if let horizontalConstraints = horizontalConstraints {
            NSLayoutConstraint.deactivate(horizontalConstraints)
        }
        
        let views = ["view": self, "textField": textField]
        
        horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-\(padding.left)-[textField]-\(padding.right)-|",
                                                               options: .alignAllCenterY,
                                                               metrics: nil,
                                                               views: views)
        NSLayoutConstraint.activate(horizontalConstraints ?? [])
        
        verticalConstraint = NSLayoutConstraint.constraints(withVisualFormat: "V:|-\(padding.top)-[textField]-\(padding.bottom)-|",
                                                                options: .alignAllCenterX,
                                                                metrics: nil,
                                                                views: views)
        NSLayoutConstraint.activate(verticalConstraint ?? [])
        
        self.layoutIfNeeded()
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


