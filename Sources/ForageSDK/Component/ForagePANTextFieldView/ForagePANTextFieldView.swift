//
//  ForagePANTextFieldView.swift
//  ForageSDK
//
//  Created by Symphony on 16/10/22.
//

import UIKit
import VGSCollectSDK

private enum CardType: String {
    case ebt = "ebt"
}

public class ForagePANTextFieldView: UIView, Identifiable {
    
    // MARK: Private Properties
    
    private var controller: ForagePANTextFieldViewController!
    private var panNumber = ""
    private var stateIIN: StateIIN?
    
    // MARK: Public Delegate
    
    /// Delegate that updates client's side about state of the entered card number
    public weak var delegate: ForagePANTextFieldDelegate?
    
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
    /// `textColor` default value is `black`
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
    /// `isSecureTextEntry` default value is `false`
    @IBInspectable public var isSecureTextEntry: Bool = false {
        didSet { textField.isSecureTextEntry = isSecureTextEntry }
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
    
    override public var intrinsicContentSize: CGSize {
        return CGSize(width: frame.width, height: 83)
    }
    
    // MARK: Private components
    
    private lazy var container: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var textField: UITextField = {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.textColor = UIColor.black
        tf.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        tf.borderStyle = .roundedRect
        tf.autocorrectionType = .no
        tf.keyboardType = UIKeyboardType.phonePad
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
        controller = LiveForagePANTextFieldViewController()
        addSubview(container)
        
        container.addSubview(textField)
        
        textField.delegate = self

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
    
    // MARK: Public Methods
    
    public func sendPanCardNumber(completion: @escaping (Result<ForagePANModel, Error>) -> Void) -> Void {
        let foragePANRequest = ForagePANRequest(
            authorization: ForageSDK.shared.bearerToken,
            merchantAccount: ForageSDK.shared.merchantID,
            panNumber: panNumber,
            type: CardType.ebt.rawValue,
            reusable: true
        )
        
        controller.sendPanCardNumber(
            request: foragePANRequest,
            completion: completion
        )
    }
    
    public func cancelRequest() {
        controller.cancelRequest()
    }
}

// MARK: - UITextFieldDelegate

extension ForagePANTextFieldView: UITextFieldDelegate {
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let panNumber = textField.text else { return true }
        
        let currentString = (textField.text ?? "") as NSString
        let newString = currentString.replacingCharacters(in: range, with: string)
        
        /// While entering first 6 digits continue typing allowed
        if newString.count < 6 {
            delegate?.panNumberStatus(self, cardStatus: .identifying)
            return true
        }
        
        /// Check if 6 first entered number are valid
        if let stateIIN = ForagePANValidations.checkPANLength(newString) {
            /// Check max length allowed is fulfill
            if newString.count <= stateIIN.panLength {
                delegate?.panNumberStatus(self, cardStatus: .identifying)
                return true
            } else {
                self.panNumber = panNumber
                delegate?.panNumberStatus(self, cardStatus: .valid)
                return false
            }
            /// A pan number is invalid in case it has more than 6 digits and is not in the allowed list
        } else if newString.count >= 6 {
            delegate?.panNumberStatus(self, cardStatus: .invalid)
        }
        
        /// Default text field allowed digits
        return newString.count <= 16
    }
}

// MARK: - UIResponder methods

extension ForagePANTextFieldView {
    
    /// Make `ForagePANTextFieldView` focused.
    @discardableResult override public func becomeFirstResponder() -> Bool {
        return textField.becomeFirstResponder()
    }
    
    /// Remove  focus from `ForagePANTextFieldView`.
    @discardableResult override public func resignFirstResponder() -> Bool {
        return textField.resignFirstResponder()
    }
    
    /// Check if `ForagePANTextFieldView` is focused.
    override public var isFirstResponder: Bool {
        return textField.isFirstResponder
    }
}
