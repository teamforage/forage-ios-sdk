//
//  CardNumberViewController.swift
//  SampleForageSDK
//
//  Created by Tiago Oliveira on 18/10/22.
//  Copyright © 2022-Present Forage Technology Corporation. All rights reserved.
//

import UIKit
import ForageSDK

class CardNumberViewController: BaseViewCodeViewController<CardNumberView> {
    // MARK: Lifecycle Methods

    override func loadView() {
        super.loadView()
        customView.backgroundColor = .white
        customView.render()
        customView.delegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        customView.foragePanTextField.becomeFirstResponder()
        
        /// Recall in `ViewController` that we intentionally set the wrong SDK values.
        /// We defer the "later" .setup call to the first `viewDidAppear` in the sample app
        /// - to ensure that .setup can update the values accurately.
        ForageSDK.setup(
            ForageSDK.Config(
                merchantID: ClientSharedData.shared.merchantID,
                sessionToken: ClientSharedData.shared.sessionToken
            )
        )
    }
}

// MARK: - CardNumberViewDelegate

extension CardNumberViewController: CardNumberViewDelegate {
    func goToBalance(_ view: CardNumberView) {
        let requestBalanceViewController = RequestBalanceViewController()
        navigationController?.pushViewController(requestBalanceViewController, animated: true)
    }
}
