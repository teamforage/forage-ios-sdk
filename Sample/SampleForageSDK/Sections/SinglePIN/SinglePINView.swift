//
//  SinglePINView.swift
//  SampleForageSDK
//
//  © 2022-2025 Forage Technology Corporation. All rights reserved.
//

import ForageSDK
import Foundation
import UIKit

/// A single payment row: a merchant ref + SNAP amount form that creates one SNAP payment.
/// After a successful creation it holds the resulting `DeferredPayment` so the parent screen
/// can defer-capture it later with a single PIN.
final class PaymentFormRow: UIView {
    // MARK: Public Properties

    /// The payment created from this row's inputs, or `nil` if it hasn't been created yet.
    private(set) var deferredPayment: DeferredPayment?

    /// Injected by the parent to perform the actual payment creation. Returns the created payment reference.
    var onCreatePayment: ((_ merchantRef: String, _ amount: String, _ completion: @escaping (Result<String, Error>) -> Void) -> Void)?

    // MARK: Private Components

    private let accessibilityPrefix: String

    private lazy var merchantRefTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Merchant ref"
        tf.borderStyle = .roundedRect
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        tf.accessibilityIdentifier = "\(accessibilityPrefix)_merchant_ref"
        tf.isAccessibilityElement = true
        return tf
    }()

    private lazy var amountTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "SNAP amount"
        tf.borderStyle = .roundedRect
        tf.keyboardType = .decimalPad
        tf.accessibilityIdentifier = "\(accessibilityPrefix)_amount"
        tf.isAccessibilityElement = true
        return tf
    }()

    private lazy var createButton: UIButton = .createPaymentButton(
        title: "Create SNAP Payment",
        accessibilityIdentifier: "\(accessibilityPrefix)_create",
        fundingType: .ebtSnap,
        action: { [weak self] completion in
            self?.createPayment(completion: completion)
        }
    )

    private lazy var statusLabel: UILabel = .create(id: "\(accessibilityPrefix)_status")

    // MARK: Init

    init(accessibilityPrefix: String) {
        self.accessibilityPrefix = accessibilityPrefix
        super.init(frame: .zero)
        setupView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Private Methods

    private func createPayment(completion: @escaping () -> Void) {
        let merchantRef = merchantRefTextField.text ?? ""
        let amount = amountTextField.text ?? ""

        guard !merchantRef.isEmpty, !amount.isEmpty else {
            statusLabel.textColor = .red
            statusLabel.text = "Enter a merchant ref and a SNAP amount"
            completion()
            return
        }

        onCreatePayment?(merchantRef, amount) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case let .success(paymentRef):
                    self.deferredPayment = DeferredPayment(merchantID: merchantRef, paymentReference: paymentRef)
                    self.statusLabel.textColor = .black
                    self.statusLabel.text = "created paymentRef=\(paymentRef)\nmerchant=\(merchantRef)"
                case let .failure(error):
                    self.deferredPayment = nil
                    self.statusLabel.textColor = .red
                    self.statusLabel.text = "error: \(error.localizedDescription)"
                }
                completion()
            }
        }
    }

    private func setupView() {
        addSubview(merchantRefTextField)
        addSubview(amountTextField)
        addSubview(createButton)
        addSubview(statusLabel)

        merchantRefTextField.anchor(
            top: topAnchor,
            leading: leadingAnchor,
            bottom: nil,
            trailing: trailingAnchor,
            centerXAnchor: centerXAnchor,
            size: .init(width: 0, height: 42)
        )

        amountTextField.anchor(
            top: merchantRefTextField.bottomAnchor,
            leading: leadingAnchor,
            bottom: nil,
            trailing: trailingAnchor,
            centerXAnchor: centerXAnchor,
            padding: .init(top: 12, left: 0, bottom: 0, right: 0),
            size: .init(width: 0, height: 42)
        )

        createButton.anchor(
            top: amountTextField.bottomAnchor,
            leading: leadingAnchor,
            bottom: nil,
            trailing: trailingAnchor,
            centerXAnchor: centerXAnchor,
            padding: .init(top: 12, left: 0, bottom: 0, right: 0),
            size: .init(width: 0, height: 48)
        )

        statusLabel.anchor(
            top: createButton.bottomAnchor,
            leading: leadingAnchor,
            bottom: bottomAnchor,
            trailing: trailingAnchor,
            centerXAnchor: centerXAnchor,
            padding: .init(top: 12, left: 0, bottom: 0, right: 0)
        )
    }
}

