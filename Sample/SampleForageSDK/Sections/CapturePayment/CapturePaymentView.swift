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
    
    // MARK: Public Properties
    
    var isSnapPINValid: Bool = false
    var isNonSnapPINValid: Bool = false
    
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
        label.accessibilityLabel = "Title label"
        label.accessibilityIdentifier = "lbl_title"
        return label
    }()
    
    private let snapTextField: ForagePINTextField = {
        let tf = ForagePINTextField()
        tf.placeholder = "PIN Snap Field"
        tf.isSecureTextEntry = true
        tf.pinType = .snap
        tf.accessibilityLabel = "Snap PIN Text Field"
        tf.accessibilityIdentifier = "tf_pin_snap"
        return tf
    }()
    
    private let nonSnapTextField: ForagePINTextField = {
        let tf = ForagePINTextField()
        tf.placeholder = "PIN Snap Field"
        tf.isSecureTextEntry = true
        tf.pinType = .nonSnap
        tf.accessibilityLabel = "Non snap PIN Text Field"
        tf.accessibilityIdentifier = "tf_pin_non_snap"
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
        button.accessibilityLabel = "Capture snap button"
        button.accessibilityIdentifier = "bt_capture_snap_payment"
        return button
    }()
    
    private let captureNonSnapPaymentButton: UIButton = {
        let button = UIButton()
        button.setTitle("Capture Non Snap Payment", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.tintColor = .white
        button.addTarget(self, action: #selector(performCaptureNonSnapPayment(_:)), for: .touchUpInside)
        button.backgroundColor = .systemBlue
        button.accessibilityLabel = "Capture non snap button"
        button.accessibilityIdentifier = "bt_capture_non_snap_payment"
        return button
    }()
    
    private let statusTypeLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.numberOfLines = 0
        label.accessibilityLabel = "Status type label"
        label.accessibilityIdentifier = "lbl_status_type"
        return label
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.numberOfLines = 0
        label.accessibilityLabel = "Status label"
        label.accessibilityIdentifier = "lbl_status"
        return label
    }()
    
    private let paymentRefLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.numberOfLines = 0
        label.accessibilityLabel = "Payment ref label"
        label.accessibilityIdentifier = "lbl_payment_ref"
        return label
    }()
    
    private let fundingTypeLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.numberOfLines = 0
        label.accessibilityLabel = "Funding type label"
        label.accessibilityIdentifier = "lbl_funding_type"
        return label
    }()
    
    private let amountLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.numberOfLines = 0
        label.accessibilityLabel = "Amount label"
        label.accessibilityIdentifier = "lbl_amount"
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
        if isSnapPINValid || isNonSnapPINValid {
            let paymentReference =
                isEbtSnap
                    ? ClientSharedData.shared.paymentReference[FundingType.ebtSnap] ?? ""
                    : ClientSharedData.shared.paymentReference[FundingType.ebtCash] ?? ""
            
            ForageSDK.shared.capturePayment(
                bearerToken: ClientSharedData.shared.bearerToken,
                merchantAccount: ClientSharedData.shared.merchantID,
                paymentReference: paymentReference,
                cardNumberToken: ClientSharedData.shared.cardNumberToken) { result in
                    self.printResult(result: result)
                }
        }
    }
    
    private func printResult(result: Result<Data?, Error>) {
        DispatchQueue.main.async {
            switch result {
            case .success(let data):
                guard let data = data,
                      let response = try? JSONDecoder().decode(ForageCaptureModel.self, from: data)
                else { return }
                self.paymentRefLabel.text = "paymentRef=\(response.paymentIdentifier)"
                self.fundingTypeLabel.text = "fundingType=\(response.fundingType)"
                self.amountLabel.text = "amount=\(response.amount)"
            case .failure(let error):
                self.paymentRefLabel.text = "error: \n\(error.localizedDescription)"
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
            size: .init(width: 0, height: 60)
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
            padding: UIEdgeInsets(top: 24, left: 24, bottom: 12, right: 24),
            size: .init(width: 0, height: 60)
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
    }
}

// MARK: - ForagePINTextFieldDelegate

extension CapturePaymentView: ForagePINTextFieldDelegate {
    func pinStatus(_ view: UIView, isValid: Bool, pinType: PinType) {
        if pinType == .snap {
            isSnapPINValid = isValid
        } else {
            isNonSnapPINValid = isValid
        }
        statusTypeLabel.text = "type=\(pinType.rawValue)"
        statusLabel.text = "isValid=\(isValid)"
    }
}
