//
//  CreatePaymentView.swift
//  SampleForageSDK
//
//  Created by Tiago Oliveira on 25/10/22.
//  Copyright © 2022-Present Forage Technology Corporation. All rights reserved.
//

import ForageSDK
import Foundation
import UIKit

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
        label.text = "Create Payments"
        label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        label.accessibilityIdentifier = "lbl_title"
        label.isAccessibilityElement = true
        return label
    }()

    private let snapTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "SNAP amount"
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.borderStyle = .roundedRect
        tf.accessibilityIdentifier = "tf_snap_amount"
        tf.isAccessibilityElement = true
        return tf
    }()

    private let ebtCashTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "EBT Cash amount"
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.borderStyle = .roundedRect
        tf.accessibilityIdentifier = "tf_non_snap_amount"
        tf.isAccessibilityElement = true
        return tf
    }()

    private lazy var createSnapPaymentButton: UIButton = .createPaymentButton(
        title: "Create SNAP Payment",
        accessibilityIdentifier: "bt_create_snap_payment",
        fundingType: .ebtSnap,
        action: { [self] completion in
            createPayment(
                fundingType: .ebtSnap,
                amountTextField: snapTextField,
                completion: completion
            )
        }
    )

    private lazy var createEbtCashPaymentButton: UIButton = .createPaymentButton(
        title: "Create EBT Cash Payment",
        accessibilityIdentifier: "bt_create_non_snap_payment",
        fundingType: .ebtCash,
        action: { [self] completion in
            createPayment(
                fundingType: .ebtCash,
                amountTextField: ebtCashTextField,
                completion: completion
            )
        }
    )

    private let nextButton: UIButton = .createNextButton(self, action: #selector(goToCapture(_:)))

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

    private let merchantIDLabel: UILabel = {
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

    @objc fileprivate func goToCapture(_ gesture: UIGestureRecognizer) {
        delegate?.goToCapture(self)
    }

    // MARK: Public Methods

    public func render() {
        setupView()
        setupConstraints()
    }

    // MARK: Private Methods

    private func createPayment(fundingType: FundingType, amountTextField: UITextField, completion: @escaping () -> Void) {
        var paymentAmount = 0.0

        guard
            let stringAmount = amountTextField.text,
            let amount = Double(stringAmount)
        else { return }
        paymentAmount = amount

        let request = CreatePaymentRequest(
            amount: paymentAmount,
            fundingType: fundingType.rawValue,
            paymentMethodIdentifier: ClientSharedData.shared.paymentMethodReference,
            merchantID: ClientSharedData.shared.merchantID,
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
            isDelivery: false,
            customerID: ClientSharedData.shared.customerID
        )

        controller.createPayment(request: request) { result in
            self.printResult(result: result, completion: completion)
        }
    }

    private func printResult(result: Result<CreatePaymentResponse, Error>, completion: @escaping () -> Void) {
        DispatchQueue.main.async {
            switch result {
            case let .success(response):
                self.fundingTypeLabel.text = "fundingType=\(response.fundingType.rawValue)"
                self.paymentMethodIdentifierLabel.text = "paymentMethodIdentifier=\(response.paymentMethodIdentifier)"
                self.paymentIdentifierLabel.text = "paymentIdentifier=\(response.paymentIdentifier)"
                self.merchantIDLabel.text = "merchantID=\(response.merchantID)"
                self.amountLabel.text = "amount=\(response.amount)"
                self.errorLabel.text = ""
                ClientSharedData.shared.paymentReference[response.fundingType] = response.paymentIdentifier

            case let .failure(error):
                self.errorLabel.text = "error: \n\(error.localizedDescription)"
                self.fundingTypeLabel.text = ""
                self.paymentMethodIdentifierLabel.text = ""
                self.paymentIdentifierLabel.text = ""
                self.merchantIDLabel.text = ""
                self.amountLabel.text = ""
            }

            completion()
            self.layoutIfNeeded()
            self.layoutSubviews()
        }
    }

    private func setupView() {
        addSubview(contentView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(snapTextField)
        contentView.addSubview(createSnapPaymentButton)
        contentView.addSubview(ebtCashTextField)
        contentView.addSubview(createEbtCashPaymentButton)
        contentView.addSubview(fundingTypeLabel)
        contentView.addSubview(paymentMethodIdentifierLabel)
        contentView.addSubview(paymentIdentifierLabel)
        contentView.addSubview(merchantIDLabel)
        contentView.addSubview(amountLabel)
        contentView.addSubview(errorLabel)
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

        ebtCashTextField.anchor(
            top: createSnapPaymentButton.safeAreaLayoutGuide.bottomAnchor,
            leading: contentView.safeAreaLayoutGuide.leadingAnchor,
            bottom: nil,
            trailing: contentView.safeAreaLayoutGuide.trailingAnchor,
            centerXAnchor: contentView.centerXAnchor,
            padding: UIEdgeInsets(top: 24, left: 24, bottom: 12, right: 24),
            size: .init(width: 0, height: 42)
        )

        createEbtCashPaymentButton.anchor(
            top: ebtCashTextField.safeAreaLayoutGuide.bottomAnchor,
            leading: contentView.safeAreaLayoutGuide.leadingAnchor,
            bottom: nil,
            trailing: contentView.safeAreaLayoutGuide.trailingAnchor,
            centerXAnchor: contentView.centerXAnchor,
            padding: .init(top: 12, left: 24, bottom: 0, right: 24),
            size: .init(width: 0, height: 48)
        )

        fundingTypeLabel.anchor(
            top: createEbtCashPaymentButton.safeAreaLayoutGuide.bottomAnchor,
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

        merchantIDLabel.anchor(
            top: paymentIdentifierLabel.safeAreaLayoutGuide.bottomAnchor,
            leading: contentView.safeAreaLayoutGuide.leadingAnchor,
            bottom: nil,
            trailing: contentView.safeAreaLayoutGuide.trailingAnchor,
            centerXAnchor: contentView.centerXAnchor,
            padding: UIEdgeInsets(top: 24, left: 24, bottom: 0, right: 24)
        )

        amountLabel.anchor(
            top: merchantIDLabel.safeAreaLayoutGuide.bottomAnchor,
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
