//
//  CardNumberView.swift
//  SampleForageSDK
//
//  Created by Tiago Oliveira on 18/10/22.
//  Copyright © 2022-Present Forage Technology Corporation. All rights reserved.
//

import ForageSDK
import Foundation
import UIKit

protocol CardNumberViewDelegate: AnyObject {
    func goToBalance(_ view: CardNumberView)
}

class CardNumberView: BaseSampleView {
    // MARK: Public Properties

    weak var delegate: CardNumberViewDelegate?

    // MARK: Private Components

    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.white
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Tokenize EBT Card"
        label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        label.accessibilityIdentifier = "lbl_title"
        label.isAccessibilityElement = true
        return label
    }()

    public let foragePanTextField: ForagePANTextField = {
        let tf = ForagePANTextField()

        tf.placeholder = "Primary Account Number (PAN)"
        tf.borderColor = UIColor(red: 0.01, green: 0.26, blue: 0.19, alpha: 1.0)
        tf.borderWidth = 2.0
        tf.cornerRadius = 4.0
        tf.clearButtonMode = .whileEditing

        // Setting height of TextField to 52.
        // Height of 'powered by Forage' is 16 and spacing is 8
        let heightAnchor = tf.heightAnchor.constraint(equalToConstant: 76)
        heightAnchor.priority = UILayoutPriority.required
        heightAnchor.isActive = true

        tf.accessibilityIdentifier = "tf_ebt_number"
        tf.isAccessibilityElement = true

        return tf
    }()

    // ObservableState labels
    private var firstResponderLabel: UILabel = .create(id: "lbl_first_responder")
    private var completeLabel: UILabel = .create(id: "lbl_complete", text: "isComplete: false")
    private var emptyLabel: UILabel = .create(id: "lbl_empty", text: "isEmpty: true")
    private var validLabel: UILabel = .create(id: "lbl_valid", text: "isValid: true")

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
        button.setTitle("Tokenize EBT Card", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(sendInfo(_:)), for: .touchUpInside)
        button.backgroundColor = .primaryColor
        button.isEnabled = true
        button.isUserInteractionEnabled = true
        button.alpha = 1
        button.accessibilityIdentifier = "bt_send_ebt_number"
        button.isAccessibilityElement = true
        return button
    }()

    private let nextButton: UIButton = .createNextButton(self, action: #selector(goToBalance(_:)))

    // MARK: Fileprivate Methods

    @objc fileprivate func sendInfo(_ gesture: UIGestureRecognizer) {
        tokenizeCardButton.showLoading()
        ForageSDK.shared.tokenizeEBTCard(
            foragePanTextField: foragePanTextField,
            customerID: ClientSharedData.shared.customerID,
            reusable: ClientSharedData.shared.isReusablePaymentMethod
        ) { [self] result in
            tokenizeCardButton.hideLoading()
            printResult(result: result)
        }
    }

    @objc fileprivate func goToBalance(_ gesture: UIGestureRecognizer) {
        delegate?.goToBalance(self)
    }

    // MARK: Public Methods

    public func render() {
        foragePanTextField.delegate = self
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
                self.updateButtonState(isEnabled: true, button: self.nextButton)
            case let .failure(error):
                self.logForageError(error)
                self.errorLabel.text = "error: \n\(error)"
                self.refLabel.text = ""
                self.typeLabel.text = ""
                self.tokenLabel.text = ""
                self.last4Label.text = ""
                self.customerIDLabel.text = ""
                self.reusableLabel.text = ""
                self.updateButtonState(isEnabled: false, button: self.nextButton)
            }

            self.layoutIfNeeded()
            self.layoutSubviews()
        }
    }

    private func setupView() {
        addSubview(contentView)

        contentView.addSubview(titleLabel)
        contentView.addSubview(foragePanTextField)
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
        contentView.addSubview(tokenizeCardButton)
        contentView.addSubview(nextButton)
    }

    private func setupConstraints() {
        setupContentViewConstraints()
        firstResponderLabel.text = "isFirstResponder: \(foragePanTextField.isFirstResponder)"
        completeLabel.text = "isComplete: \(foragePanTextField.isComplete)"
        emptyLabel.text = "isEmpty: \(foragePanTextField.isEmpty)"
        validLabel.text = "isValid: \(foragePanTextField.isValid)"
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
            foragePanTextField,
            firstResponderLabel,
            completeLabel,
            emptyLabel,
            validLabel,
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

    private func updateState(state: ObservableState) {
        firstResponderLabel.text = "isFirstResponder: \(state.isFirstResponder)"
        completeLabel.text = "isComplete: \(state.isComplete)"
        emptyLabel.text = "isEmpty: \(state.isEmpty)"
        validLabel.text = "isValid: \(state.isValid)"
    }
}

// MARK: - ForagePANTextFieldDelegate

extension CardNumberView: ForageElementDelegate {
    func focusDidChange(_ state: ObservableState) {
        updateState(state: state)
    }

    func textFieldDidChange(_ state: ObservableState) {
        updateState(state: state)
    }
}
