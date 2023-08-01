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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let pinView = self.customView.pinNumberTextField
        
        print("Is Input Frame Focused: \(pinView.isFirstResponder)")
        let didFocus = self.customView.pinNumberTextField.becomeFirstResponder()
        print("Is Input Frame Focused: \(pinView.isFirstResponder)")
    }
}

// MARK: - RequestBalanceViewDelegate

extension RequestBalanceViewController: RequestBalanceViewDelegate {
    func goToCreatePayment(_ view: RequestBalanceView) {
        let createPaymentViewController = CreatePaymentViewController()
        navigationController?.pushViewController(createPaymentViewController, animated: true)
    }
}
