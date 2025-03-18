//
//  ForagePaymentSheet.swift
//  ForageSDK
//
//  Created by Jerimiah on 2/27/25.
//  Copyright © 2025-Present Forage Technology Corporation. All rights reserved.
//

import UIKit

public enum PaymentSheetError: Error {
    case invalidCardNumber
    case invalidDate
    case inComplete
}

public class ForagePaymentSheet: UIView, Identifiable, ForagePaymentSheetElement {
    // MARK: - Properties
    
    public private(set) var completionErrors: [String: any Error] = [:]
    public var currentFirstResponder: (any ForagePaymentSheetField)? {
        get { fields.first { $0.isFirstResponder } }
    }
    
    /// height for textfields
    @IBInspectable public var elementHeight: Int = 83 {
        didSet { fields.forEach({ setHeight(on: $0, to: elementHeight )}) }
    }

    /// complete when all fields are complete
    @IBInspectable public var isComplete: Bool {
        get { fields.allSatisfy({ $0.isComplete }) }
    }

    /// BorderWidth for the text fields
    @IBInspectable public var borderWidth: CGFloat = 0.1 {
        didSet {
            for var field in fields {
                field.borderWidth = borderWidth
            }
        }
    }

    /// BorderColor for the text fields
    @IBInspectable public var borderColor: UIColor? = .black {
        didSet {
            for var field in fields {
                field.borderColor = borderColor ?? .black
            }
        }
    }

    /// CornerRadius for the text fields
    @IBInspectable public var cornerRadius: CGFloat = 4 {
        didSet {
            for var field in fields {
                field.cornerRadius = cornerRadius
            }
        }
    }

    /// MasksToBounds for the text fields
    @IBInspectable public var masksToBounds: Bool = false {
        didSet {
            for var field in fields {
                field.masksToBounds = masksToBounds
            }
        }
    }

