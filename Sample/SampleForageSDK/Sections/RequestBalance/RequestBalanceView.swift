//
//  RequestBalanceView.swift
//  SampleForageSDK
//
//  Created by Symphony on 24/10/22.
//

import Foundation
import UIKit
import ForageSDK

protocol RequestBalanceViewDelegate: AnyObject {
    func goToCreatePayment(_ view: RequestBalanceView)
}

class RequestBalanceView: UIView {
    
    // MARK: Public Properties
    
    var isPINValid: Bool = false
    weak var delegate: RequestBalanceViewDelegate?
    
    // MARK: Private Components
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.white
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Request Balance"
        label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        label.accessibilityIdentifier = "lbl_title"
        label.isAccessibilityElement = true
        return label
    }()
    
    private let pinNumberTextField: ForagePINTextField = {
        let tf = ForagePINTextField()
        tf.placeholder = "PIN Field"
        tf.isSecureTextEntry = true
        tf.pinType = .balance
        tf.accessibilityIdentifier = "tf_pin_balance"
        tf.isAccessibilityElement = true
        return tf
    }()
    
    private let requestBalanceButton: UIButton = {
        let button = UIButton()
        button.setTitle("Get Balance", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(getBalanceInfo(_:)), for: .touchUpInside)
        button.backgroundColor = .systemBlue
        button.isEnabled = false
        button.isUserInteractionEnabled = false
        button.alpha = 0.5
        button.accessibilityIdentifier = "bt_check_balance"
        button.isAccessibilityElement = true
        return button
    }()
    
    private let nextButton: UIButton = {
        let button = UIButton()
        button.setTitle("Go To Next", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(goToCreatePayment(_:)), for: .touchUpInside)
        button.backgroundColor = .systemBlue
        button.isEnabled = false
        button.isUserInteractionEnabled = false
        button.alpha = 0.5
        button.accessibilityIdentifier = "bt_next"
        button.isAccessibilityElement = true
        return button
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = "PIN status"
        label.textColor = .red
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.accessibilityIdentifier = "lbl_status"
        label.isAccessibilityElement = true
        return label
    }()
    
    private let snapBalanceLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.numberOfLines = 0
        label.accessibilityIdentifier = "lbl_snap_balance"
        label.isAccessibilityElement = true
        return label
    }()
    
    private let nonSnapBalanceLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.numberOfLines = 0
        label.accessibilityIdentifier = "lbl_non_snap_balance"
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
    
    @objc fileprivate func getBalanceInfo(_ gesture: UIGestureRecognizer) {
        ForageSDK.shared.checkBalance(
            bearerToken: ClientSharedData.shared.bearerToken,
            merchantAccount: ClientSharedData.shared.merchantID,
            paymentMethodReference: ClientSharedData.shared.paymentMethodReference,
            cardNumberToken: ClientSharedData.shared.cardNumberToken) { result in
                self.printPINResult(result: result)
            }
    }
    
    @objc fileprivate func goToCreatePayment(_ gesture: UIGestureRecognizer) {
        delegate?.goToCreatePayment(self)
    }
    
    // MARK: Public Methods
    
    public func render() {
        pinNumberTextField.delegate = self
        setupView()
        setupConstraints()
    }
    
    // MARK: Private Methods
    
    private func printPINResult(result: Result<Data?, Error>) {
        DispatchQueue.main.async {
            switch result {
            case .success(let data):
                guard let data = data,
                      let response = try? JSONDecoder().decode(ForageBalanceModel.self, from: data)
                else { return }
                self.snapBalanceLabel.text = "snap=\(response.snap)"
                self.nonSnapBalanceLabel.text = "nonSnap=\(response.nonSnap)"
                self.errorLabel.text = ""
                self.updateButtonState(isEnabled: true, button: self.nextButton)
            case .failure(let error):
                self.errorLabel.text = "\(error)"
                self.snapBalanceLabel.text = ""
                self.nonSnapBalanceLabel.text = ""
                self.updateButtonState(isEnabled: false, button: self.nextButton)
            }
            
            self.layoutIfNeeded()
            self.layoutSubviews()
        }
    }
    
    private func setupView() {
        self.addSubview(contentView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(pinNumberTextField)
        contentView.addSubview(statusLabel)
        contentView.addSubview(snapBalanceLabel)
        contentView.addSubview(nonSnapBalanceLabel)
        contentView.addSubview(errorLabel)
        contentView.addSubview(requestBalanceButton)
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
            padding: UIEdgeInsets(top: 24, left: 24, bottom: 0, right: 24)
        )
        
        pinNumberTextField.anchor(
            top: titleLabel.safeAreaLayoutGuide.bottomAnchor,
            leading: contentView.safeAreaLayoutGuide.leadingAnchor,
            bottom: nil,
            trailing: contentView.safeAreaLayoutGuide.trailingAnchor,
            centerXAnchor: contentView.centerXAnchor,
            padding: UIEdgeInsets(top: 24, left: 24, bottom: 0, right: 24),
            size: .init(width: 0, height: 60)
        )
        
        statusLabel.anchor(
            top: pinNumberTextField.safeAreaLayoutGuide.bottomAnchor,
            leading: contentView.safeAreaLayoutGuide.leadingAnchor,
            bottom: nil,
            trailing: contentView.safeAreaLayoutGuide.trailingAnchor,
            centerXAnchor: contentView.centerXAnchor,
            padding: UIEdgeInsets(top: 24, left: 24, bottom: 0, right: 24)
        )
        
        snapBalanceLabel.anchor(
            top: statusLabel.safeAreaLayoutGuide.bottomAnchor,
            leading: contentView.safeAreaLayoutGuide.leadingAnchor,
            bottom: nil,
            trailing: contentView.safeAreaLayoutGuide.trailingAnchor,
            centerXAnchor: contentView.centerXAnchor,
            padding: UIEdgeInsets(top: 24, left: 24, bottom: 0, right: 24)
        )
        
        nonSnapBalanceLabel.anchor(
            top: snapBalanceLabel.safeAreaLayoutGuide.bottomAnchor,
            leading: contentView.safeAreaLayoutGuide.leadingAnchor,
            bottom: nil,
            trailing: contentView.safeAreaLayoutGuide.trailingAnchor,
            centerXAnchor: contentView.centerXAnchor,
            padding: UIEdgeInsets(top: 24, left: 24, bottom: 0, right: 24)
        )
        
        errorLabel.anchor(
            top: nonSnapBalanceLabel.safeAreaLayoutGuide.bottomAnchor,
            leading: contentView.safeAreaLayoutGuide.leadingAnchor,
            bottom: nil,
            trailing: contentView.safeAreaLayoutGuide.trailingAnchor,
            centerXAnchor: contentView.centerXAnchor,
            padding: UIEdgeInsets(top: 24, left: 24, bottom: 0, right: 24)
        )
        
        requestBalanceButton.anchor(
            top: nil,
            leading: contentView.safeAreaLayoutGuide.leadingAnchor,
            bottom: nextButton.safeAreaLayoutGuide.topAnchor,
            trailing: contentView.safeAreaLayoutGuide.trailingAnchor,
            centerXAnchor: contentView.centerXAnchor,
            padding: .init(top: 0, left: 24, bottom: 8, right: 24),
            size: .init(width: 0, height: 48)
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
    
    private func updateButtonState(isEnabled: Bool, button: UIButton) {
        button.isEnabled = isEnabled
        button.isUserInteractionEnabled = isEnabled
        button.alpha = isEnabled ? 1.0 : 0.5
    }
}

// MARK: - ForagePINTextFieldDelegate

extension RequestBalanceView: ForagePINTextFieldDelegate {
    func pinStatus(_ view: UIView, isValid: Bool, pinType: PinType) {
        if isValid {
            statusLabel.text = "It is a VALID pin"
            statusLabel.textColor = .green
        } else {
            statusLabel.text = "It is a NON VALID pin"
            statusLabel.textColor = .red
        }
        updateButtonState(isEnabled: isValid, button: requestBalanceButton)
        isPINValid = isValid
    }
}
