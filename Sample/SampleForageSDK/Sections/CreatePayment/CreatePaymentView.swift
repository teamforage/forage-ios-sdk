//
//  CreatePaymentView.swift
//  SampleForageSDK
//
//  Created by Symphony on 25/10/22.
//

import Foundation
import UIKit
import ForageSDK

protocol CreatePaymentViewDelegate: AnyObject {
    func goToCapture(_ view: CreatePaymentView)
}

class CreatePaymentView: UIView {
    
    // MARK: Public Properties
    
    private var controller = CreatePaymentViewController()
    var isPINValid: Bool = false
    weak var delegate: CreatePaymentViewDelegate?
    
    // MARK: Private Components
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.white
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Create Payment"
        label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        label.accessibilityIdentifier = "lbl_title"
        label.isAccessibilityElement = true
        return label
    }()
    
    private let snapTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Snap amount"
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.borderStyle = .roundedRect
        tf.accessibilityIdentifier = "tf_snap_amount"
        tf.isAccessibilityElement = true
        return tf
    }()
    
    private let nonSnapTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Non Snap amount"
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.borderStyle = .roundedRect
        tf.accessibilityIdentifier = "tf_non_snap_amount"
        tf.isAccessibilityElement = true
        return tf
    }()
    
    private let createSnapPaymentButton: UIButton = {
        let button = UIButton()
        button.setTitle("Create Snap Payment", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(performSnapPayment(_:)), for: .touchUpInside)
        button.backgroundColor = .systemBlue
        button.accessibilityIdentifier = "bt_create_snap_payment"
        button.isAccessibilityElement = true
        return button
    }()
    
    private let createNonSnapPaymentButton: UIButton = {
        let button = UIButton()
        button.setTitle("Create Non Snap Payment", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(performNonSnapPayment(_:)), for: .touchUpInside)
        button.backgroundColor = .systemBlue
        button.accessibilityIdentifier = "bt_create_non_snap_payment"
        button.isAccessibilityElement = true
        return button
    }()
    
    private let nextButton: UIButton = {
        let button = UIButton()
        button.setTitle("Go To Next", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(goToCapture(_:)), for: .touchUpInside)
        button.backgroundColor = .systemBlue
        button.accessibilityIdentifier = "bt_next"
        button.isAccessibilityElement = true
        return button
    }()
    
    private let fundingTypeLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.numberOfLines = 0
        label.accessibilityIdentifier = "lbl_funding_type"
        label.isAccessibilityElement = true
        return label
    }()
    
    private let paymentMethodIdentifierLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.numberOfLines = 0
        label.accessibilityIdentifier = "lbl_payment_method_identifier"
        label.isAccessibilityElement = true
        return label
    }()
    
    private let paymentIdentifierLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.numberOfLines = 0
        label.accessibilityIdentifier = "lbl_payment_identifier"
        label.isAccessibilityElement = true
        return label
    }()
    
    private let merchantAccountLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.numberOfLines = 0
        label.accessibilityIdentifier = "lbl_merchant_account"
        label.isAccessibilityElement = true
        return label
    }()
    
    private let amountLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.numberOfLines = 0
        label.accessibilityIdentifier = "lbl_amount"
        label.isAccessibilityElement = true
        return label
    }()
    
    private let errorLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.numberOfLines = 0
        label.accessibilityIdentifier = "lbl_error"
        label.isAccessibilityElement = true
        return label
    }()
    
    // MARK: Fileprivate Methods
    
    @objc fileprivate func performSnapPayment(_ gesture: UIGestureRecognizer) {
        createPayment(isEbtSnap: true)
    }
    
    @objc fileprivate func performNonSnapPayment(_ gesture: UIGestureRecognizer) {
        createPayment(isEbtSnap: false)
    }
    
    @objc fileprivate func goToCapture(_ gesture: UIGestureRecognizer) {
        delegate?.goToCapture(self)
    }
    
    // MARK: Public Methods
    
    public func render() {
        setupView()
        setupConstraints()
    }
    
    // MARK: Private Methods
    
    private func createPayment(isEbtSnap: Bool) {
        var paymentAmount: Double = 0.0
        
        if isEbtSnap {
            guard
                let stringAmount = snapTextField.text,
                let amount = Double(stringAmount)
            else { return }
            paymentAmount = amount
        } else {
            guard
                let stringAmount = nonSnapTextField.text,
                let amount = Double(stringAmount)
            else { return }
            paymentAmount = amount
        }
        
        let request = CreatePaymentRequest(
            amount: paymentAmount,
            fundingType: isEbtSnap ? "ebt_snap" : "ebt_cash",
            paymentMethodIdentifier: ClientSharedData.shared.paymentMethodReference,
            merchantAccount: ClientSharedData.shared.merchantID,
            description: "desc",
            metadata: [:],
            deliveryAddress: Address(
                city: "Los Angeles",
                country: "United States",
                line1: "Street",
                line2: "Number",
                zipcode: "12345",
                state: "LA"
            ),
            isDelivery: false
        )
        
        controller.createPayment(request: request) { result in
            self.printResult(result: result)
        }
    }
    
    private func printResult(result: Result<CreatePaymentResponse, Error>) {
        DispatchQueue.main.async {
            switch result {
            case .success(let response):
                self.fundingTypeLabel.text = "fundingType=\(response.fundingType.rawValue)"
                self.paymentMethodIdentifierLabel.text = "paymentMethodIdentifier=\(response.paymentMethodIdentifier)"
                self.paymentIdentifierLabel.text = "paymentIdentifier=\(response.paymentIdentifier)"
                self.merchantAccountLabel.text = "merchantAccount=\(response.merchantAccount)"
                self.amountLabel.text = "amount=\(response.amount)"
                self.errorLabel.text = ""
                ClientSharedData.shared.paymentReference = [response.fundingType : response.paymentIdentifier]
                
            case .failure(let error):
                self.errorLabel.text = "error: \n\(error.localizedDescription)"
                self.fundingTypeLabel.text = ""
                self.paymentMethodIdentifierLabel.text = ""
                self.paymentIdentifierLabel.text = ""
                self.merchantAccountLabel.text = ""
                self.amountLabel.text = ""
            }
            
            self.layoutIfNeeded()
            self.layoutSubviews()
        }
    }
    
    private func setupView() {
        self.addSubview(contentView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(snapTextField)
        contentView.addSubview(createSnapPaymentButton)
        contentView.addSubview(nonSnapTextField)
        contentView.addSubview(createNonSnapPaymentButton)
        contentView.addSubview(fundingTypeLabel)
        contentView.addSubview(paymentMethodIdentifierLabel)
        contentView.addSubview(paymentIdentifierLabel)
        contentView.addSubview(merchantAccountLabel)
        contentView.addSubview(amountLabel)
        contentView.addSubview(errorLabel)
        contentView.addSubview(nextButton)
    }
    
    private func setupConstraints() {
        setupContentViewConstraints()
    }
    
    private func setupContentViewConstraints() {
        
        contentView.anchor(
            top: self.topAnchor,
            leading: self.leadingAnchor,
            bottom: self.bottomAnchor,
            trailing: self.trailingAnchor,
            centerXAnchor: self.centerXAnchor
        )
        
        titleLabel.anchor(
            top: contentView.safeAreaLayoutGuide.topAnchor,
            leading: contentView.safeAreaLayoutGuide.leadingAnchor,
            bottom: nil,
            trailing: contentView.safeAreaLayoutGuide.trailingAnchor,
            centerXAnchor: contentView.centerXAnchor,
            padding: UIEdgeInsets(top: 24, left: 24, bottom: 12, right: 24)
        )
        
        snapTextField.anchor(
            top: titleLabel.safeAreaLayoutGuide.bottomAnchor,
            leading: contentView.safeAreaLayoutGuide.leadingAnchor,
            bottom: nil,
            trailing: contentView.safeAreaLayoutGuide.trailingAnchor,
            centerXAnchor: contentView.centerXAnchor,
            padding: UIEdgeInsets(top: 24, left: 24, bottom: 12, right: 24),
            size: .init(width: 0, height: 42)
        )
        
        createSnapPaymentButton.anchor(
            top: snapTextField.safeAreaLayoutGuide.bottomAnchor,
            leading: contentView.safeAreaLayoutGuide.leadingAnchor,
            bottom: nil,
            trailing: contentView.safeAreaLayoutGuide.trailingAnchor,
            centerXAnchor: contentView.centerXAnchor,
            padding: .init(top: 12, left: 24, bottom: 0, right: 24),
            size: .init(width: 0, height: 48)
        )
        
        nonSnapTextField.anchor(
            top: createSnapPaymentButton.safeAreaLayoutGuide.bottomAnchor,
            leading: contentView.safeAreaLayoutGuide.leadingAnchor,
            bottom: nil,
            trailing: contentView.safeAreaLayoutGuide.trailingAnchor,
            centerXAnchor: contentView.centerXAnchor,
            padding: UIEdgeInsets(top: 24, left: 24, bottom: 12, right: 24),
            size: .init(width: 0, height: 42)
        )
        
        createNonSnapPaymentButton.anchor(
            top: nonSnapTextField.safeAreaLayoutGuide.bottomAnchor,
            leading: contentView.safeAreaLayoutGuide.leadingAnchor,
            bottom: nil,
            trailing: contentView.safeAreaLayoutGuide.trailingAnchor,
            centerXAnchor: contentView.centerXAnchor,
            padding: .init(top: 12, left: 24, bottom: 0, right: 24),
            size: .init(width: 0, height: 48)
        )
        
        fundingTypeLabel.anchor(
            top: createNonSnapPaymentButton.safeAreaLayoutGuide.bottomAnchor,
            leading: contentView.safeAreaLayoutGuide.leadingAnchor,
            bottom: nil,
            trailing: contentView.safeAreaLayoutGuide.trailingAnchor,
            centerXAnchor: contentView.centerXAnchor,
            padding: UIEdgeInsets(top: 24, left: 24, bottom: 0, right: 24)
        )
        
        paymentMethodIdentifierLabel.anchor(
            top: fundingTypeLabel.safeAreaLayoutGuide.bottomAnchor,
            leading: contentView.safeAreaLayoutGuide.leadingAnchor,
            bottom: nil,
            trailing: contentView.safeAreaLayoutGuide.trailingAnchor,
            centerXAnchor: contentView.centerXAnchor,
            padding: UIEdgeInsets(top: 24, left: 24, bottom: 0, right: 24)
        )
        
        paymentIdentifierLabel.anchor(
            top: paymentMethodIdentifierLabel.safeAreaLayoutGuide.bottomAnchor,
            leading: contentView.safeAreaLayoutGuide.leadingAnchor,
            bottom: nil,
            trailing: contentView.safeAreaLayoutGuide.trailingAnchor,
            centerXAnchor: contentView.centerXAnchor,
            padding: UIEdgeInsets(top: 24, left: 24, bottom: 0, right: 24)
        )
        
        merchantAccountLabel.anchor(
            top: paymentIdentifierLabel.safeAreaLayoutGuide.bottomAnchor,
            leading: contentView.safeAreaLayoutGuide.leadingAnchor,
            bottom: nil,
            trailing: contentView.safeAreaLayoutGuide.trailingAnchor,
            centerXAnchor: contentView.centerXAnchor,
            padding: UIEdgeInsets(top: 24, left: 24, bottom: 0, right: 24)
        )
        
        amountLabel.anchor(
            top: merchantAccountLabel.safeAreaLayoutGuide.bottomAnchor,
            leading: contentView.safeAreaLayoutGuide.leadingAnchor,
            bottom: nil,
            trailing: contentView.safeAreaLayoutGuide.trailingAnchor,
            centerXAnchor: contentView.centerXAnchor,
            padding: UIEdgeInsets(top: 24, left: 24, bottom: 0, right: 24)
        )
        
        errorLabel.anchor(
            top: amountLabel.safeAreaLayoutGuide.bottomAnchor,
            leading: contentView.safeAreaLayoutGuide.leadingAnchor,
            bottom: nil,
            trailing: contentView.safeAreaLayoutGuide.trailingAnchor,
            centerXAnchor: contentView.centerXAnchor,
            padding: UIEdgeInsets(top: 24, left: 24, bottom: 0, right: 24)
        )
        
        nextButton.anchor(
            top: nil,
            leading: contentView.safeAreaLayoutGuide.leadingAnchor,
            bottom: contentView.safeAreaLayoutGuide.bottomAnchor,
            trailing: contentView.safeAreaLayoutGuide.trailingAnchor,
            centerXAnchor: contentView.centerXAnchor,
            padding: .init(top: 0, left: 24, bottom: 0, right: 24),
            size: .init(width: 0, height: 48)
        )
    }
}
