//
//  ForagePINTextField.swift
//  ForageSDK
//
//  Created by Symphony on 23/10/22.
//

import UIKit
import VGSCollectSDK

public class ForagePINTextField: UIView, Identifiable {
    
    // MARK: Public Delegate
    
    /// Delegate that updates client's side about state of the entered pin
    public weak var delegate: ForagePINTextFieldDelegate?
    
    // MARK: Public Properties
    
    public var pinType: PinType = .balance
    
    /// Placeholder for the text field
    @IBInspectable public var placeholder: String? {
        get { return textField.placeholder }
        set { textField.placeholder = newValue }
    }
    
    /// Text color for the text field
    /// `textColor` default value is `black`
    @IBInspectable public var textColor: UIColor? {
        get { return textField.textColor }
        set { textField.textColor = newValue }
    }
    
    /// Size of the text for the text field
    /// `size` default value is `24`
    @IBInspectable public var size: Double = 24.0 {
        didSet { textField.font = UIFont.systemFont(ofSize: size) }
    }
    
    /// Tint color for the text field
    /// `tfTintColor` default value is `black`
    @IBInspectable public var tfTintColor: UIColor? {
        get { return textField.tintColor }
        set { textField.tintColor = newValue }
    }
    
    /// Hide text and disable copy when set `true`
    /// `isSecureTextEntry` default value is `true`
    @IBInspectable public var isSecureTextEntry: Bool = true {
        didSet { textField.isSecureTextEntry = isSecureTextEntry }
    }
    
    /// Text alignment
    /// `textAlignment` default value is `natural`
    @IBInspectable public var textAlignment: NSTextAlignment = .natural {
        didSet { textField.textAlignment = textAlignment }
    }
    
    /// Change UIFont
    /// `VGSTextField` text font
    @IBInspectable public var font: UIFont? {
        get { return textField.font }
        set { textField.font = newValue }
    }
    
    // MARK: Private components
    
    private lazy var container: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var textField: VGSTextField = {
        let tf = VGSTextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.textColor = UIColor.black
        tf.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        tf.autocorrectionType = .no
        tf.borderWidth = 0.25
        tf.borderColor = UIColor.lightGray
        tf.padding = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
        return tf
    }()
    
    // MARK: Lifecycle methods
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    override public func awakeFromNib() {
        super.awakeFromNib()
    }
    
    // MARK: Private Methods
    
    private func commonInit() {
        guard let collector = ForageSDK.shared.collector else { return }
        addSubview(container)
        
        container.addSubview(textField)
        
        textField.delegate = self
        
        let configuration = VGSConfiguration(collector: collector, fieldName: "pin")
        configuration.type = .none
        configuration.keyboardType = .numberPad
        configuration.maxInputLength = 4
        textField.configuration = configuration
        
        container.anchor(
            top: self.topAnchor,
            leading: self.leadingAnchor,
            bottom: self.bottomAnchor,
            trailing: self.trailingAnchor,
            centerXAnchor: nil,
            padding: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        )
        
        textField.anchor(
            top: self.topAnchor,
            leading: self.leadingAnchor,
            bottom: self.bottomAnchor,
            trailing: self.trailingAnchor,
            centerXAnchor: nil,
            padding: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        )
        
        let tapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(requestFocus(_:))
        )
        addGestureRecognizer(tapGesture)
    }
    
    @objc fileprivate func requestFocus(_ gesture: UIGestureRecognizer) {
        becomeFirstResponder()
    }
}

extension ForagePINTextField: VGSTextFieldDelegate {
    /// Check active vgs textfield's state when editing the field
    public func vgsTextFieldDidChange(_ textField: VGSTextField) {
        let isValid = textField.state.inputLength == 4
        delegate?.pinStatus(self, isValid: isValid, pinType: pinType)
    }
}

// MARK: - UIResponder methods

extension ForagePINTextField {
    
    /// Make `ForagePINTextField` focused.
    @discardableResult override public func becomeFirstResponder() -> Bool {
        return textField.becomeFirstResponder()
    }
    
    /// Remove  focus from `ForagePINTextField`.
    @discardableResult override public func resignFirstResponder() -> Bool {
        return textField.resignFirstResponder()
    }
    
    /// Check if `ForagePINTextField` is focused.
    override public var isFirstResponder: Bool {
        return textField.isFirstResponder
    }
}
