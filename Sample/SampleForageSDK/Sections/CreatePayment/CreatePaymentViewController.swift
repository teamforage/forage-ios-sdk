//
//  CreatePaymentViewController.swift
//  SampleForageSDK
//
//  Created by Symphony on 25/10/22.
//

import UIKit

class CreatePaymentViewController: BaseViewCodeViewController<CreatePaymentView> {
    
    // MARK: Lifecycle Methods
    
    override func loadView() {
        super.loadView()
        customView.backgroundColor = .white
        customView.render()
        customView.delegate = self
    }
    
    func createPayment(
        request: CreatePaymentRequest,
        completion: @escaping (Result<CreatePaymentResponse, Error>) -> Void) -> Void {
            let service = CreatePaymentService()
            return service.createPayment(request: request, completion: completion)
    }
}

// MARK: - RequestBalanceViewDelegate

extension CreatePaymentViewController: CreatePaymentViewDelegate {
    func goToCapture(_ view: CreatePaymentView) {
        // TODO: Implement capture VC and View
    }
}
