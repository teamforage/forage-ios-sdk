//
//  BtPINTextField.swift
//  
//
//  Created by Danny Leiser on 7/27/23.
//

import UIKit
import BasisTheoryElements
import Combine

class BasisTheoryTextFieldWrapper: UIView, VaultWrapper {
    /**
     BT Event Types
     */
    private enum BTEventType: String {
        case TEXT_CHANGE = "textChange"
        case MASK_CHANGE = "maskChange"
        case BLUR = "blur"
        case FOCUS = "focus"
    }
    
    private var _isEmpty: Bool = true
    @IBInspectable public var isEmpty: Bool {
        get { return _isEmpty }
    }
    
    private var _isValid: Bool = false
    @IBInspectable public var isValid: Bool {
        get { return _isValid }
    }
    
    private var _isComplete: Bool = false
    @IBInspectable public var isComplete: Bool {
        get { return _isComplete }
    }
    
    func clearText() {
        textField.text = ""
    }
    
    var collector: VaultCollector
    
    var delegate: VaultWrapperDelegate?
    
    var placeholder: String?
    
    var tfTintColor: UIColor?
    
    private var cancellables = Set<AnyCancellable>()
    
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
        
        let pinRegex = try! NSRegularExpression(pattern: "\\d{4}$")
        
        try! textField.setConfig(options: TextElementOptions(mask: pinMask, validation: pinRegex))
        
        textField.subject.sink { completion in
        } receiveValue: { elementEvent in
            if (elementEvent.type == BTEventType.TEXT_CHANGE.rawValue) {
                self._isEmpty = elementEvent.empty
                self._isValid = elementEvent.valid
                self._isComplete = elementEvent.complete
                self.delegate?.textFieldDidChange(self)
            } else if (
                elementEvent.type == BTEventType.FOCUS.rawValue ||
                elementEvent.type == BTEventType.BLUR.rawValue
            ) {
                // Note: This is custom logic to unblock us while BT makes changes on their
                // end. They had the incorrect initial state logic for their input field.
                if (elementEvent.empty) {
                    self._isEmpty = elementEvent.empty
                    self._isValid = false
                    self._isComplete = false
                } else {
                    self._isEmpty = elementEvent.empty
                    self._isValid = elementEvent.valid
                    self._isComplete = elementEvent.complete
                }
                self.delegate?.textFieldDidChange(self)
            }
        }.store(in: &cancellables)
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
