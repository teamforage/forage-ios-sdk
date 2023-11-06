//
//  RequestBalanceViewController.swift
//  SampleForageSDK
//
//  Created by Tiago Oliveira on 24/10/22.
//  Copyright © 2022-Present Forage Technology Corporation. All rights reserved.
//

import UIKit

class RequestBalanceViewController: BaseViewCodeViewController<RequestBalanceView> {
    // MARK: Lifecycle Methods

    override func loadView() {
        super.loadView()
        customView.backgroundColor = .white
        customView.render()
        customView.delegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        customView.foragePinTextField.becomeFirstResponder()
    }
}

// MARK: - RequestBalanceViewDelegate

extension RequestBalanceViewController: RequestBalanceViewDelegate {
    func goToCreatePayment(_ view: RequestBalanceView) {
        let createPaymentViewController = CreatePaymentViewController()
        navigationController?.pushViewController(createPaymentViewController, animated: true)
    }
}
