//
//  ForagePINTextField.swift
//  ForageSDK
//
//  Created by Symphony on 23/10/22.
//

import UIKit
import VGSCollectSDK

public class ForagePINTextField: UIView, Identifiable, ForageElement {
    public func setPlaceholderText(_ text: String) {
        
    }
    
    @IBInspectable public var isEmpty: Bool {
        get { return textField.isEmpty }
    }
    
    @IBInspectable public var isValid: Bool {
        get { return textField.isValid }
    }
    
    @IBInspectable public var isComplete: Bool {
        get { return textField.isComplete }
    }
    
    // MARK: Public Delegate
    
    /// Delegate that updates client's side about state of the entered pin
    public weak var delegate: ForageElementDelegate?
    
    // MARK: Public Properties
    
    public var pinType: PinType = .balance
    
    internal var collector: VaultCollector?
    
    // TODO: This is a no-op for now
    /// BorderWidth for the text field
    public var cornerRadius: CGFloat = 0
    
    /// BorderWidth for the text field
    @IBInspectable public var borderWidth: CGFloat {
        get { return textField.borderWidth }
        set { textField.borderWidth = newValue }
    }
    
    /// BorderColor for the text field
    @IBInspectable public var borderColor: UIColor? {
        get { return textField.borderColor }
        set { textField.borderColor = newValue }
    }
    
    /// BorderRadius for the text field
    @IBInspectable public var borderRadius: CGFloat {
        get { return textField.borderRadius }
        set { textField.borderRadius = newValue }
    }
    
    /// Padding for the text field
    @IBInspectable public var padding: UIEdgeInsets {
        get { return textField.padding }
        set { textField.padding = newValue }
    }
    
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
    
    /// BackgroundColor for the text field
    @IBInspectable public override var backgroundColor: UIColor? {
        get { return textField.backgroundColor }
        set { textField.backgroundColor = newValue }
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
    
    /// Change UIFont
    /// `VGSTextField` text font
    @IBInspectable public var font: UIFont? {
        get { return textField.font }
        set { textField.font = newValue }
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
    
    private lazy var textField: VaultWrapper = {
        let vaultType = LDManager.shared.getVaultType()
        
        var tf: VaultWrapper?
        
        if (vaultType == VaultType.vgsVaultType) {
            tf = VGSTextFieldWrapper()
        } else if (vaultType == VaultType.btVaultType) {
            tf = BasisTheoryTextFieldWrapper()
        } else {
            tf = VGSTextFieldWrapper()
        }
        
        tf?.textColor = UIColor.black
        tf?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        tf?.borderWidth = 0.25
        tf?.borderRadius = 4
        tf?.borderColor = UIColor.lightGray
        tf?.backgroundColor = UIColor.white
        tf?.padding = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
        collector = tf?.collector
        
        return tf ?? VGSTextFieldWrapper()
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
        
        textFieldContainer.addSubview(textField as UIView)
        imageViewContainer.addSubview(imageView)
        container.addArrangedSubview(textFieldContainer)
        container.addArrangedSubview(imageViewContainer)
        
        textField.delegate = self
        
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
        self.logger.notice("ForagePINTextField was initialized successfully", attributes: nil)
    }
    
    @objc fileprivate func requestFocus(_ gesture: UIGestureRecognizer) {
        becomeFirstResponder()
    }

    public func clearText() {
        textField.clearText()
    }
}

extension ForagePINTextField: VaultWrapperDelegate {
    internal func textFieldDidChange(_ textField: VaultWrapper) {
        delegate?.textFieldDidChange(self)
    }
    
    internal func firstResponderDidChange(_ textField: VaultWrapper) {
        delegate?.focusDidChange(self)
    }
}

// MARK: - UIResponder methods
extension ForagePINTextField {
    /// Make `ForagePINTextField` focused.
    @discardableResult override public func becomeFirstResponder() -> Bool {
        return textField.becomeFirstResponder()
    }

    /// Remove focus from `ForagePINTextField`.
    @discardableResult override public func resignFirstResponder() -> Bool {
        return textField.resignFirstResponder()
    }

    /// Check if `ForagePINTextField` is focused.
    override public var isFirstResponder: Bool {
        return textField.isFirstResponder
    }
}
