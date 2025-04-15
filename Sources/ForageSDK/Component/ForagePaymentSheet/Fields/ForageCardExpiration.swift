//
//  ForageCardExpiration.swift
//  ForageSDK
//
//  Created by Jerimiah on 3/6/25.
//  © 2025 Forage Technology Corporation. All rights reserved.
//

import UIKit

public class ForageCardExpiration: UIView, Identifiable, ForagePaymentSheetField, ForageElementDelegate {
    // MARK: - Properties
    public var name: String = "cardExpirationTextField"
    
    public private(set) var isDirty: Bool = false
    
    public private(set) var isTouched: Bool = false
    
    public var invalidError: (any Error)? {
        get { enhancedTextField.invalidError }
    }
    
    @IBInspectable public var isEmpty: Bool {
        enhancedTextField.isEmpty
    }
    
    @IBInspectable public var isValid: Bool {
        enhancedTextField.isValid
    }

    @IBInspectable public var isComplete: Bool {
        get { enhancedTextField.isComplete }
    }

    /// BorderWidth for the text field
    @IBInspectable public var borderWidth: CGFloat {
        get { enhancedTextField.borderWidth }
        set { enhancedTextField.borderWidth = newValue }
    }

    /// BorderColor for the text field
    @IBInspectable public var borderColor: UIColor? {
        get { enhancedTextField.borderColor }
        set { enhancedTextField.borderColor = newValue ?? .black }
    }

    /// CornerRadius for the text field
    @IBInspectable public var cornerRadius: CGFloat = 4 {
        didSet { enhancedTextField.layer.cornerRadius = cornerRadius }
    }

    /// MasksToBounds for the text field
    @IBInspectable public var masksToBounds: Bool {
        get { enhancedTextField.layer.masksToBounds }
        set { enhancedTextField.layer.masksToBounds = newValue }
    }

    /// Padding for the text field
    private var _padding: UIEdgeInsets = .init(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
    @IBInspectable public var padding: UIEdgeInsets {
        get { _padding }
        set { _padding = newValue }
    }

    /// Placeholder for the text field
    @IBInspectable public var placeholder: String? {
        get { enhancedTextField.placeholder }
        set { enhancedTextField.placeholder = "\(newValue ?? "")*"}
    }

    /// Text color for the text field
    /// `textColor` default value is `black`
    @IBInspectable public var textColor: UIColor? {
        get { enhancedTextField.textColor }
        set { enhancedTextField.textColor = newValue }
    }

    /// Size of the text for the text field
    /// `size` default value is `24`
    @IBInspectable public var size: Double = 24.0 {
        didSet { enhancedTextField.font = UIFont.systemFont(ofSize: size) }
    }

    /// Tint color for the text field
    /// `tfTintColor` default value is `black`
    @IBInspectable public var tfTintColor: UIColor? {
        get { enhancedTextField.tintColor }
        set { enhancedTextField.tintColor = newValue }
    }

    /// Text alignment
    /// `textAlignment` default value is `natural`
    @IBInspectable public var textAlignment: NSTextAlignment = .natural {
        didSet { enhancedTextField.textAlignment = textAlignment }
    }

    /// Allow user to clear text field
    /// `clearButtonMode` default value is `never`
    @IBInspectable public var clearButtonMode: UITextField.ViewMode = .never {
        didSet { enhancedTextField.clearButtonMode = clearButtonMode }
    }

    /// Change UIFont
    /// `UITextField` text font
    @IBInspectable public var font: UIFont? {
        get { enhancedTextField.font }
        set { enhancedTextField.font = newValue }
    }

    // MARK: - Public Delegate

    /// A delegate that informs the client about the state (validation, focus).
    public weak var delegate: ForageElementDelegate?

    // MARK: - Private components

    private lazy var root: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var textFieldContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var container: UIStackView = {
        let sv = UIStackView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis = .vertical
        sv.alignment = .fill
        sv.distribution = .fill
        sv.spacing = 8
        return sv
    }()

    private lazy var logger: ForageLogger = {
        let ddLogger = DatadogLogger(
            ForageLoggerConfig(
                prefix: "UIView"
            )
        )
        return ddLogger
    }()

    /// UITextField with masking and floating placeholder label functionality.
    lazy var enhancedTextField: CardExpiration = {
        let tf = CardExpiration()
        
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.textColor = UIColor.black
        tf.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        tf.heightAnchor.constraint(greaterThanOrEqualToConstant: 37).isActive = true
        tf.borderStyle = .roundedRect
        tf.autocorrectionType = .no
        tf.keyboardType = .numberPad
        tf.accessibilityIdentifier = "tf_forage_card_expiration_text_field"
        tf.isAccessibilityElement = true
        tf.borderWidth = 0.1
        tf.borderColor = .black
        tf.layer.cornerRadius = 4
        return tf
    }()

    // MARK: - Lifecycle methods

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    // MARK: - Private API

    private func commonInit() {
        addSubview(root)

        root.addSubview(container)

        textFieldContainer.addSubview(enhancedTextField)
        container.addArrangedSubview(textFieldContainer)

        enhancedTextField.forageDelegate = self

        root.anchor(
            top: topAnchor,
            leading: leadingAnchor,
            bottom: bottomAnchor,
            trailing: trailingAnchor,
            centerXAnchor: nil,
            padding: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        )

        container.anchor(
            top: root.topAnchor,
            leading: root.leadingAnchor,
            bottom: root.bottomAnchor,
            trailing: root.trailingAnchor,
            centerXAnchor: nil,
            padding: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        )

        enhancedTextField.anchor(
            top: textFieldContainer.topAnchor,
            leading: textFieldContainer.leadingAnchor,
            bottom: textFieldContainer.bottomAnchor,
            trailing: textFieldContainer.trailingAnchor,
            centerXAnchor: nil,
            padding: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        )

        let tapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(requestFocus(_:))
        )
        addGestureRecognizer(tapGesture)
        logger.notice("ForageCardHolderName was initialized successfully", attributes: nil)
    }

