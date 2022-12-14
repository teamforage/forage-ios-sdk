//
//  CardNumberViewController.swift
//  SampleForageSDK
//
//  Created by Symphony on 18/10/22.
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
}

// MARK: - CardNumberViewDelegate

extension CardNumberViewController: CardNumberViewDelegate {
    func goToBalance(_ view: CardNumberView) {
        let requestBalanceViewController = RequestBalanceViewController()
        navigationController?.pushViewController(requestBalanceViewController, animated: true)
    }
}