/// Demonstrates deferring the capture of multiple payments with a single PIN entry via
/// `ForageSDK.deferMultiPaymentCapture(foragePinTextField:payments:completion:)`.
final class SinglePINView: BaseSampleView {
    // MARK: Private Properties

    private let createPaymentService = CreatePaymentService()

    // MARK: Private Components

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.keyboardDismissMode = .interactive
        return scrollView
    }()

    private let contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Single PIN"
        label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        label.accessibilityIdentifier = "lbl_title"
        label.isAccessibilityElement = true
        return label
    }()

    private let paymentRow1 = PaymentFormRow(accessibilityPrefix: "single_pin_payment_1")
    private let paymentRow2 = PaymentFormRow(accessibilityPrefix: "single_pin_payment_2")

    private let separator: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray4
        return view
    }()

    private let pinHeadingLabel: UILabel = {
        let label = UILabel.create(id: "lbl_pin_heading")
        label.text = "EBT PIN"
        label.textColor = .black
        label.font = .systemFont(ofSize: 20)
        return label
    }()

    public let foragePinTextField: ForagePINTextField = {
        let tf = ForagePINTextField()
        tf.placeholder = "PIN Field"
        tf.accessibilityIdentifier = "tf_pin_single"
        tf.isAccessibilityElement = true
        tf.borderWidth = 2.0
        tf.borderColor = .primaryColor
        tf.font = .systemFont(ofSize: 18)
        return tf
    }()

    private lazy var deferBothButton: UIButton = .createPaymentButton(
        title: "Defer Capture Both Payments",
        accessibilityIdentifier: "bt_defer_both_payments",
        fundingType: .ebtSnap,
        action: { [weak self] completion in
            self?.deferBothPayments(completion: completion)
        }
    )

    private let resultLabel: UILabel = .create(id: "lbl_defer_result")
    private let errorLabel: UILabel = .create(id: "lbl_error")

    // MARK: Public Methods

    public func render() {
        wirePaymentRows()
        setupView()
        setupConstraints()
    }

    // MARK: Private Methods

    private func wirePaymentRows() {
        let creator: (String, String, @escaping (Result<String, Error>) -> Void) -> Void = { [weak self] merchantRef, amount, completion in
            self?.createPayment(merchantRef: merchantRef, amount: amount, completion: completion)
        }
        paymentRow1.onCreatePayment = creator
        paymentRow2.onCreatePayment = creator
    }

    private func createPayment(merchantRef: String, amount: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let amountValue = Double(amount) else {
            completion(.failure(NSError(
                domain: "SinglePIN",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "SNAP amount must be a number"]
            )))
            return
        }

        let request = CreatePaymentRequest(
            amount: amountValue,
            fundingType: FundingType.ebtSnap.rawValue,
            paymentMethodIdentifier: ClientSharedData.shared.paymentMethodReference,
            merchantID: merchantRef,
            description: "Single PIN test payment",
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

        createPaymentService.createPayment(request: request) { result in
            switch result {
            case let .success(response):
                completion(.success(response.paymentIdentifier))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    private func deferBothPayments(completion: @escaping () -> Void) {
        guard
            let firstPayment = paymentRow1.deferredPayment,
            let secondPayment = paymentRow2.deferredPayment
        else {
            DispatchQueue.main.async {
                self.resultLabel.text = ""
                self.errorLabel.text = "Create both payments before deferring."
                completion()
            }
            return
        }

        let payments = [firstPayment, secondPayment]

        DispatchQueue.global(qos: .userInitiated).async {
            ForageSDK.shared.deferMultiPaymentCapture(
                foragePinTextField: self.foragePinTextField,
                payments: payments
            ) { result in
                DispatchQueue.main.async {
                    self.foragePinTextField.clearText()
                    switch result {
                    case .success:
                        self.resultLabel.textColor = .black
                        self.resultLabel.text = "deferMultiPaymentCapture: success (\(payments.count) payments)"
                        self.errorLabel.text = ""
                    case let .failure(error):
                        self.logForageError(error)
                        self.resultLabel.text = ""
                        self.errorLabel.text = "\(error)"
                    }
                    completion()
                }
            }
        }
    }

    private func setupView() {
        addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(titleLabel)
        contentView.addSubview(paymentRow1)
        contentView.addSubview(separator)
        contentView.addSubview(paymentRow2)
        contentView.addSubview(pinHeadingLabel)
        contentView.addSubview(foragePinTextField)
        contentView.addSubview(deferBothButton)
        contentView.addSubview(resultLabel)
        contentView.addSubview(errorLabel)
    }

    private func setupConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
        ])

        titleLabel.anchor(
            top: contentView.topAnchor,
            leading: contentView.leadingAnchor,
            bottom: nil,
            trailing: contentView.trailingAnchor,
            centerXAnchor: contentView.centerXAnchor,
            padding: .init(top: 24, left: 24, bottom: 0, right: 24)
        )

        paymentRow1.anchor(
            top: titleLabel.bottomAnchor,
            leading: contentView.leadingAnchor,
            bottom: nil,
            trailing: contentView.trailingAnchor,
            centerXAnchor: contentView.centerXAnchor,
            padding: .init(top: 24, left: 24, bottom: 0, right: 24)
        )

        separator.anchor(
            top: paymentRow1.bottomAnchor,
            leading: contentView.leadingAnchor,
            bottom: nil,
            trailing: contentView.trailingAnchor,
            centerXAnchor: contentView.centerXAnchor,
            padding: .init(top: 24, left: 24, bottom: 0, right: 24),
            size: .init(width: 0, height: 1)
        )

        paymentRow2.anchor(
            top: separator.bottomAnchor,
            leading: contentView.leadingAnchor,
            bottom: nil,
            trailing: contentView.trailingAnchor,
            centerXAnchor: contentView.centerXAnchor,
            padding: .init(top: 24, left: 24, bottom: 0, right: 24)
        )

        pinHeadingLabel.anchor(
            top: paymentRow2.bottomAnchor,
            leading: contentView.leadingAnchor,
            bottom: nil,
            trailing: contentView.trailingAnchor,
            centerXAnchor: contentView.centerXAnchor,
            padding: .init(top: 24, left: 24, bottom: 0, right: 24)
        )

        foragePinTextField.anchor(
            top: pinHeadingLabel.bottomAnchor,
            leading: contentView.leadingAnchor,
            bottom: nil,
            trailing: contentView.trailingAnchor,
            centerXAnchor: contentView.centerXAnchor,
            padding: .init(top: 12, left: 24, bottom: 0, right: 24),
            size: .init(width: 0, height: 60)
        )

        deferBothButton.anchor(
            top: foragePinTextField.bottomAnchor,
            leading: contentView.leadingAnchor,
            bottom: nil,
            trailing: contentView.trailingAnchor,
            centerXAnchor: contentView.centerXAnchor,
            padding: .init(top: 24, left: 24, bottom: 0, right: 24),
            size: .init(width: 0, height: 48)
        )

        resultLabel.anchor(
            top: deferBothButton.bottomAnchor,
            leading: contentView.leadingAnchor,
            bottom: nil,
            trailing: contentView.trailingAnchor,
            centerXAnchor: contentView.centerXAnchor,
            padding: .init(top: 24, left: 24, bottom: 0, right: 24)
        )

        errorLabel.anchor(
            top: resultLabel.bottomAnchor,
            leading: contentView.leadingAnchor,
            bottom: contentView.bottomAnchor,
            trailing: contentView.trailingAnchor,
            centerXAnchor: contentView.centerXAnchor,
            padding: .init(top: 24, left: 24, bottom: 24, right: 24)
        )
    }
}
