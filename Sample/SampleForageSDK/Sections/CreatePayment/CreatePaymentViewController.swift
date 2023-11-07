//
//  CreatePaymentViewController.swift
//  SampleForageSDK
//
//  Created by Tiago Oliveira on 25/10/22.
//  Copyright © 2022-Present Forage Technology Corporation. All rights reserved.
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
        completion: @escaping (Result<CreatePaymentResponse, Error>) -> Void
    ) {
        let service = CreatePaymentService()
        return service.createPayment(request: request, completion: completion)
    }
}

// MARK: - RequestBalanceViewDelegate

extension CreatePaymentViewController: CreatePaymentViewDelegate {
    func goToCapture(_ view: CreatePaymentView) {
        let capturePaymentViewController = CapturePaymentViewController()
        navigationController?.pushViewController(capturePaymentViewController, animated: true)
    }
}
