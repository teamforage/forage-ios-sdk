//
//  HSAView.swift
//  SampleForageSDK
//
//  Created by Jerimiah on 2/27/25.
//  © 2025 Forage Technology Corporation. All rights reserved.
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
    
    public let forageHSAPaymentSheet: ForagePaymentSheet = {
        let ps = ForagePaymentSheet()
        
        // set paymentType on the sheet
        ps.paymentType = .HSAFSA
        
        // set defaults on payment sheet that will cascade to all fields
        ps.borderWidth = 2.0
        ps.borderColor = UIColor(red: 0.01, green: 0.26, blue: 0.19, alpha: 1.0)
        ps.cornerRadius = 4.0
        ps.elementHeight = 52
        
        // set field specific styles
        ps.cardExpirationTextField.cornerRadius = 6.0
        ps.cardCVVTextField.cornerRadius = 6.0
        
        // Set field accessibility settings
        ps.cardHolderNameTextField.placeholder = "Card holder name"
        ps.cardHolderNameTextField.accessibilityIdentifier = "tf_paymentsheet_cardholderName"
        ps.cardHolderNameTextField.isAccessibilityElement = true
        
        ps.cardNumberTextField.placeholder = "Card number"
        ps.cardNumberTextField.accessibilityIdentifier = "tf_paymentsheet_cardNumber"
        ps.cardNumberTextField.isAccessibilityElement = true
        
        ps.cardExpirationTextField.placeholder = "Expiration (MM/YY)"
        ps.cardExpirationTextField.accessibilityIdentifier = "tf_paymentsheet_expiration"
        ps.cardExpirationTextField.isAccessibilityElement = true
        
        ps.cardCVVTextField.placeholder = "Security code"
        ps.cardCVVTextField.accessibilityIdentifier = "tf_paymentsheet_security_code"
        ps.cardCVVTextField.isAccessibilityElement = true
        
        ps.cardZipCodeTextField.placeholder = "Zip code"
        ps.cardZipCodeTextField.accessibilityIdentifier = "tf_paymentsheet_zip_code"
        ps.cardZipCodeTextField.isAccessibilityElement = true
        
        // set custom field names to identify the field as currentFirstResponder or completionErrors map
        ps.cardHolderNameTextField.name = "cardName"
        ps.cardNumberTextField.name = "cardNumber"
        ps.cardExpirationTextField.name = "cardExp"
        ps.cardCVVTextField.name = "cardCVV"
        ps.cardZipCodeTextField.name = "cardZip"
        
        return ps
    }()

    // ObservableState labels
    private var completeLabel: UILabel = .create(id: "lbl_complete", text: "isComplete: false")
    private var currentFirstResponderLabel: UILabel = .create(id: "lbl_first_responder", text: "currentFirstResponder: ")
    private var completionErrorsLabel: UILabel = .create(id: "lbl_completion_errors", text: "completionErrors: []")

    // Result labels
    private var refLabel: UILabel = .create(id: "lbl_ref")
    private var typeLabel: UILabel = .create(id: "lbl_type")
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
    
    @objc fileprivate func sendInfo(_ gesture: UIGestureRecognizer) {
        tokenizeCardButton.showLoading()
        ForageSDK.shared.tokenizeCreditDebitCard(
            foragePaymentSheet: forageHSAPaymentSheet,
            customerID: ClientSharedData.shared.customerID,
            reusable: ClientSharedData.shared.isReusablePaymentMethod
        ) { [self] result in
            tokenizeCardButton.hideLoading()
            printResult(result: result)
        }
    }

    // MARK: Public Methods

    public func render() {
        // TODO: set delegate to ForageHSAForm
        forageHSAPaymentSheet.delegate = self
        setupView()
        setupConstraints()
    }

    // MARK: Private Methods
    
    private func printResult(result: Result<PaymentMethodModel<ForageCreditDebitCard>, Error>) {
        DispatchQueue.main.async {
            switch result {
            case let .success(response):
                self.refLabel.text = "ref=\(response.paymentMethodIdentifier)"
                self.typeLabel.text = "type=\(response.type)"
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
        completionErrorsLabel.text = "completionErrors: \(forageHSAPaymentSheet.completionErrors)"
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

    private func updateState(state: PaymentSheetObservableState) {
        // loop through fields and highlight fields with errors that are not in Focus
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
    func sheetFocusDidChange(_ state: any PaymentSheetObservableState) {
        updateState(state: state)
    }
    
    func sheetTextFieldDidChange(_ state: any PaymentSheetObservableState) {
        updateState(state: state)
    }
}
