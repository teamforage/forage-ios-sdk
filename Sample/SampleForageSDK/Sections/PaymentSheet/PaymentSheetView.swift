//
//  PaymentSheetView.swift
//  SampleForageSDK
//
//  Created by Danilo Joksimovic on 2023-12-07.
//  © 2022-2025 Forage Technology Corporation. All rights reserved.

import ForageSDK
import Foundation
import UIKit

class PaymentSheetView: UIView {
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.white
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "ForagePaymentSheet Flow"
        label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        label.accessibilityIdentifier = "lbl_title"
        label.isAccessibilityElement = true
        return label
    }()

    // TODO: implement
//    public let panNumberTextField: ForagePANTextField = {
//        let tf = ForagePANTextField()
//        tf.placeholder = "PAN Number"
//        tf.accessibilityIdentifier = "tf_ebt_number"
//        tf.isAccessibilityElement = true
//        return tf
//    }()

    private let firstResponderLabel: UILabel = {
        let label = UILabel()
        label.text = "isFirstResponder: false"
        label.textColor = .gray
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.accessibilityIdentifier = "lbl_first_responder"
        label.isAccessibilityElement = true
        return label
    }()

    private let completeLabel: UILabel = {
        let label = UILabel()
        label.text = "isComplete: false"
        label.textColor = .gray
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.accessibilityIdentifier = "lbl_complete"
        label.isAccessibilityElement = true
        return label
    }()

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "isEmpty: true"
        label.textColor = .gray
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.accessibilityIdentifier = "lbl_empty"
        label.isAccessibilityElement = true
        return label
    }()

    private let validLabel: UILabel = {
        let label = UILabel()
        label.text = "isValid: true"
        label.textColor = .gray
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.accessibilityIdentifier = "lbl_valid"
        label.isAccessibilityElement = true
        return label
    }()

    private let tokenizeSheetButton: UIButton = {
        let button = UIButton()
        button.setTitle("Tokenize ForagePaymentSheet", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(sendInfo(_:)), for: .touchUpInside)
        button.backgroundColor = .systemBlue
        button.isEnabled = true
        button.isUserInteractionEnabled = true
        button.alpha = 1
        button.accessibilityIdentifier = "bt_tokenize_payment_sheet"
        button.isAccessibilityElement = true
        return button
    }()

    private let refLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.numberOfLines = 0
        label.accessibilityIdentifier = "lbl_ref"
        label.isAccessibilityElement = true
        return label
    }()

    private let tokenLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.numberOfLines = 0
        label.accessibilityIdentifier = "lbl_token"
        label.isAccessibilityElement = true
        return label
    }()

    private let typeLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.numberOfLines = 0
        label.accessibilityIdentifier = "lbl_type"
        label.isAccessibilityElement = true
        return label
    }()

    private let last4Label: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.numberOfLines = 0
        label.accessibilityIdentifier = "lbl_last4"
        label.isAccessibilityElement = true
        return label
    }()

    private let customerIDLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.numberOfLines = 0
        label.accessibilityIdentifier = "lbl_customerID"
        label.isAccessibilityElement = true
        return label
    }()

    private let reusableLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.numberOfLines = 0
        label.accessibilityIdentifier = "lbl_reusable"
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

    @objc fileprivate func sendInfo(_ gesture: UIGestureRecognizer) {
        // TODO: implement
//        ForageSDK.shared.tokenizeEBTCard(
//            foragePanTextField: panNumberTextField,
//            customerID: ClientSharedData.shared.customerID,
//            reusable: ClientSharedData.shared.isReusablePaymentMethod
//        ) { result in
//            self.printResult(result: result)
//        }
    }

    // MARK: Public Methods

    public func render() {
        setupView()
        setupConstraints()
    }

    // MARK: Private Methods

    private func printResult(result: Result<PaymentMethodModel<ForageEBTCard>, Error>) {
        DispatchQueue.main.async {
            switch result {
            case let .success(response):
                self.refLabel.text = "ref=\(response.paymentMethodIdentifier)"
                self.typeLabel.text = "type=\(response.type)"
                self.tokenLabel.text = "token=\(response.card.token)"
                self.last4Label.text = "last4=\(response.card.last4)"
                self.customerIDLabel.text = "customerID=\(response.customerID ?? "NO CUST ID")"
                if let reusable = response.reusable {
                    self.reusableLabel.text = "reusable=\(String(describing: reusable))"
                } else {
                    self.reusableLabel.text = "reusable not in response"
                }
                self.errorLabel.text = ""
                ClientSharedData.shared.paymentMethodReference = response.paymentMethodIdentifier
            case let .failure(error):
                self.errorLabel.text = "error: \n\(error)"
                self.refLabel.text = ""
                self.typeLabel.text = ""
                self.tokenLabel.text = ""
                self.last4Label.text = ""
                self.customerIDLabel.text = ""
                self.reusableLabel.text = ""
            }

            self.layoutIfNeeded()
            self.layoutSubviews()
        }
    }

    private func setupView() {
        addSubview(contentView)
        contentView.addSubview(titleLabel)
        // TODO: uncomment
//        contentView.addSubview(panNumberTextField)
        contentView.addSubview(firstResponderLabel)
        contentView.addSubview(completeLabel)
        contentView.addSubview(emptyLabel)
        contentView.addSubview(validLabel)
        contentView.addSubview(refLabel)
        contentView.addSubview(typeLabel)
        contentView.addSubview(tokenLabel)
        contentView.addSubview(last4Label)
        contentView.addSubview(customerIDLabel)
        contentView.addSubview(reusableLabel)
        contentView.addSubview(errorLabel)
        contentView.addSubview(tokenizeSheetButton)
    }

    private func setupConstraints() {
        setupContentViewConstraints()
//        completeLabel.text = "isComplete: \(foragePaymentSheet.isComplete)"
    }

    private func setupContentViewConstraints() {
        contentView.anchor(
            top: topAnchor,
            leading: leadingAnchor,
            bottom: bottomAnchor,
            trailing: trailingAnchor,
            centerXAnchor: centerXAnchor
        )

        titleLabel.anchor(
            top: contentView.safeAreaLayoutGuide.topAnchor,
            leading: contentView.safeAreaLayoutGuide.leadingAnchor,
            bottom: nil,
            trailing: contentView.safeAreaLayoutGuide.trailingAnchor,
            centerXAnchor: contentView.centerXAnchor,
            padding: UIEdgeInsets(top: 24, left: 24, bottom: 0, right: 24)
        )

        // TODO: anchor foragePaymentSheet
//        panNumberTextField.anchor(
//            top: titleLabel.safeAreaLayoutGuide.bottomAnchor,
//            leading: contentView.safeAreaLayoutGuide.leadingAnchor,
//            bottom: nil,
//            trailing: contentView.safeAreaLayoutGuide.trailingAnchor,
//            centerXAnchor: contentView.centerXAnchor,
//            padding: UIEdgeInsets(top: 24, left: 24, bottom: 0, right: 24)
//        )

        // TODO: update this constraint
        completeLabel.anchor(
            top: titleLabel.safeAreaLayoutGuide.bottomAnchor,
            leading: contentView.safeAreaLayoutGuide.leadingAnchor,
            bottom: nil,
            trailing: contentView.safeAreaLayoutGuide.trailingAnchor,
            centerXAnchor: contentView.centerXAnchor,
            padding: UIEdgeInsets(top: 24, left: 24, bottom: 0, right: 24)
        )

        emptyLabel.anchor(
            top: completeLabel.safeAreaLayoutGuide.bottomAnchor,
            leading: contentView.safeAreaLayoutGuide.leadingAnchor,
            bottom: nil,
            trailing: contentView.safeAreaLayoutGuide.trailingAnchor,
            centerXAnchor: contentView.centerXAnchor,
            padding: UIEdgeInsets(top: 24, left: 24, bottom: 0, right: 24)
        )

        refLabel.anchor(
            top: validLabel.safeAreaLayoutGuide.bottomAnchor,
            leading: contentView.safeAreaLayoutGuide.leadingAnchor,
            bottom: nil,
            trailing: contentView.safeAreaLayoutGuide.trailingAnchor,
            centerXAnchor: contentView.centerXAnchor,
            padding: UIEdgeInsets(top: 24, left: 24, bottom: 0, right: 24)
        )

        typeLabel.anchor(
            top: refLabel.safeAreaLayoutGuide.bottomAnchor,
            leading: contentView.safeAreaLayoutGuide.leadingAnchor,
            bottom: nil,
            trailing: contentView.safeAreaLayoutGuide.trailingAnchor,
            centerXAnchor: contentView.centerXAnchor,
            padding: UIEdgeInsets(top: 24, left: 24, bottom: 0, right: 24)
        )

        tokenLabel.anchor(
            top: typeLabel.safeAreaLayoutGuide.bottomAnchor,
            leading: contentView.safeAreaLayoutGuide.leadingAnchor,
            bottom: nil,
            trailing: contentView.safeAreaLayoutGuide.trailingAnchor,
            centerXAnchor: contentView.centerXAnchor,
            padding: UIEdgeInsets(top: 24, left: 24, bottom: 0, right: 24)
        )

        last4Label.anchor(
            top: tokenLabel.safeAreaLayoutGuide.bottomAnchor,
            leading: contentView.safeAreaLayoutGuide.leadingAnchor,
            bottom: nil,
            trailing: contentView.safeAreaLayoutGuide.trailingAnchor,
            centerXAnchor: contentView.centerXAnchor,
            padding: UIEdgeInsets(top: 24, left: 24, bottom: 0, right: 24)
        )

        customerIDLabel.anchor(
            top: last4Label.safeAreaLayoutGuide.bottomAnchor,
            leading: contentView.safeAreaLayoutGuide.leadingAnchor,
            bottom: nil,
            trailing: contentView.safeAreaLayoutGuide.trailingAnchor,
            centerXAnchor: contentView.centerXAnchor,
            padding: UIEdgeInsets(top: 24, left: 24, bottom: 0, right: 24)
        )

        reusableLabel.anchor(
            top: customerIDLabel.safeAreaLayoutGuide.bottomAnchor,
            leading: contentView.safeAreaLayoutGuide.leadingAnchor,
            bottom: nil,
            trailing: contentView.safeAreaLayoutGuide.trailingAnchor,
            centerXAnchor: contentView.centerXAnchor,
            padding: UIEdgeInsets(top: 24, left: 24, bottom: 0, right: 24)
        )

        errorLabel.anchor(
            top: reusableLabel.safeAreaLayoutGuide.bottomAnchor,
            leading: contentView.safeAreaLayoutGuide.leadingAnchor,
            bottom: nil,
            trailing: contentView.safeAreaLayoutGuide.trailingAnchor,
            centerXAnchor: contentView.centerXAnchor,
            padding: UIEdgeInsets(top: 24, left: 24, bottom: 0, right: 24)
        )

        tokenizeSheetButton.anchor(
            top: nil,
            leading: contentView.safeAreaLayoutGuide.leadingAnchor,
            bottom: contentView.safeAreaLayoutGuide.bottomAnchor,
            trailing: contentView.safeAreaLayoutGuide.trailingAnchor,
            centerXAnchor: contentView.centerXAnchor,
            padding: .init(top: 0, left: 24, bottom: 8, right: 24),
            size: .init(width: 0, height: 48)
        )
    }

    private func updateButtonState(isEnabled: Bool, button: UIButton) {
        button.isEnabled = isEnabled
        button.isUserInteractionEnabled = isEnabled
        button.alpha = isEnabled ? 1.0 : 0.5
    }

    private func updateState(state: ObservableState) {
        firstResponderLabel.text = "isFirstResponder: \(state.isFirstResponder)"
        completeLabel.text = "isComplete: \(state.isComplete)"
    }
}

// MARK: - ForagePANTextFieldDelegate

extension PaymentSheetView: ForageElementDelegate {
    func focusDidChange(_ state: ObservableState) {
        updateState(state: state)
    }

    func textFieldDidChange(_ state: ObservableState) {
        updateState(state: state)
    }
}
