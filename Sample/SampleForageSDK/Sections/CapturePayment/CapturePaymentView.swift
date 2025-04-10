//
//  CapturePaymentView.swift
//  SampleForageSDK
//
//  Created by Tiago Oliveira on 26/10/22.
//  © 2022-Present Forage Technology Corporation. All rights reserved.
//

import ForageSDK
import Foundation
import UIKit

class CapturePaymentView: BaseSampleView {
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
        label.text = "Capture Payments"
        label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        label.accessibilityIdentifier = "lbl_title"
        label.isAccessibilityElement = true
        return label
    }()

    public let snapTextField: ForagePINTextField = {
        let tf = ForagePINTextField()
        tf.accessibilityIdentifier = "tf_pin_snap"
        tf.isAccessibilityElement = true
        return tf
    }()

    private let ebtCashTextField: ForagePINTextField = {
        let tf = ForagePINTextField()
        tf.accessibilityIdentifier = "tf_pin_cash"
        tf.isAccessibilityElement = true
        return tf
    }()

    /// Set accessibilityIdentifier for all of the elements, used by mobile-qa-tests service.
    private let deferPaymentCaptureResponseLabel: UILabel = .create(id: "lbl_defer_capture_response")
    private let statusTypeLabel: UILabel = .create(id: "lbl_status_type")
    private let statusLabel: UILabel = .create(id: "lbl_status")
    private let paymentRefLabel: UILabel = .create(id: "lbl_payment_ref")
    private let fundingTypeLabel: UILabel = .create(id: "lbl_funding_type")
    private let amountLabel: UILabel = .create(id: "lbl_amount")
    private let errorLabel: UILabel = .create(id: "lbl_error")
    private let remainingBalanceLabel: UILabel = .create(id: "lbl_remaining_balance")

    private let snapHeadingLabel: UILabel = {
        let lbl = UILabel.create(id: "lbl_snap_heading")
        lbl.text = "SNAP PIN"
        lbl.font = .systemFont(ofSize: 20)
        return lbl
    }()

    private let ebtCashHeadingLabel: UILabel = {
        let lbl = UILabel.create(id: "lbl_ebt_cash_heading")
        lbl.text = "EBT Cash PIN"
        lbl.font = .systemFont(ofSize: 20)
        return lbl
    }()

    // MARK: Fileprivate Methods

    private func createSubmitButton(
        title: String,
        accessibilityIdentifier: String,
        fundingType: FundingType,
        pinTextField: ForagePINTextField,
        submitMethod: @escaping (ForagePINTextField, String, @escaping () -> Void) -> Void
    ) -> UIButton {
        .createPaymentButton(
            title: title,
            accessibilityIdentifier: accessibilityIdentifier,
            fundingType: fundingType,
            action: { completion in
                let paymentReference = ClientSharedData.shared.paymentReference[fundingType] ?? ""
                submitMethod(pinTextField, paymentReference, completion)
            }
        )
    }

    private lazy var collectSnapPinButton: UIButton = createSubmitButton(
        title: "Defer SNAP",
        accessibilityIdentifier: "bt_defer_capture_snap",
        fundingType: .ebtSnap,
        pinTextField: snapTextField,
        submitMethod: deferPaymentCapture
    )

    private lazy var captureSnapButton: UIButton = createSubmitButton(
        title: "Capture SNAP",
        accessibilityIdentifier: "bt_capture_snap_payment",
        fundingType: .ebtSnap,
        pinTextField: snapTextField,
        submitMethod: capturePayment
    )

    private lazy var collectEbtCashPinButton: UIButton = createSubmitButton(
        title: "Defer EBT Cash",
        accessibilityIdentifier: "bt_defer_capture_cash",
        fundingType: .ebtCash,
        pinTextField: ebtCashTextField,
        submitMethod: deferPaymentCapture
    )

    private lazy var captureEbtCashButton: UIButton = createSubmitButton(
        title: "Capture EBT Cash",
        accessibilityIdentifier: "bt_capture_cash_payment",
        fundingType: .ebtCash,
        pinTextField: ebtCashTextField,
        submitMethod: capturePayment
    )

    // MARK: Public Methods

    public func render() {
        snapTextField.delegate = self
        ebtCashTextField.delegate = self

        setupView()
        setupConstraints()
    }

    // MARK: Private Methods

    private func deferPaymentCapture(pinTextField: ForagePINTextField, paymentReference: String, completion: @escaping () -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            ForageSDK.shared.deferPaymentCapture(
                foragePinTextField: pinTextField,
                paymentReference: paymentReference
            ) { result in
                pinTextField.clearText()
                self.printCollectPinResult(result, completion: completion)
            }
        }
    }

    private func capturePayment(pinTextField: ForagePINTextField, paymentReference: String, completion: @escaping () -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            ForageSDK.shared.capturePayment(
                foragePinTextField: pinTextField,
                paymentReference: paymentReference
            ) { result in
                pinTextField.clearText()
                self.printCaptureResult(result, completion: completion)
            }
        }
    }

    private func printCollectPinResult(_ result: Result<Void, Error>, completion: @escaping () -> Void) {
        DispatchQueue.main.async {
            switch result {
            case .success:
                self.deferPaymentCaptureResponseLabel.text = "deferPaymentCapture: success"
                self.paymentRefLabel.text = ""
                self.fundingTypeLabel.text = ""
                self.amountLabel.text = ""
                self.errorLabel.text = ""
            case let .failure(error):
                self.printError(error)
            }
            completion()
        }
    }

    private func printError(_ error: Error) {
        DispatchQueue.main.async { [self] in
            logForageError(error)
            errorLabel.text = "\(error)"
            paymentRefLabel.text = ""
            fundingTypeLabel.text = ""
            amountLabel.text = ""
            deferPaymentCaptureResponseLabel.text = ""
        }
    }

    private func printCaptureResult(_ result: Result<PaymentModel, Error>, completion: @escaping () -> Void) {
        DispatchQueue.main.async { [self] in
            switch result {
            case let .success(response):
                paymentRefLabel.text = "paymentRef=\(response.paymentRef)"
                fundingTypeLabel.text = "fundingType=\(response.fundingType)"
                amountLabel.text = "amount=\(response.amount)"
                errorLabel.text = ""
                deferPaymentCaptureResponseLabel.text = ""
            case let .failure(error):
                if let forageError = error as? ForageError? {
                    if forageError?.code == "ebt_error_51" && forageError?.httpStatusCode == 400 {
                        switch forageError?.details {
                        case let .ebtError51(snapBalance, cashBalance):
                            let snapBalanceText = snapBalance ?? "N/A"
                            let cashBalanceText = cashBalance ?? "N/A"

                            remainingBalanceLabel.text = "firstForageError.details: remaining balances are SNAP: \(snapBalanceText), EBT Cash: \(cashBalanceText)"
                        default:
                            remainingBalanceLabel.text = "firstForageError.details: Missing insufficient funds error details!"
                        }
                    }
                }
                printError(error)
            }

            layoutIfNeeded()
            layoutSubviews()

            completion()
        }
    }

    private func setupView() {
        addSubview(contentView)

        contentView.addSubview(titleLabel)

        contentView.addSubview(snapHeadingLabel)
        contentView.addSubview(snapTextField)
        contentView.addSubview(snapButtonContainer)
        snapButtonContainer.addSubview(collectSnapPinButton)
        snapButtonContainer.addSubview(captureSnapButton)

        contentView.addSubview(ebtCashHeadingLabel)
        contentView.addSubview(ebtCashTextField)

        contentView.addSubview(ebtCashButtonContainer)
        ebtCashButtonContainer.addSubview(collectEbtCashPinButton)
        ebtCashButtonContainer.addSubview(captureEbtCashButton)

        contentView.addSubview(deferPaymentCaptureResponseLabel)
        contentView.addSubview(statusTypeLabel)
        contentView.addSubview(statusLabel)
        contentView.addSubview(paymentRefLabel)
        contentView.addSubview(fundingTypeLabel)
        contentView.addSubview(amountLabel)
        contentView.addSubview(errorLabel)
        contentView.addSubview(remainingBalanceLabel)
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

        anchorContentViewSubviews(
            contentView: contentView,
            subviews: [
                titleLabel,
                snapHeadingLabel,
                snapTextField,
            ]
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
            collectSnapPinButton.topAnchor.constraint(equalTo: snapButtonContainer.topAnchor),
            collectSnapPinButton.leadingAnchor.constraint(equalTo: snapButtonContainer.leadingAnchor),
            collectSnapPinButton.bottomAnchor.constraint(equalTo: snapButtonContainer.bottomAnchor),
            collectSnapPinButton.heightAnchor.constraint(equalToConstant: 48),
            collectSnapPinButton.widthAnchor.constraint(equalTo: snapButtonContainer.widthAnchor, multiplier: collectButtonWidthMultiplier, constant: -(buttonSpacing / 2)),
        ])

        NSLayoutConstraint.activate([
            captureSnapButton.topAnchor.constraint(equalTo: snapButtonContainer.topAnchor),
            captureSnapButton.leadingAnchor.constraint(equalTo: collectSnapPinButton.trailingAnchor, constant: buttonSpacing),
            captureSnapButton.trailingAnchor.constraint(equalTo: snapButtonContainer.trailingAnchor),
            captureSnapButton.bottomAnchor.constraint(equalTo: snapButtonContainer.bottomAnchor),
            captureSnapButton.heightAnchor.constraint(equalToConstant: 48),
            captureSnapButton.widthAnchor.constraint(equalTo: snapButtonContainer.widthAnchor, multiplier: captureButtonWidthMultiplier, constant: -(buttonSpacing / 2)),
        ])

        ebtCashHeadingLabel.anchor(
            top: captureSnapButton.safeAreaLayoutGuide.bottomAnchor,
            leading: contentView.safeAreaLayoutGuide.leadingAnchor,
            bottom: nil,
            trailing: contentView.safeAreaLayoutGuide.trailingAnchor,
            centerXAnchor: contentView.centerXAnchor,
            padding: UIEdgeInsets(top: 24, left: 24, bottom: 12, right: 24)
        )

        ebtCashTextField.anchor(
            top: ebtCashHeadingLabel.safeAreaLayoutGuide.bottomAnchor,
            leading: contentView.safeAreaLayoutGuide.leadingAnchor,
            bottom: nil,
            trailing: contentView.safeAreaLayoutGuide.trailingAnchor,
            centerXAnchor: contentView.centerXAnchor,
            padding: UIEdgeInsets(top: 24, left: 24, bottom: 12, right: 24)
        )

        ebtCashButtonContainer.anchor(
            top: ebtCashTextField.bottomAnchor,
            leading: contentView.leadingAnchor,
            bottom: nil,
            trailing: contentView.trailingAnchor,
            centerXAnchor: contentView.centerXAnchor,
            padding: UIEdgeInsets(top: 12, left: 24, bottom: 0, right: 24)
        )

        collectEbtCashPinButton.anchor(
            top: ebtCashButtonContainer.topAnchor,
            leading: ebtCashButtonContainer.leadingAnchor,
            bottom: ebtCashButtonContainer.bottomAnchor,
            trailing: nil,
            centerXAnchor: nil,
            size: .init(width: 0, height: 48)
        )

        captureEbtCashButton.anchor(
            top: ebtCashButtonContainer.topAnchor,
            leading: collectEbtCashPinButton.trailingAnchor,
            bottom: ebtCashButtonContainer.bottomAnchor,
            trailing: ebtCashButtonContainer.trailingAnchor,
            centerXAnchor: nil,
            padding: UIEdgeInsets(top: 0, left: buttonSpacing, bottom: 0, right: 0),
            size: .init(width: 0, height: 48)
        )

        NSLayoutConstraint.activate([
            collectEbtCashPinButton.topAnchor.constraint(equalTo: ebtCashButtonContainer.topAnchor),
            collectEbtCashPinButton.leadingAnchor.constraint(equalTo: ebtCashButtonContainer.leadingAnchor),
            collectEbtCashPinButton.bottomAnchor.constraint(equalTo: ebtCashButtonContainer.bottomAnchor),
            collectEbtCashPinButton.heightAnchor.constraint(equalToConstant: 48),
            collectEbtCashPinButton.widthAnchor.constraint(equalTo: ebtCashButtonContainer.widthAnchor, multiplier: collectButtonWidthMultiplier, constant: -(buttonSpacing / 2)),
        ])

        NSLayoutConstraint.activate([
            captureEbtCashButton.topAnchor.constraint(equalTo: ebtCashButtonContainer.topAnchor),
            captureEbtCashButton.leadingAnchor.constraint(equalTo: collectEbtCashPinButton.trailingAnchor, constant: buttonSpacing),
            captureEbtCashButton.trailingAnchor.constraint(equalTo: ebtCashButtonContainer.trailingAnchor),
            captureEbtCashButton.bottomAnchor.constraint(equalTo: ebtCashButtonContainer.bottomAnchor),
            captureEbtCashButton.heightAnchor.constraint(equalToConstant: 48),
            captureEbtCashButton.widthAnchor.constraint(equalTo: ebtCashButtonContainer.widthAnchor, multiplier: captureButtonWidthMultiplier, constant: -(buttonSpacing / 2)),
        ])

        deferPaymentCaptureResponseLabel.anchor(
            top: captureEbtCashButton.safeAreaLayoutGuide.bottomAnchor,
            leading: contentView.safeAreaLayoutGuide.leadingAnchor,
            bottom: nil,
            trailing: contentView.safeAreaLayoutGuide.trailingAnchor,
            centerXAnchor: contentView.centerXAnchor,
            padding: UIEdgeInsets(top: 24, left: 24, bottom: 0, right: 24)
        )

        statusTypeLabel.anchor(
            top: deferPaymentCaptureResponseLabel.safeAreaLayoutGuide.bottomAnchor,
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

        remainingBalanceLabel.anchor(
            top: errorLabel.safeAreaLayoutGuide.bottomAnchor,
            leading: contentView.safeAreaLayoutGuide.leadingAnchor,
            bottom: nil,
            trailing: contentView.safeAreaLayoutGuide.trailingAnchor,
            centerXAnchor: contentView.centerXAnchor,
            padding: UIEdgeInsets(top: 24, left: 24, bottom: 0, right: 24)
        )
    }
}

// MARK: - ForageElementDelegate

extension CapturePaymentView: ForageElementDelegate {
    func focusDidChange(_ state: ObservableState) {}

    func textFieldDidChange(_ state: ObservableState) {}
}
