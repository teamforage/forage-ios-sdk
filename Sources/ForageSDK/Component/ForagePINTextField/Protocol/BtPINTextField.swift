//
//  File.swift
//  
//
//  Created by Danny Leiser on 7/27/23.
//

import UIKit
import BasisTheoryElements

class BasisTheoryTextFieldWrapper: UIView, UITextFieldDelegate, PINVaultTextField{
    func cleanText() {
        textField.text = ""
    }
    
    var collector: VaultCollector
    
    weak var delegate: PINVaultTextFieldDelegate?
    
    func isValid() -> Bool {
        return textField.metadata.valid
    }
    
    @objc func btTextFieldDidChange(_ textField: UITextField) {
        delegate?.textFieldDidChange(self)
    }
    
    var placeholder: String?
    
    var tfTintColor: UIColor?
    
    var verticalConstraint: [NSLayoutConstraint]?
    var horizontalConstraints: [NSLayoutConstraint]?
    
    private let textField: TextElementUITextField
    
    
    override init(frame: CGRect) {
        textField = TextElementUITextField()
        collector = CollectorFactory.createBasisTheory(environment: ForageSDK.shared.environment, textElement: textField)
        
        super.init(frame: frame)
        
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        textField = TextElementUITextField()
        collector = CollectorFactory.createBasisTheory(environment: ForageSDK.shared.environment, textElement: textField)
        super.init(coder: aDecoder)
        
        commonInit()
    }
    
    private func commonInit() {
        addSubview(textField)
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.keyboardType = UIKeyboardType.phonePad
        
        let regexDigit = try! NSRegularExpression(pattern: "\\d")
        
        let pinMask =   [
            regexDigit,
            regexDigit,
            regexDigit,
            regexDigit
        ] as [Any]
        
        let pinRegex = try! NSRegularExpression(pattern: "^\\d{4}$")
        
        try! textField.setConfig(options: TextElementOptions(mask: pinMask, validation: pinRegex))
        
        textField.addTarget(self, action: #selector(btTextFieldDidChange(_:)), for: .editingChanged)
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