    /// Padding for the text fields
    private var _padding: UIEdgeInsets = .init(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
    @IBInspectable public var padding: UIEdgeInsets {
        get { _padding }
        set { _padding = newValue }
    }

    /// Text color for the text fields
    /// `textColor` default value is `black`
    @IBInspectable public var textColor: UIColor? {
        didSet {
            for var field in fields {
                field.textColor = textColor
            }
        }
    }

    /// Size of the text for the text fields
    /// `size` default value is `24`
    @IBInspectable public var size: Double = 24.0 {
        didSet {
            for var field in fields {
                field.size = size
            }
        }
    }

    /// Tint color for the text fields
    /// `tfTintColor` default value is `black`
    @IBInspectable public var tfTintColor: UIColor? {
        didSet {
            for var field in fields {
                field.tfTintColor = tfTintColor
            }
        }
    }

    /// Text alignment
    /// `textAlignment` default value is `natural`
    @IBInspectable public var textAlignment: NSTextAlignment = .natural {
        didSet {
            for var field in fields {
                field.textAlignment = textAlignment
            }
        }
    }

    /// Change UIFont
    /// `UITextField` text font
    @IBInspectable public var font: UIFont? {
        didSet {
            for var field in fields {
                field.font = font
            }
        }
    }

    // MARK: - Public Delegate

//    /// A delegate that informs the client about the state of the sheet.
    public var delegate: ForagePaymentSheetElementDelegate?

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
    
    private lazy var cardNumberTextFieldContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
 
    private lazy var cardExpirationTextFieldContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var cardCVVTextFieldContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var cardZipCodeTextFieldContainer: UIView = {
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
    
    private lazy var expirationCVVHorizontalContainer = {
        let sv = UIStackView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis = .horizontal
        sv.alignment = .fill
        sv.distribution = .fillEqually
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
    
    // MARK: Public Components
    public lazy var cardHolderNameTextField: ForageCardHolderName = ForageCardHolderName()
    public lazy var cardNumberTextField: ForageCardNumber = ForageCardNumber()
    public lazy var cardExpirationTextField: ForageCardExpiration = ForageCardExpiration()
    public lazy var cardCVVTextField: ForageCardCVV = ForageCardCVV()
    public lazy var cardZipCodeTextField: ForageCardZipCode = ForageCardZipCode()
    
    private lazy var imageView: UIView = PoweredByForageImage()
    
    /// collection of all fields to easily iterate and style fields as needed
    public private(set) lazy var fields: [any ForagePaymentSheetField] = [
        cardHolderNameTextField,
        cardNumberTextField,
        cardExpirationTextField,
        cardCVVTextField,
        cardZipCodeTextField
    ]

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
        fields.forEach({ $0.delegate = self })
        
        addSubview(root)

        root.addSubview(container)

        textFieldContainer.addSubview(cardHolderNameTextField)
        cardNumberTextFieldContainer.addSubview(cardNumberTextField)
        cardExpirationTextFieldContainer.addSubview(cardExpirationTextField)
        cardCVVTextFieldContainer.addSubview(cardCVVTextField)
        cardZipCodeTextFieldContainer.addSubview(cardZipCodeTextField)
        imageViewContainer.addSubview(imageView)
        
        expirationCVVHorizontalContainer.addArrangedSubview(cardExpirationTextFieldContainer)
        expirationCVVHorizontalContainer.addArrangedSubview(cardCVVTextFieldContainer)
        
        container.addArrangedSubview(textFieldContainer)
        container.addArrangedSubview(cardNumberTextFieldContainer)
        container.addArrangedSubview(expirationCVVHorizontalContainer)
        container.addArrangedSubview(cardZipCodeTextFieldContainer)
        container.addArrangedSubview(imageViewContainer)

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

        cardHolderNameTextField.anchor(
            top: textFieldContainer.topAnchor,
            leading: textFieldContainer.leadingAnchor,
            bottom: textFieldContainer.bottomAnchor,
            trailing: textFieldContainer.trailingAnchor,
            centerXAnchor: nil,
            padding: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        )
        
        cardNumberTextField.anchor(
            top: cardNumberTextFieldContainer.topAnchor,
            leading: cardNumberTextFieldContainer.leadingAnchor,
            bottom: cardNumberTextFieldContainer.bottomAnchor,
            trailing: cardNumberTextFieldContainer.trailingAnchor,
            centerXAnchor: nil,
            padding: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        )
   
        cardExpirationTextField.anchor(
            top: cardExpirationTextFieldContainer.topAnchor,
            leading: cardExpirationTextFieldContainer.leadingAnchor,
            bottom: cardExpirationTextFieldContainer.bottomAnchor,
            trailing: cardExpirationTextFieldContainer.trailingAnchor,
            centerXAnchor: nil,
            padding: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        )

        cardCVVTextField.anchor(
            top: cardCVVTextFieldContainer.topAnchor,
            leading: cardCVVTextFieldContainer.leadingAnchor,
            bottom: cardCVVTextFieldContainer.bottomAnchor,
            trailing: cardCVVTextFieldContainer.trailingAnchor,
            centerXAnchor: nil,
            padding: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        )

        cardZipCodeTextField.anchor(
            top: cardZipCodeTextFieldContainer.topAnchor,
            leading: cardZipCodeTextFieldContainer.leadingAnchor,
            bottom: cardZipCodeTextFieldContainer.bottomAnchor,
            trailing: cardZipCodeTextFieldContainer.trailingAnchor,
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
        
        logger.notice("ForageHSAForm was initialized successfully", attributes: nil)
    }
    
    private func setHeight(on element: UIView, to newHeight: Int) {
        let heightAnchor = element.heightAnchor.constraint(equalToConstant: CGFloat(newHeight))
        heightAnchor.priority = UILayoutPriority.required
        heightAnchor.isActive = true
    }

    @objc fileprivate func requestFocus(_ gesture: UIGestureRecognizer) {
        becomeFirstResponder()
    }

    // MARK: - Public API

    override public var intrinsicContentSize: CGSize {
        CGSize(width: frame.width, height: 83)
    }

    public func clearSheet() {
        cardHolderNameTextField.clearText()
    }
    
    private func updateSheetState() {
        var errors: [String: any Error] = [:]
        
        for field in fields {
            if field.invalidError != nil {
                errors[field.name] = field.invalidError
            }
        }
        
        completionErrors = errors
    }
}

// MARK: - UIResponder methods
extension ForagePaymentSheet: ForageElementDelegate {
    public func textFieldDidChange(_ state: any ObservableState) {
        updateSheetState()
        delegate?.sheetTextFieldDidChange(self)
    }
    
    public func focusDidChange(_ state: any ObservableState) {
        updateSheetState()
        delegate?.sheetFocusDidChange(self)
    }
}
