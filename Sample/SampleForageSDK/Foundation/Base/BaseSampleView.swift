//
//  BaseSampleView.swift
//  SampleForageSDK
//
//  Created by Danilo Joksimovic on 2023-12-13.
//

import Foundation
import UIKit

extension UIColor {
    // Forage Green
    static let primaryColor = UIColor(red: 2.0 / 255.0, green: 66.0 / 255.0, blue: 48.0 / 255.0, alpha: 1.0)
    static let secondaryColor = UIColor(red: 220.0 / 255.0, green: 255.0 / 255.0, blue: 224.0 / 255.0, alpha: 1.0)
    static let offWhite = UIColor(red: 245.0 / 255.0, green: 244.0 / 255.0, blue: 238.0 / 255.0, alpha: 1.0)
    static let forageBlack = UIColor(red: 29.0 / 255.0, green: 29.0 / 255.0, blue: 32.0 / 255.0, alpha: 1.0)
}

extension UILabel {
    static func create(id: String, text: String = "") -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = .gray
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.numberOfLines = 0
        label.accessibilityIdentifier = id
        label.isAccessibilityElement = true
        return label
    }
}

extension UIButton {
    static func createNextButton(
        _ target: Any?,
        action: Selector,
        isEnabled: Bool = true,
        title: String = "Next step"
    ) -> UIButton {
        let button = UIButton()
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(target, action: action, for: .touchUpInside)
        button.backgroundColor = .forageBlack
        button.isEnabled = isEnabled
        button.isUserInteractionEnabled = isEnabled
        button.alpha = isEnabled ? 1.0 : 0.5
        button.accessibilityIdentifier = "bt_next"
        button.isAccessibilityElement = true
        return button
    }

    static func createPaymentButton(
        title: String,
        accessibilityIdentifier: String,
        fundingType: FundingType,
        action: @escaping (_ completion: @escaping () -> Void) -> Void
    ) -> LoadingButton {
        let button = LoadingButton()
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)

        button.setTitleColor(fundingType == .ebtSnap ? .white : .forageBlack, for: .normal)
        button.tintColor = .offWhite
        button.backgroundColor = fundingType == .ebtSnap ? .primaryColor : .offWhite
        button.layer.borderWidth = fundingType == .ebtSnap ? 0 : 2
        button.layer.borderColor = fundingType == .ebtSnap ? nil : UIColor.forageBlack.cgColor

        button.translatesAutoresizingMaskIntoConstraints = false
        button.addAction(UIAction { _ in
            button.showLoading()
            action {
                DispatchQueue.main.async {
                    button.hideLoading()
                }
            }
        }, for: .touchUpInside)
        button.accessibilityIdentifier = accessibilityIdentifier
        button.isAccessibilityElement = true
        return button
    }
}

class LoadingButton: UIButton {
    private var originalButtonText: String?
    private var activityIndicator: UIActivityIndicatorView!

    func showLoading() {
        DispatchQueue.main.async { [self] in
            originalButtonText = titleLabel?.text
            setTitle("", for: .normal)

            if activityIndicator == nil {
                activityIndicator = createActivityIndicator()
            }

            activityIndicator.startAnimating()
        }
    }

    func hideLoading() {
        DispatchQueue.main.async { [self] in
            setTitle(originalButtonText, for: .normal)
            activityIndicator.stopAnimating()
        }
    }

    private func createActivityIndicator() -> UIActivityIndicatorView {
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = backgroundColor == .primaryColor ? .secondaryColor : .forageBlack
        addSubview(activityIndicator)

        // Center the activity indicator in the button
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

        return activityIndicator
    }
}

class BaseSampleView: UIView {
    func anchorContentViewSubviews(contentView: UIView, subviews: [UIView]) {
        for (index, view) in subviews.enumerated() {
            view.anchor(
                top:
                index == 0 ?
                    contentView.safeAreaLayoutGuide.topAnchor
                    : subviews[index - 1].safeAreaLayoutGuide.bottomAnchor,
                leading: contentView.safeAreaLayoutGuide.leadingAnchor,
                bottom: nil,
                trailing: contentView.safeAreaLayoutGuide.trailingAnchor,
                centerXAnchor: contentView.centerXAnchor,
                padding: UIEdgeInsets(top: index == 0 ? 0 : 24, left: 24, bottom: 0, right: 24)
            )
        }
    }
}
