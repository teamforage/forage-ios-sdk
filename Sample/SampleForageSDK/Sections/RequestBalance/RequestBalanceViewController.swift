//
//  RequestBalanceViewController.swift
//  SampleForageSDK
//
//  Created by Symphony on 24/10/22.
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
}

// MARK: - RequestBalanceViewDelegate

extension RequestBalanceViewController: RequestBalanceViewDelegate {
    func goToCreatePayment(_ view: RequestBalanceView) {
        let createPaymentViewController = CreatePaymentViewController()
        navigationController?.pushViewController(createPaymentViewController, animated: true)
    }
}
