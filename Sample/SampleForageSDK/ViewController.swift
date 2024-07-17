//
//  ViewController.swift
//  SampleForageSDK
//
//  Created by Tiago Oliveira on 16/10/22.
//  Copyright © 2022-Present Forage Technology Corporation. All rights reserved.
//

import ForageSDK
import UIKit

class ViewController: UIViewController {
    // MARK: IBOutlets

    @IBOutlet private var sessionTokenTextField: UITextField!
    @IBOutlet private var merchantIdTextField: UITextField!

    @IBOutlet private var startPaymentSheetFlowButton: UIButton!

    override func viewDidLoad() {
        startPaymentSheetFlowButton.layer.borderWidth = 2
        startPaymentSheetFlowButton.layer.borderColor = UIColor.black.cgColor
    }

    private func initializeSdk() {
        guard
            let merchantID = merchantIdTextField.text,
            let sessionToken = sessionTokenTextField.text
        else { return }

        ClientSharedData.shared.merchantID = merchantID
        ClientSharedData.shared.sessionToken = sessionToken
        
        /// CHANGE WITH CAUTION
        /// we intentionall call ``ForageSDK.setup`` with invalid values first to ensure that we can update
        /// the config values later on in the ``CardNumberViewController.viewDidAppear`` method
        ForageSDK.setup(
            ForageSDK.Config(
                merchantID: "invalid mid/...",
                // intentionally omitted environment prefix from this sessionToken
                sessionToken: "invalid session Token with no environment prefix"
            )
        )
    }

    // MARK: IBActions

    @IBAction func didTapOnStartEbtFlow(_ sender: Any) {
        initializeSdk()

        let cardNumberViewController = CardNumberViewController()
        navigationController?.pushViewController(
            cardNumberViewController,
            animated: true
        )
    }

    @IBAction func didTapOnStartPaymentSheetFlow(_ sender: Any) {
        initializeSdk()

        let paymentSheetViewController = PaymentSheetViewController()
        navigationController?.pushViewController(
            paymentSheetViewController,
            animated: true
        )
    }
}
