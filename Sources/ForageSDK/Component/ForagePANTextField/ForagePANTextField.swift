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

public class ForagePANTextField: UIView, Identifiable, ForageElement {
    public func setPlaceholderText(_ text: String) {
        
    }
    
    public func clearText() {
        self.actualPan = ""
        self.maskedPan = ""
        self.textField.text = ""
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
        get { return self.actualPan.isEmpty }
    }
    
    private var _isValid: Bool = true
    @IBInspectable public var isValid: Bool {
        get { return _isValid }
    }
    
    private var _isComplete: Bool = false
    @IBInspectable public var isComplete: Bool {
        get { return _isComplete }
    }
    
    // MARK: Private Properties
    private var stateIIN: StateIIN?
    
    // MARK: Public Delegate
    
    /// Delegate that updates client's side about state of the entered card number
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
    
    private lazy var textField: UITextField = {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.textColor = UIColor.black
        tf.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        tf.borderStyle = .roundedRect
        tf.autocorrectionType = .no
        tf.keyboardType = UIKeyboardType.phonePad
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
    }
    
    @objc fileprivate func requestFocus(_ gesture: UIGestureRecognizer) {
        becomeFirstResponder()
    }
    
    internal var actualPan: String = ""
    internal var maskedPan: String = ""
}

// MARK: - UITextFieldDelegate

extension ForagePANTextField: UITextFieldDelegate {
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate?.focusDidChange(self)
    }
    
    public func textFieldDidEndEditing(_ textField: UITextField) {
        delegate?.focusDidChange(self)
    }
    
    private func validateNewInput(text: String) -> Bool {
        if (text.count > 19) {
            return false
        }
        if let stateIIN = ForagePANValidations.checkPANLength(text) {
            if (text.count > stateIIN.panLength) {
                return false
            }
        }
        return true
    }
    
    private func formatText(text: String, maskToApply: Int) -> String {
        var components: [String] = []
        if (maskToApply == 16) {
            // Mask of #### #### #### ####
            let maxSectionLength = 4
            components = {
                var toDeplete = text
                var components: [String] = []
                while !toDeplete.isEmpty {
                    let length = min(toDeplete.count, maxSectionLength)
                    components.append(String(toDeplete.prefix(length)))
                    toDeplete.removeFirst(length)
                }
                return components
            }()
        } else if (maskToApply == 18) {
            // Mask of ###### #### ##### ## #
            var maskComponentLengthsInReverse = [1, 2, 5, 4, 6]
            components = {
                var toDeplete = text
                var components: [String] = []
                while !toDeplete.isEmpty {
                    let maxSectionLength = maskComponentLengthsInReverse.popLast()
                    let length = min(toDeplete.count, maxSectionLength!)
                    components.append(String(toDeplete.prefix(length)))
                    toDeplete.removeFirst(length)
                }
                return components
            }()
        } else {
            // Mask of ###### #### #### ### ##
            var maskComponentLengthsInReverse = [2, 3, 4, 4, 6]
            components = {
                var toDeplete = text
                var components: [String] = []
                while !toDeplete.isEmpty {
                    let maxSectionLength = maskComponentLengthsInReverse.popLast()
                    let length = min(toDeplete.count, maxSectionLength!)
                    components.append(String(toDeplete.prefix(length)))
                    toDeplete.removeFirst(length)
                }
                return components
            }()
        }
        
        // Add spaces
        return components.joined(separator: " ")
    }
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        var newString = (maskedPan as NSString).replacingCharacters(in: range, with: string) // Apply new text

        // Remove all whitespaces
        newString = newString.replacingOccurrences(of: " ", with: "").filter("0123456789".contains)
        
        // Check if the current PAN is already at max length for a valid entry and cap the user there
        if (!validateNewInput(text: newString)) {
            return false
        }
        
        // If the string is less than 6 digits, apply no mask.
        // Prior to seeing 6 digits, the PAN is considered valid but incomplete.
        if newString.count < 6 {
            self.actualPan = newString
            self.maskedPan = newString
            textField.text = newString
            _isValid = true
            _isComplete = false
            delegate?.textFieldDidChange(self)
            return false
        }
        
        var maskToApply = 16
        
        // Check if the first 6 digits are valid
        if let stateIIN = ForagePANValidations.checkPANLength(newString) {
            maskToApply = stateIIN.panLength
            // If the first 6 digits are valid, then we know what the expected length of the card will be.
            // If we haven't reached the max length yet, the PAN is considered valid but incomplete.
            if newString.count < stateIIN.panLength {
                _isValid = true
                _isComplete = false
                delegate?.textFieldDidChange(self)
            } else {
                /// If the first 6 digits are correct and we have the correct length, the PAN is considered valid AND complete.
                _isValid = true
                _isComplete = true
                delegate?.textFieldDidChange(self)
            }
        } else {
            // If 6 or more digits are included and the first 6 digits don't map to a known state, we set the
            // PAN to invalid and incomplete.
            _isValid = false
            _isComplete = false
            delegate?.textFieldDidChange(self)
        }
        
        // Store the string's actual value for submitting later
        self.actualPan = newString
        // Get the masked version of the string
        newString = formatText(text: newString, maskToApply: maskToApply)
        // Store the visual string for reference on next input
        self.maskedPan = newString
        // And show the masked string to the user
        textField.text = newString
        return false
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
