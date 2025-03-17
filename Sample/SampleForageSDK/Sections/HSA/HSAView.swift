//
//  HSAView.swift
//  SampleForageSDK
//
//  Created by Jerimiah on 2/27/25.
//  Copyright © 2025-Present Forage Technology Corporation. All rights reserved.
//

import ForageSDK
import Foundation
import UIKit

class HSAView: BaseSampleView {
    // MARK: Private Components

    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.white
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "HSA / FSA Form"
        label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        label.accessibilityIdentifier = "lbl_title"
        label.isAccessibilityElement = true
        return label
    }()
    
    // set defaults on payment sheet
    public let forageHSAPaymentSheet: ForagePaymentSheet = {
        let ps = ForagePaymentSheet()
        
        ps.borderWidth = 2.0
        ps.borderColor = UIColor(red: 0.01, green: 0.26, blue: 0.19, alpha: 1.0)
        ps.cornerRadius = 4.0
        ps.elementHeight = 52
        
        ps.cardHolderNameTextField.placeholder = "Card holder name"
        ps.cardHolderNameTextField.accessibilityIdentifier = "tf_paymentsheet_cardholderName"
        ps.cardHolderNameTextField.isAccessibilityElement = true
        
        ps.cardNumberTextField.placeholder = "Card number"
        ps.cardNumberTextField.accessibilityIdentifier = "tf_paymentsheet_cardNumber"
        ps.cardNumberTextField.isAccessibilityElement = true
        ps.cardExpirationTextField.placeholder = "Expiration (MM/YY)"
        ps.cardCVVTextField.placeholder = "Security code"
        ps.cardZipCodeTextField.placeholder = "Zip code"
        
        return ps
    }()

    // ObservableState labels
    private var completeLabel: UILabel = .create(id: "lbl_complete", text: "isComplete: false")
    private var currentFirstResponderLabel: UILabel = .create(id: "lbl_first_responder", text: "currentFirstResponder: ")
    private var completionErrorsLabel: UILabel = .create(id: "lbl_completion_errors", text: "completionErrors: []")

    // Result labels
    private var refLabel: UILabel = .create(id: "lbl_ref")
    private var typeLabel: UILabel = .create(id: "lbl_type")
    private var tokenLabel: UILabel = .create(id: "lbl_token")
    private var last4Label: UILabel = .create(id: "lbl_last4")
    private var customerIDLabel: UILabel = .create(id: "lbl_customerID")
    private var reusableLabel: UILabel = .create(id: "lbl_reusable")
    private var errorLabel: UILabel = .create(id: "lbl_error")

    private let tokenizeCardButton: LoadingButton = {
        let button = LoadingButton()
        button.setTitle("Tokenize Card Data", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(sendInfo(_:)), for: .touchUpInside)
        button.backgroundColor = .primaryColor
        button.isEnabled = true
        button.isUserInteractionEnabled = true
        button.alpha = 1
        button.accessibilityIdentifier = "bt_send_hsa_fsa_data"
        button.isAccessibilityElement = true
        return button
    }()

    // MARK: Fileprivate Methods

    @objc fileprivate func sendInfo(_ gesture: UIGestureRecognizer) {
//        tokenizeCardButton.showLoading()
//        ForageSDK.shared.tokenizeEBTCard(
//            foragePanTextField: foragePanTextField,
//            customerID: ClientSharedData.shared.customerID,
//            reusable: ClientSharedData.shared.isReusablePaymentMethod
//        ) { [self] result in
//            tokenizeCardButton.hideLoading()
//            printResult(result: result)
//        }
    }

    // MARK: Public Methods

    public func render() {
        // TODO: set delegate to ForageHSAForm
        forageHSAPaymentSheet.delegate = self
        setupView()
        setupConstraints()
    }

    // MARK: Private Methods

    private func printResult(result: Result<PaymentMethodModel, Error>) {
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
                self.logForageError(error)
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
        contentView.addSubview(forageHSAPaymentSheet)
        contentView.addSubview(currentFirstResponderLabel)
        contentView.addSubview(completeLabel)
        contentView.addSubview(completionErrorsLabel)
        contentView.addSubview(refLabel)
        contentView.addSubview(typeLabel)
        contentView.addSubview(tokenLabel)
        contentView.addSubview(last4Label)
        contentView.addSubview(customerIDLabel)
        contentView.addSubview(reusableLabel)
        contentView.addSubview(errorLabel)
        contentView.addSubview(tokenizeCardButton)
    }

    private func setupConstraints() {
        setupContentViewConstraints()
        currentFirstResponderLabel.text = "currentFirstResponder: \(forageHSAPaymentSheet.currentFirstResponder?.name ?? "")"
        completeLabel.text = "isComplete: \(forageHSAPaymentSheet.isComplete)"
        completeLabel.text = "completionErrors: \(forageHSAPaymentSheet.completionErrors)"
    }

    private func setupContentViewConstraints() {
        contentView.anchor(
            top: topAnchor,
            leading: leadingAnchor,
            bottom: bottomAnchor,
            trailing: trailingAnchor,
            centerXAnchor: centerXAnchor
        )

        anchorContentViewSubviews(contentView: contentView, subviews: [
            titleLabel,
            forageHSAPaymentSheet,
            currentFirstResponderLabel,
            completeLabel,
            completionErrorsLabel,
            refLabel,
            typeLabel,
            tokenLabel,
            last4Label,
            customerIDLabel,
            reusableLabel,
            errorLabel,
        ])

        tokenizeCardButton.anchor(
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

    private func updateState(state: PaymentSheetObservableState) {
        // TODO: determine best way to expose the state on all of the fields
        // TODO: is it better to expose the fields and by proxy expose the state on each or better to have a sheet level object
        // TODO: tbh I think it's probably better to expose the list fields and then allow them to edit their state easily with access to the
        for var field in forageHSAPaymentSheet.fields {
            if !field.isValid && !field.isFirstResponder && field.isDirty {
                field.borderColor = UIColor(red: 0.60, green: 0.26, blue: 0.19, alpha: 1.0)
            } else {
                field.borderColor = UIColor(red: 0.01, green: 0.26, blue: 0.19, alpha: 1.0)
            }
        }
        
        currentFirstResponderLabel.text = "currentFirstResponder: \(state.currentFirstResponder?.name ?? "")"
        completeLabel.text = "isComplete: \(state.isComplete)"
        completionErrorsLabel.text = "completionErrors: \(state.completionErrors)"
    }
}

// MARK: - ForagePaymentSheetDelegate

extension HSAView: ForagePaymentSheetElementDelegate {
    func sheetDidChange(_ state: PaymentSheetObservableState) {
        updateState(state: state)
    }
}
