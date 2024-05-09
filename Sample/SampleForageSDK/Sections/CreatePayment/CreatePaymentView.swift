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
    
    private let snapButtonContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let ebtCashButtonContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
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
        tf.placeholder = "SNAP amount or Payment ref"
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.borderStyle = .roundedRect
        tf.accessibilityIdentifier = "tf_snap_amount"
        tf.isAccessibilityElement = true
        return tf
    }()

    private let ebtCashTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "EBT Cash amount or Payment ref"
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.borderStyle = .roundedRect
        tf.accessibilityIdentifier = "tf_cash_amount"
        tf.isAccessibilityElement = true
        return tf
    }()

    private lazy var createSnapPaymentButton: UIButton = .createPaymentButton(
        title: "Set SNAP Amount",
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
    
    private lazy var addSnapPaymentRefButton: UIButton = .createPaymentButton(
        title: "Set SNAP Ref",
        accessibilityIdentifier: "bt_add_snap_payment_ref",
        fundingType: .ebtSnap,
        action: { [self] completion in
            addPaymentRef(
                fundingType: .ebtSnap,
                amountTextField: snapTextField,
                completion: completion
            )
        }
    )

    private lazy var createEbtCashPaymentButton: UIButton = .createPaymentButton(
        title: "Set Cash Amount",
        accessibilityIdentifier: "bt_create_cash_payment",
        fundingType: .ebtCash,
        action: { [self] completion in
            createPayment(
                fundingType: .ebtCash,
                amountTextField: ebtCashTextField,
                completion: completion
            )
        }
    )
    
    private lazy var addEbtCashPaymentRefButton: UIButton = .createPaymentButton(
        title: "Set Cash Ref",
        accessibilityIdentifier: "bt_create_cash_payment_ref",
        fundingType: .ebtCash,
        action: { [self] completion in
            addPaymentRef(
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
    
    private func addPaymentRef(fundingType: FundingType, amountTextField: UITextField, completion: @escaping () -> Void) {
        let paymentReference = amountTextField.text ?? "Unknown value"
        DispatchQueue.main.async {
            self.paymentIdentifierLabel.text = "paymentIdentifier=\(paymentReference)"
            ClientSharedData.shared.paymentReference[fundingType] = paymentReference
            
            completion()
            self.layoutIfNeeded()
            self.layoutSubviews()
        }
    }

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
        contentView.addSubview(snapButtonContainer)
        snapButtonContainer.addSubview(createSnapPaymentButton)
        snapButtonContainer.addSubview(addSnapPaymentRefButton)
        contentView.addSubview(ebtCashTextField)
        contentView.addSubview(ebtCashButtonContainer)
        ebtCashButtonContainer.addSubview(createEbtCashPaymentButton)
        ebtCashButtonContainer.addSubview(addEbtCashPaymentRefButton)
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
        let buttonSpacing: CGFloat = 10
        let collectButtonWidthMultiplier: CGFloat = 0.50 // 50%
        let captureButtonWidthMultiplier: CGFloat = 0.50 // 50%
        
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
        
        snapButtonContainer.anchor(
            top: snapTextField.bottomAnchor,
            leading: contentView.leadingAnchor,
            bottom: nil,
            trailing: contentView.trailingAnchor,
            centerXAnchor: contentView.centerXAnchor,
            padding: UIEdgeInsets(top: 12, left: 24, bottom: 0, right: 24)
        )

        NSLayoutConstraint.activate([
            addSnapPaymentRefButton.topAnchor.constraint(equalTo: snapButtonContainer.topAnchor),
            addSnapPaymentRefButton.leadingAnchor.constraint(equalTo: snapButtonContainer.leadingAnchor),
            addSnapPaymentRefButton.bottomAnchor.constraint(equalTo: snapButtonContainer.bottomAnchor),
            addSnapPaymentRefButton.heightAnchor.constraint(equalToConstant: 48),
            addSnapPaymentRefButton.widthAnchor.constraint(equalTo: snapButtonContainer.widthAnchor, multiplier: collectButtonWidthMultiplier, constant: -(buttonSpacing / 2)),
        ])

        NSLayoutConstraint.activate([
            createSnapPaymentButton.topAnchor.constraint(equalTo: snapButtonContainer.topAnchor),
            createSnapPaymentButton.leadingAnchor.constraint(equalTo: addSnapPaymentRefButton.trailingAnchor, constant: buttonSpacing),
            createSnapPaymentButton.trailingAnchor.constraint(equalTo: snapButtonContainer.trailingAnchor),
            createSnapPaymentButton.bottomAnchor.constraint(equalTo: snapButtonContainer.bottomAnchor),
            createSnapPaymentButton.heightAnchor.constraint(equalToConstant: 48),
            createSnapPaymentButton.widthAnchor.constraint(equalTo: snapButtonContainer.widthAnchor, multiplier: captureButtonWidthMultiplier, constant: -(buttonSpacing / 2)),
        ])

        ebtCashTextField.anchor(
            top: snapButtonContainer.safeAreaLayoutGuide.bottomAnchor,
            leading: contentView.safeAreaLayoutGuide.leadingAnchor,
            bottom: nil,
            trailing: contentView.safeAreaLayoutGuide.trailingAnchor,
            centerXAnchor: contentView.centerXAnchor,
            padding: UIEdgeInsets(top: 24, left: 24, bottom: 12, right: 24),
            size: .init(width: 0, height: 42)
        )
        
        ebtCashButtonContainer.anchor(
            top: ebtCashTextField.bottomAnchor,
            leading: contentView.leadingAnchor,
            bottom: nil,
            trailing: contentView.trailingAnchor,
            centerXAnchor: contentView.centerXAnchor,
            padding: UIEdgeInsets(top: 12, left: 24, bottom: 0, right: 24)
        )

        NSLayoutConstraint.activate([
            addEbtCashPaymentRefButton.topAnchor.constraint(equalTo: ebtCashButtonContainer.topAnchor),
            addEbtCashPaymentRefButton.leadingAnchor.constraint(equalTo: ebtCashButtonContainer.leadingAnchor),
            addEbtCashPaymentRefButton.bottomAnchor.constraint(equalTo: ebtCashButtonContainer.bottomAnchor),
            addEbtCashPaymentRefButton.heightAnchor.constraint(equalToConstant: 48),
            addEbtCashPaymentRefButton.widthAnchor.constraint(equalTo: ebtCashButtonContainer.widthAnchor, multiplier: collectButtonWidthMultiplier, constant: -(buttonSpacing / 2)),
        ])

        NSLayoutConstraint.activate([
            createEbtCashPaymentButton.topAnchor.constraint(equalTo: ebtCashButtonContainer.topAnchor),
            createEbtCashPaymentButton.leadingAnchor.constraint(equalTo: addEbtCashPaymentRefButton.trailingAnchor, constant: buttonSpacing),
            createEbtCashPaymentButton.trailingAnchor.constraint(equalTo: ebtCashButtonContainer.trailingAnchor),
            createEbtCashPaymentButton.bottomAnchor.constraint(equalTo: ebtCashButtonContainer.bottomAnchor),
            createEbtCashPaymentButton.heightAnchor.constraint(equalToConstant: 48),
            createEbtCashPaymentButton.widthAnchor.constraint(equalTo: ebtCashButtonContainer.widthAnchor, multiplier: captureButtonWidthMultiplier, constant: -(buttonSpacing / 2)),
        ])

        fundingTypeLabel.anchor(
            top: ebtCashButtonContainer.safeAreaLayoutGuide.bottomAnchor,
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
