//
//  BtPINTextField.swift
//  
//
//  Created by Danny Leiser on 7/27/23.
//

import UIKit
import BasisTheoryElements

class BasisTheoryTextFieldWrapper: UIView, VaultWrapper {
    
    @IBInspectable public var isEmpty: Bool {
        get { return false }
    }
    
    @IBInspectable public var isValid: Bool {
        get { return false }
    }
    
    @IBInspectable public var isComplete: Bool {
        get { return false }
    }
    
    func clearText() {
        textField.text = ""
    }
    
    var collector: VaultCollector
    
    var delegate: VaultWrapperDelegate?
    
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
        textField.isSecureTextEntry = true
        
        let regexDigit = try! NSRegularExpression(pattern: "\\d")
        
        let pinMask =   [
            regexDigit,
            regexDigit,
            regexDigit,
            regexDigit
        ] as [Any]
        
        let pinRegex = try! NSRegularExpression(pattern: "^\\d{4}$")
        
        try! textField.setConfig(options: TextElementOptions(mask: pinMask, validation: pinRegex))
    }
    
    func setPlaceholderText(_ text: String) {
        textField.placeholder = text
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
    
    var textAlignment: NSTextAlignment {
        get { return textField.textAlignment }
        set { textField.textAlignment = newValue }
    }
}

extension BasisTheoryTextFieldWrapper {
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
