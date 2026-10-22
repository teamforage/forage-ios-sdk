//
//  MomentsView.swift
//  SampleForageSDK
//
//  © 2025 Forage Technology Corporation. All rights reserved.
//

import Foundation
import UIKit

protocol MomentsViewDelegate: AnyObject {
    func openCollectPinMoment(_ view: MomentsView, paymentRef: String, baseURL: String)
}

class MomentsView: BaseSampleView {
    // MARK: Public Properties

    weak var delegate: MomentsViewDelegate?

    // MARK: Private Components

    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.white
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Moments"
        label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        label.accessibilityIdentifier = "lbl_title"
        label.isAccessibilityElement = true
        return label
    }()

    private let paymentRefTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Payment ref"
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.borderStyle = .roundedRect
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        tf.accessibilityIdentifier = "tf_moment_payment_ref"
        tf.isAccessibilityElement = true
        return tf
    }()

    private let baseURLTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Moment base URL (empty uses the token's environment)"
        // custom-checkout's local dev server, reachable from the simulator
        tf.text = "http://localhost:3000"
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.borderStyle = .roundedRect
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        tf.keyboardType = .URL
        tf.accessibilityIdentifier = "tf_moment_base_url"
        tf.isAccessibilityElement = true
        return tf
    }()

    private lazy var openButton: UIButton = .createNextButton(
        self,
        action: #selector(didTapOpen),
        title: "Open payment_collect_pin moment"
    )

    private let resultLabel: UILabel = .create(id: "lbl_moment_result")

    // MARK: Public Methods

    public func render() {
        // prefill with the SNAP payment from the EBT flow, if there is one
        paymentRefTextField.text = ClientSharedData.shared.paymentReference[.ebtSnap]

        addSubview(contentView)
        contentView.anchor(
            top: safeAreaLayoutGuide.topAnchor,
            leading: leadingAnchor,
            bottom: bottomAnchor,
            trailing: trailingAnchor,
            centerXAnchor: nil
        )

        let subviews = [titleLabel, paymentRefTextField, baseURLTextField, openButton, resultLabel]
        subviews.forEach { contentView.addSubview($0) }
        anchorContentViewSubviews(contentView: contentView, subviews: subviews)
        openButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
    }

    public func showResult(_ text: String) {
        resultLabel.text = text
    }

    // MARK: Private Methods

    @objc private func didTapOpen() {
        resultLabel.text = "Opening..."
        delegate?.openCollectPinMoment(
            self,
            paymentRef: paymentRefTextField.text ?? "",
            baseURL: baseURLTextField.text ?? ""
        )
    }
}
