//
//  ForagePINTextFieldView.swift
//  ForageSDK
//
//  Created by Symphony on 23/10/22.
//

import UIKit
import VGSCollectSDK

public enum PINType {
    case balance(paymentMethodReference: String, cardNumberToken: String)
    case ebtCapture(paymentReference: String, cardNumberToken: String)
}

public class ForagePINTextFieldView: UIView, Identifiable {
    
    // MARK: Private Properties
    
    private var controller: ForagePINTextFieldViewController!
    
    // MARK: Public Delegate
    
    /// Delegate that updates client's side about state of the entered pin
    public weak var delegate: ForagePINTextFieldDelegate?
    
    // MARK: Public Properties
    
    /// Init VGS Collector
    ///
    /// - Parameters:
    ///
    ///  - id: client vaultid
    ///  - environment: client environment
    ///
    var collector = VGSCollect(id: "tntagcot4b1", environment: .sandbox)
    
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
        controller = LiveForagePINTextFieldViewController()
        addSubview(container)
        
        container.addSubview(textField)
        
        textField.delegate = self
        let configuration = VGSConfiguration(collector: controller.collector, fieldName: "pin")
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
    
    // MARK: Public Methods
    
    public func performRequest(forPIN type: PINType) {
        switch type {
        case .balance(let paymentMethodReference, let cardNumberToken):
            requestBalance(paymentMethodReference: paymentMethodReference, cardNumberToken: cardNumberToken)
        case .ebtCapture(let paymentReference, let cardNumberToken):
            capturePayment(paymentReference: paymentReference, cardNumberToken: cardNumberToken)
        }
    }
    
    private func requestBalance(
        paymentMethodReference: String,
        cardNumberToken: String) -> Void {
        controller.requestBalance(
            paymentMethodReference: paymentMethodReference,
            cardNumberToken: cardNumberToken) { result in
                self.delegate?.balanceCallback(self, result: result)
            }
    }
    
    private func capturePayment(
        paymentReference: String,
        cardNumberToken: String
    ) -> Void {
            controller.capturePayment(
                paymentReference: paymentReference,
                cardNumberToken: cardNumberToken,
                merchantID: ForageSDK.shared.merchantID
            ) { result in
                self.delegate?.capturePaymentCallback(self, result: result)
            }
    }
}

extension ForagePINTextFieldView: VGSTextFieldDelegate {
    /// Check active vgs textfield's state when editing the field
    public func vgsTextFieldDidChange(_ textField: VGSTextField) {
        let isValid = textField.state.inputLength == 4
        delegate?.pinStatus(self, isValid: isValid)
//        textField.borderColor = .white
        print(textField.state.description)
    }
}

// MARK: - UIResponder methods

extension ForagePINTextFieldView {
    
    /// Make `ForagePINTextFieldView` focused.
    @discardableResult override public func becomeFirstResponder() -> Bool {
        return textField.becomeFirstResponder()
    }
    
    /// Remove  focus from `ForagePINTextFieldView`.
    @discardableResult override public func resignFirstResponder() -> Bool {
        return textField.resignFirstResponder()
    }
    
    /// Check if `ForagePINTextFieldView` is focused.
    override public var isFirstResponder: Bool {
        return textField.isFirstResponder
    }
}
