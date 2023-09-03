//
//  CapturePaymentView.swift
//  SampleForageSDK
//
//  Created by Symphony on 26/10/22.
//

import Foundation
import UIKit
import ForageSDK

class CapturePaymentView: UIView {
    
    // MARK: Private Components
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.white
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Capture Payment"
        label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        label.accessibilityIdentifier = "lbl_title"
        label.isAccessibilityElement = true
        return label
    }()
    
    public let snapTextField: ForagePINTextField = {
        let tf = ForagePINTextField()
        tf.placeholder = "PIN Snap Field"
        tf.pinType = .snap
        tf.accessibilityIdentifier = "tf_pin_snap"
        tf.isAccessibilityElement = true
        return tf
    }()
    
    private let nonSnapTextField: ForagePINTextField = {
        let tf = ForagePINTextField()
        tf.placeholder = "PIN Snap Field"
        tf.pinType = .nonSnap
        tf.accessibilityIdentifier = "tf_pin_non_snap"
        tf.isAccessibilityElement = true
        return tf
    }()
    
    private let captureSnapPaymentButton: UIButton = {
        let button = UIButton()
        button.setTitle("Capture Snap Payment", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(performCaptureSnapPayment(_:)), for: .touchUpInside)
        button.backgroundColor = .systemBlue
        button.accessibilityIdentifier = "bt_capture_snap_payment"
        button.isAccessibilityElement = true
        return button
    }()
    
    private let captureNonSnapPaymentButton: UIButton = {
        let button = UIButton()
        button.setTitle("Capture Non Snap Payment", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.tintColor = .white
        button.addTarget(self, action: #selector(performCaptureNonSnapPayment(_:)), for: .touchUpInside)
        button.backgroundColor = .systemBlue
        button.accessibilityIdentifier = "bt_capture_non_snap_payment"
        button.isAccessibilityElement = true
        return button
    }()
    
    private let statusTypeLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.numberOfLines = 0
        label.accessibilityIdentifier = "lbl_status_type"
        label.isAccessibilityElement = true
        return label
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.numberOfLines = 0
        label.accessibilityIdentifier = "lbl_status"
        label.isAccessibilityElement = true
        return label
    }()
    
    private let paymentRefLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.numberOfLines = 0
        label.accessibilityIdentifier = "lbl_payment_ref"
        label.isAccessibilityElement = true
        return label
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
    
    @objc fileprivate func performCaptureSnapPayment(_ gesture: UIGestureRecognizer) {
        capturePayment(isEbtSnap: true)
    }
    
    @objc fileprivate func performCaptureNonSnapPayment(_ gesture: UIGestureRecognizer) {
        capturePayment(isEbtSnap: false)
    }
    
    // MARK: Public Methods
    
    public func render() {
        snapTextField.delegate = self
        nonSnapTextField.delegate = self
        setupView()
        setupConstraints()
    }
    
    // MARK: Private Methods
    
    private func capturePayment(isEbtSnap: Bool) {
        let paymentReference =
            isEbtSnap
                ? ClientSharedData.shared.paymentReference[FundingType.ebtSnap] ?? ""
                : ClientSharedData.shared.paymentReference[FundingType.ebtCash] ?? ""
        
        let inputFieldReference = isEbtSnap ? snapTextField : nonSnapTextField
        
        ForageSDK.shared.capturePayment(
            bearerToken: ClientSharedData.shared.bearerToken,
            merchantAccount: ClientSharedData.shared.merchantID,
            paymentReference: paymentReference,
            foragePinTextEdit: inputFieldReference) { result in
                self.printResult(result: result)
            }
    }
    
    private func printResult(result: Result<PaymentModel, Error>) {
        DispatchQueue.main.async {
            switch result {
            case .success(let response):
                self.paymentRefLabel.text = "paymentRef=\(response.paymentRef)"
                self.fundingTypeLabel.text = "fundingType=\(response.fundingType)"
                self.amountLabel.text = "amount=\(response.amount)"
                self.errorLabel.text = ""
            case .failure(let error):
                self.errorLabel.text = "\(error)"
                self.paymentRefLabel.text = ""
                self.fundingTypeLabel.text = ""
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
        contentView.addSubview(captureSnapPaymentButton)
        contentView.addSubview(nonSnapTextField)
        contentView.addSubview(captureNonSnapPaymentButton)
        contentView.addSubview(statusTypeLabel)
        contentView.addSubview(statusLabel)
        contentView.addSubview(paymentRefLabel)
        contentView.addSubview(fundingTypeLabel)
        contentView.addSubview(amountLabel)
        contentView.addSubview(errorLabel)
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
            padding: UIEdgeInsets(top: 24, left: 24, bottom: 12, right: 24)
        )
        
        captureSnapPaymentButton.anchor(
            top: snapTextField.safeAreaLayoutGuide.bottomAnchor,
            leading: contentView.safeAreaLayoutGuide.leadingAnchor,
            bottom: nil,
            trailing: contentView.safeAreaLayoutGuide.trailingAnchor,
            centerXAnchor: contentView.centerXAnchor,
            padding: .init(top: 12, left: 24, bottom: 0, right: 24),
            size: .init(width: 0, height: 48)
        )
        
        nonSnapTextField.anchor(
            top: captureSnapPaymentButton.safeAreaLayoutGuide.bottomAnchor,
            leading: contentView.safeAreaLayoutGuide.leadingAnchor,
            bottom: nil,
            trailing: contentView.safeAreaLayoutGuide.trailingAnchor,
            centerXAnchor: contentView.centerXAnchor,
            padding: UIEdgeInsets(top: 24, left: 24, bottom: 12, right: 24)
        )
        
        captureNonSnapPaymentButton.anchor(
            top: nonSnapTextField.safeAreaLayoutGuide.bottomAnchor,
            leading: contentView.safeAreaLayoutGuide.leadingAnchor,
            bottom: nil,
            trailing: contentView.safeAreaLayoutGuide.trailingAnchor,
            centerXAnchor: contentView.centerXAnchor,
            padding: .init(top: 12, left: 24, bottom: 0, right: 24),
            size: .init(width: 0, height: 48)
        )
        
        statusTypeLabel.anchor(
            top: captureNonSnapPaymentButton.safeAreaLayoutGuide.bottomAnchor,
            leading: contentView.safeAreaLayoutGuide.leadingAnchor,
            bottom: nil,
            trailing: contentView.safeAreaLayoutGuide.trailingAnchor,
            centerXAnchor: contentView.centerXAnchor,
            padding: UIEdgeInsets(top: 24, left: 24, bottom: 0, right: 24)
        )
        
        statusLabel.anchor(
            top: statusTypeLabel.safeAreaLayoutGuide.bottomAnchor,
            leading: contentView.safeAreaLayoutGuide.leadingAnchor,
            bottom: nil,
            trailing: contentView.safeAreaLayoutGuide.trailingAnchor,
            centerXAnchor: contentView.centerXAnchor,
            padding: UIEdgeInsets(top: 24, left: 24, bottom: 0, right: 24)
        )
        
        paymentRefLabel.anchor(
            top: statusLabel.safeAreaLayoutGuide.bottomAnchor,
            leading: contentView.safeAreaLayoutGuide.leadingAnchor,
            bottom: nil,
            trailing: contentView.safeAreaLayoutGuide.trailingAnchor,
            centerXAnchor: contentView.centerXAnchor,
            padding: UIEdgeInsets(top: 24, left: 24, bottom: 0, right: 24)
        )
        
        fundingTypeLabel.anchor(
            top: paymentRefLabel.safeAreaLayoutGuide.bottomAnchor,
            leading: contentView.safeAreaLayoutGuide.leadingAnchor,
            bottom: nil,
            trailing: contentView.safeAreaLayoutGuide.trailingAnchor,
            centerXAnchor: contentView.centerXAnchor,
            padding: UIEdgeInsets(top: 24, left: 24, bottom: 0, right: 24)
        )
        
        amountLabel.anchor(
            top: fundingTypeLabel.safeAreaLayoutGuide.bottomAnchor,
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
    }
}

// MARK: - ForagePINTextFieldDelegate

extension CapturePaymentView: ForageElementDelegate {
    func focusDidChange(_ state: ObservableState) {
        
    }
    
    func textFieldDidChange(_ state: ObservableState) {
        
    }
}