    @objc fileprivate func requestFocus(_ gesture: UIGestureRecognizer) {
        becomeFirstResponder()
    }

    // MARK: - Public API

    override public var intrinsicContentSize: CGSize {
        CGSize(width: frame.width, height: 83)
    }

    public func clearText() {
        enhancedTextField.text = ""
    }
}

// MARK: - UIResponder methods

extension ForageCardExpiration {
    /// Make `ForageCardExpiration` focused.
    @discardableResult override public func becomeFirstResponder() -> Bool {
        enhancedTextField.becomeFirstResponder()
    }

    /// Remove  focus from `ForageCardExpiration`.
    @discardableResult override public func resignFirstResponder() -> Bool {
        isTouched = true
        return enhancedTextField.resignFirstResponder()
    }

    /// Check if `ForageCardExpiration` is focused.
    override public var isFirstResponder: Bool {
        enhancedTextField.isFirstResponder
    }
}

extension ForageCardExpiration: UITextFieldDelegate {
    public func focusDidChange(_ state: ObservableState) {
        delegate?.focusDidChange(self)
    }

    public func textFieldDidChange(_ state: ObservableState) {
        isDirty = true
        delegate?.textFieldDidChange(self)
    }

    public func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate?.focusDidChange(self)
    }

    public func textFieldDidEndEditing(_ textField: UITextField) {
        delegate?.focusDidChange(self)
    }
    
    /// Determines whether the text field should allow a change of characters within the specified range.
    /// This method is called when the user attempts to change the content of the text field.
    /// - Parameters:
    ///   - textField: The text field containing the text.
    ///   - range: The range of characters to be replaced.
    ///   - replacementString: The replacement string.
    /// - Returns: `true` if the changes should be allowed; otherwise, `false`.
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString: String) -> Bool {
        let isBackspace = replacementString.isEmpty
        if isBackspace {
            return true
        }

        // Only allow the user to enter numeric strings
        if !replacementString.allSatisfy(\.isNumber) {
            return false
        }

        return true
    }
}
