//
//  MomentsViewController.swift
//  SampleForageSDK
//
//  © 2025 Forage Technology Corporation. All rights reserved.
//

@_spi(Development) import ForageSDK
import UIKit

class MomentsViewController: BaseViewCodeViewController<MomentsView> {
    // MARK: Lifecycle Methods

    override func loadView() {
        super.loadView()
        customView.backgroundColor = .white
        customView.render()
        customView.delegate = self
    }
}

// MARK: - MomentsViewDelegate

extension MomentsViewController: MomentsViewDelegate {
    func openCollectPinMoment(_ view: MomentsView, paymentRef: String, baseURL: String) {
        // only for local development, so the moment opens on a local custom-checkout.
        // only dev and local session tokens use it
        ForageSDK.momentBaseURLOverride = baseURL.isEmpty ? nil : URL(string: baseURL)

        ForageSDK.shared.createMoment(
            .paymentCollectPin(paymentRef: paymentRef),
            presentingFrom: self
        ) { result in
            switch result {
            case .success(.completed):
                view.showResult("completed")
            case .success(.dismissed):
                view.showResult("dismissed")
            case let .failure(error):
                view.logForageError(error)
                view.showResult("failed: \(error)")
            }
        }
    }
}
