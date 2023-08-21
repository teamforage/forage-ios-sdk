//
//  ForagePANTextField.swift
//  ForageSDK
//
//  Created by Symphony on 16/10/22.
//

import UIKit
import VGSCollectSDK

public enum CardType: String {
    case EBT = "ebt"
}

public class ForagePANTextField: UIView, Identifiable, ForageElement, ForageElementDelegate {
    public func setPlaceholderText(_ text: String) {
        
    }
    
    public func clearText() {
        ForageSDK.shared.panNumber = ""
    }
    
    /// BorderWidth for the text field
    private var _borderWidth: CGFloat = 0.1
    @IBInspectable public var borderWidth: CGFloat {
        get { return _borderWidth }
        set { _borderWidth = newValue }
    }
    
    /// BorderColor for the text field
    private var _borderColor: UIColor? = .black
    @IBInspectable public var borderColor: UIColor? {
        get { return _borderColor }
        set { _borderColor = newValue }
    }
    
    /// Padding for the text field
    private var _padding: UIEdgeInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
    @IBInspectable public var padding: UIEdgeInsets {
        get { return _padding }
        set { _padding = newValue }
    }
    
    @IBInspectable public var isEmpty: Bool {
        textField.isEmpty
    }

    @IBInspectable public var isValid: Bool {
        textField.isValid
    }

    @IBInspectable public var isComplete: Bool {
        textField.isComplete
    }
    
    // MARK: Public Delegate
    
    /// A delegate that informs the client about the state of the entered card number (validation, focus).
    public weak var delegate: ForageElementDelegate?
    
    // MARK: Public Properties
    
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
    
    /// Text alignment
    /// `textAlignment` default value is `natural`
    @IBInspectable public var textAlignment: NSTextAlignment = .natural {
        didSet { textField.textAlignment = textAlignment }
    }
    
    /// Allow user to clear text field
    /// `clearButtonMode` default value is `never`
    @IBInspectable public var clearButtonMode: UITextField.ViewMode = .never {
        didSet { textField.clearButtonMode = clearButtonMode }
    }
    
    /// Change UIFont
    /// `UITextField` text font
    @IBInspectable public var font: UIFont? {
        get { return textField.font }
        set { textField.font = newValue }
    }
    
    override public var intrinsicContentSize: CGSize {
        return CGSize(width: frame.width, height: 83)
    }
    
    // MARK: Private components
    
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
    
    private lazy var imageViewContainer: UIView = {
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
    
    private lazy var textField: MaskedUITextField = {
        let tf = MaskedUITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.textColor = UIColor.black
        tf.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        tf.heightAnchor.constraint(equalToConstant: 36).isActive = true
        tf.borderStyle = .roundedRect
        tf.autocorrectionType = .no
        tf.keyboardType = UIKeyboardType.numberPad
        tf.accessibilityIdentifier = "tf_forage_ebt_text_field"
        tf.isAccessibilityElement = true
        return tf
    }()
    
    private lazy var imageView: UIImageView = {
        let imgView = UIImageView()
        let image = UIImage(named: "forageLogo", in: AssetsBundle.main.iconBundle, compatibleWith: nil)
        imgView.adjustsImageSizeForAccessibilityContentSizeCategory = true
        imgView.image = image
        imgView.contentMode = .scaleAspectFit
        imgView.translatesAutoresizingMaskIntoConstraints = false
        imgView.heightAnchor.constraint(equalToConstant: 16).isActive = true
        imgView.accessibilityIdentifier = "img_forage_logo"
        imgView.isAccessibilityElement = true
        return imgView
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
        addSubview(root)
        
        root.addSubview(container)
        
        textFieldContainer.addSubview(textField)
        imageViewContainer.addSubview(imageView)
        container.addArrangedSubview(textFieldContainer)
        container.addArrangedSubview(imageViewContainer)
        
        textField.forageDelegate = self
        
        root.anchor(
            top: self.topAnchor,
            leading: self.leadingAnchor,
            bottom: self.bottomAnchor,
            trailing: self.trailingAnchor,
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
        
        textField.anchor(
            top: textFieldContainer.topAnchor,
            leading: textFieldContainer.leadingAnchor,
            bottom: textFieldContainer.bottomAnchor,
            trailing: textFieldContainer.trailingAnchor,
            centerXAnchor: nil,
            padding: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        )
        
        imageView.anchor(
            top: imageViewContainer.topAnchor,
            leading: imageViewContainer.leadingAnchor,
            bottom: imageViewContainer.bottomAnchor,
            trailing: imageViewContainer.trailingAnchor,
            centerXAnchor: nil,
            padding: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        )
        
        let tapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(requestFocus(_:))
        )
        addGestureRecognizer(tapGesture)
        self.logger.notice("ForagePANTextField was initialized successfully", attributes: nil)
    }
    
    @objc fileprivate func requestFocus(_ gesture: UIGestureRecognizer) {
        becomeFirstResponder()
    }
}

// MARK: - UITextFieldDelegate

extension ForagePANTextField : UITextFieldDelegate {
    public func focusDidChange(_ state: ObservableState) {
        delegate?.focusDidChange(self)
    }
    
    public func textFieldDidChange(_ state: ObservableState) {
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
        if !replacementString.allSatisfy({ $0.isNumber }) {
            return false
        }
        
        return true
    }
}

// MARK: - UIResponder methods

extension ForagePANTextField {
    
    /// Make `ForagePANTextField` focused.
    @discardableResult override public func becomeFirstResponder() -> Bool {
        return textField.becomeFirstResponder()
    }
    
    /// Remove  focus from `ForagePANTextField`.
    @discardableResult override public func resignFirstResponder() -> Bool {
        return textField.resignFirstResponder()
    }
    
    /// Check if `ForagePANTextField` is focused.
    override public var isFirstResponder: Bool {
        return textField.isFirstResponder
    }
}
