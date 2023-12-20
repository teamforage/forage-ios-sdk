//
//  RequestBalanceView.swift
//  SampleForageSDK
//
//  Created by Tiago Oliveira on 24/10/22.
//  Copyright © 2022-Present Forage Technology Corporation. All rights reserved.
//

import ForageSDK
import Foundation
import UIKit

protocol RequestBalanceViewDelegate: AnyObject {
    func goToCreatePayment(_ view: RequestBalanceView)
}

class RequestBalanceView: BaseSampleView {
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

    public let foragePinTextField: ForagePINTextField = {
        let tf = ForagePINTextField()
        tf.placeholder = "PIN Field"
        tf.accessibilityIdentifier = "tf_pin_balance"
        tf.isAccessibilityElement = true
        tf.borderWidth = 2.0
        tf.borderColor = UIColor(red: 0.01, green: 0.26, blue: 0.19, alpha: 1.0)
        tf.font = .systemFont(ofSize: 18)
        let height = tf.heightAnchor.constraint(equalToConstant: 84)
        height.priority = UILayoutPriority.defaultHigh + 10
        height.isActive = true
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
        button.isEnabled = true
        button.isUserInteractionEnabled = true
        button.alpha = 1.0
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
        button.isEnabled = true
        button.isUserInteractionEnabled = true
        button.alpha = 1.0
        button.accessibilityIdentifier = "bt_next"
        button.isAccessibilityElement = true
        return button
    }()

    private let isFirstResponderLabel: UILabel = {
        let label = UILabel()
        label.text = "isFirstResponder: false"
        label.textColor = .red
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.accessibilityIdentifier = "lbl_first_responder"
        label.isAccessibilityElement = true
        return label
    }()

    private let isEmptyLabel: UILabel = {
        let label = UILabel()
        label.text = "isEmpty: true"
        label.textColor = .red
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.accessibilityIdentifier = "lbl_empty"
        label.isAccessibilityElement = true
        return label
    }()

    private let isValidLabel: UILabel = {
        let label = UILabel()
        label.text = "isValid: false"
        label.textColor = .red
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.accessibilityIdentifier = "lbl_valid"
        label.isAccessibilityElement = true
        return label
    }()

    private let isCompleteLabel: UILabel = {
        let label = UILabel()
        label.text = "isComplete: false"
        label.textColor = .red
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.accessibilityIdentifier = "lbl_complete"
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

    private let ebtCashBalanceLabel: UILabel = {
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
        DispatchQueue.global(qos: .userInitiated).async {
            ForageSDK.shared.checkBalance(
                foragePinTextField: self.foragePinTextField,
                paymentMethodReference: ClientSharedData.shared.paymentMethodReference
            ) { result in
                self.foragePinTextField.clearText()
                self.printPINResult(result: result)
            }
        }
    }

    @objc fileprivate func goToCreatePayment(_ gesture: UIGestureRecognizer) {
        delegate?.goToCreatePayment(self)
    }

    // MARK: Public Methods

    public func render() {
        foragePinTextField.delegate = self
        setupView()
        setupConstraints()
    }

    // MARK: Private Methods

    private func printPINResult(result: Result<BalanceModel, Error>) {
        DispatchQueue.main.async {
            switch result {
            case let .success(response):
                self.snapBalanceLabel.text = "snap=\(response.snap)"
                self.ebtCashBalanceLabel.text = "cash=\(response.cash)"
                self.errorLabel.text = ""
            case let .failure(error):
                self.errorLabel.text = "\(error)"
                self.snapBalanceLabel.text = ""
                self.ebtCashBalanceLabel.text = ""
            }

            self.layoutIfNeeded()
            self.layoutSubviews()
        }
    }

    private func setupView() {
        addSubview(contentView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(foragePinTextField)
        contentView.addSubview(isFirstResponderLabel)
        contentView.addSubview(isEmptyLabel)
        contentView.addSubview(isValidLabel)
        contentView.addSubview(isCompleteLabel)
        contentView.addSubview(snapBalanceLabel)
        contentView.addSubview(ebtCashBalanceLabel)
        contentView.addSubview(errorLabel)
        contentView.addSubview(requestBalanceButton)
        contentView.addSubview(nextButton)
    }

    private func setupConstraints() {
        setupContentViewConstraints()
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
            foragePinTextField,
            isFirstResponderLabel,
            isEmptyLabel,
            isValidLabel,
            isCompleteLabel,
            snapBalanceLabel,
            ebtCashBalanceLabel,
            errorLabel,
        ])

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

    private func updateState(state: ObservableState) {
        isEmptyLabel.text = "isEmpty: \(state.isEmpty)"
        isCompleteLabel.text = "isComplete: \(state.isComplete)"
        isValidLabel.text = "isValid: \(state.isValid)"
        isFirstResponderLabel.text = "isFirstResponder: \(state.isFirstResponder)"
    }
}

// MARK: - ForageElementDelegate

extension RequestBalanceView: ForageElementDelegate {
    func focusDidChange(_ state: ObservableState) {
        updateState(state: state)
    }

    func textFieldDidChange(_ state: ObservableState) {
        updateState(state: state)
    }
}
