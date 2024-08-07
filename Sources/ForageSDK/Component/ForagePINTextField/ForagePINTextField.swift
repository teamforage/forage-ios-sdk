//
//  ForagePINTextField.swift
//  ForageSDK
//

import UIKit
import VGSCollectSDK

public class ForagePINTextField: UIView, Identifiable, ForageElement {
    // MARK: - Properties

    /// Delegate that updates client's side about state of the entered pin
    public weak var delegate: ForageElementDelegate?

    // MARK: - Exposed properties

    @IBInspectable public var isEmpty: Bool { textField.isEmpty }

    @IBInspectable public var isValid: Bool { textField.isValid }

    @IBInspectable public var isComplete: Bool { textField.isComplete }

    /// CornerRadius for the text field
    @IBInspectable public var cornerRadius: CGFloat {
        get { textField.cornerRadius }
        set { textField.cornerRadius = newValue }
    }

    /// MasksToBounds for the text field
    @IBInspectable public var masksToBounds: Bool {
        get { textField.masksToBounds }
        set { textField.masksToBounds = newValue }
    }

    /// BorderWidth for the text field
    @IBInspectable public var borderWidth: CGFloat {
        get { textField.borderWidth }
        set { textField.borderWidth = newValue }
    }

    /// BorderColor for the text field
    @IBInspectable public var borderColor: UIColor? {
        get { textField.borderColor }
        set { textField.borderColor = newValue }
    }

    /// Padding for the text field
    @IBInspectable public var padding: UIEdgeInsets {
        get { textField.padding }
        set { textField.padding = newValue }
    }

    /// Placeholder for the text field
    @available(*, deprecated, message: "Setting ForagePINTextField.placeholder is unsupported.")
    @IBInspectable public var placeholder: String? {
        get { textField.placeholder }
        set { textField.placeholder = newValue }
    }

    /// Text color for the text field
    /// `textColor` default value is `black`
    @IBInspectable public var textColor: UIColor? {
        get { textField.textColor }
        set { textField.textColor = newValue }
    }

    /// BackgroundColor for the text field
    @IBInspectable override public var backgroundColor: UIColor? {
        get { textField.backgroundColor }
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
        get { textField.tintColor }
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
        get { textField.font }
        set { textField.font = newValue }
    }

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
        let vaultType = LDManager.shared.getVaultType(
            ldClient: LDManager.getDefaultLDClient(),
            genRandomDouble: LDManager.generateRandomDouble
        )

        var tf: VaultWrapper?

        if vaultType == VaultType.basisTheory {
            tf = BasisTheoryTextFieldWrapper()
        } else {
            tf = RosettaPINTextField()
        }

        tf?.textColor = UIColor.black
        tf?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        tf?.borderWidth = 0
        tf?.cornerRadius = 16
        tf?.masksToBounds = true
        tf?.borderColor = .clear
        tf?.backgroundColor = .systemGray6

        return tf ?? RosettaPINTextField()
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

    func getPinCollector() -> VaultCollector {
        textField.collector
    }

    // MARK: - Lifecycle methods

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    // MARK: - Private Methods

    private func commonInit() {
        addSubview(root)

        root.addSubview(container)

        textFieldContainer.addSubview(textField as UIView)
        imageViewContainer.addSubview(imageView)
        container.addArrangedSubview(textFieldContainer)
        container.addArrangedSubview(imageViewContainer)

        textField.delegate = self

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
        logger.notice("ForagePINTextField was initialized successfully", attributes: nil)
    }

    @objc fileprivate func requestFocus(_ gesture: UIGestureRecognizer) {
        becomeFirstResponder()
    }

    // MARK: - Public API

    public func clearText() {
        DispatchQueue.main.async {
            self.textField.clearText()
        }
    }
}

// MARK: - VaultWrapperDelegate

extension ForagePINTextField: VaultWrapperDelegate {
    func textFieldDidChange(_ textField: VaultWrapper) {
        delegate?.textFieldDidChange(self)
    }

    func firstResponderDidChange(_ textField: VaultWrapper) {
        delegate?.focusDidChange(self)
    }
}

// MARK: - UIResponder methods

extension ForagePINTextField {
    /// Make `ForagePINTextField` focused.
    @discardableResult override public func becomeFirstResponder() -> Bool {
        textField.becomeFirstResponder()
    }

    /// Remove focus from `ForagePINTextField`.
    @discardableResult override public func resignFirstResponder() -> Bool {
        textField.resignFirstResponder()
    }

    /// Check if `ForagePINTextField` is focused.
    override public var isFirstResponder: Bool {
        textField.isFirstResponder
    }
}
