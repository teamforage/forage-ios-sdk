//
//  CardNumberViewController.swift
//  SampleForageSDK
//
//  Created by Tiago Oliveira on 18/10/22.
//  © 2022-2025 Forage Technology Corporation. All rights reserved.
//

import UIKit

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
    }
}

// MARK: - CardNumberViewDelegate

extension CardNumberViewController: CardNumberViewDelegate {
    func goToBalance(_ view: CardNumberView) {
        let requestBalanceViewController = RequestBalanceViewController()
        navigationController?.pushViewController(requestBalanceViewController, animated: true)
    }
}
