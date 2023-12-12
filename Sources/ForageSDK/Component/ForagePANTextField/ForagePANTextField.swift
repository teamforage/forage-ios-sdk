//
//  ForagePANTextField.swift
//  ForageSDK
//

import UIKit
import VGSCollectSDK

public enum CardType: String {
    case EBT = "ebt"
}

public class ForagePANTextField: UIView, ForageTextField, ForageTextFieldDelegate {
    // MARK: - Properties

    @IBInspectable public var isEmpty: Bool {
        enhancedTextField.isEmpty
    }

    @IBInspectable public var isValid: Bool {
        enhancedTextField.isValid
    }

    @IBInspectable public var isComplete: Bool {
        enhancedTextField.isComplete
    }

    public var derivedCardInfo: DerivedCardInfo {
        enhancedTextField.derivedCardInfo
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
    @IBInspectable public var cornerRadius: CGFloat {
        get { enhancedTextField.layer.cornerRadius }
        set { enhancedTextField.layer.cornerRadius = newValue }
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
        set { enhancedTextField.placeholder = newValue }
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

    /// A delegate that informs the client about the state of the entered card number (validation, focus).
    public weak var delegate: ForageTextFieldDelegate?

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

    /// UITextField with masking and floating placeholder label functionality.
    lazy var enhancedTextField: MaskedUITextField = {
        let tf = MaskedUITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.textColor = UIColor.black
        tf.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        tf.heightAnchor.constraint(equalToConstant: 37).isActive = true
        tf.borderStyle = .roundedRect
        tf.autocorrectionType = .no
        tf.keyboardType = UIKeyboardType.numberPad
        tf.accessibilityIdentifier = "tf_forage_ebt_text_field"
        tf.isAccessibilityElement = true
        tf.borderWidth = 0.1
        tf.borderColor = .black
        tf.layer.cornerRadius = 4
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
        imageViewContainer.addSubview(imageView)
        container.addArrangedSubview(textFieldContainer)
        container.addArrangedSubview(imageViewContainer)

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
        logger.notice("ForagePANTextField was initialized successfully", attributes: nil)
    }

    @objc fileprivate func requestFocus(_ gesture: UIGestureRecognizer) {
        becomeFirstResponder()
    }

    func getActualPAN() -> String {
        enhancedTextField.actualPAN
    }

    // MARK: - Public API

    override public var intrinsicContentSize: CGSize {
        CGSize(width: frame.width, height: 83)
    }

    public func clearText() {
        enhancedTextField.text = ""
        enhancedTextField.actualPAN = ""
    }
}

// MARK: - UIResponder methods

// TODO: update comments
extension ForagePANTextField {
    /// Set focus on the `ForagePANTextField` if ...
    @discardableResult override public func becomeFirstResponder() -> Bool {
        enhancedTextField.becomeFirstResponder()
    }

    /// Remove  focus from `ForagePANTextField`.
    @discardableResult override public func resignFirstResponder() -> Bool {
        enhancedTextField.resignFirstResponder()
    }

    /// Check if `ForagePANTextField` is focused.
    override public var isFirstResponder: Bool {
        enhancedTextField.isFirstResponder
    }
}
