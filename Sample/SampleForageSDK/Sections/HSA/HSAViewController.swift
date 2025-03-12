//
//  HSAViewController.swift
//  SampleForageSDK
//
//  Created by Jerimiah on 2/27/25.
//  Copyright © 2025-Present Forage Technology Corporation. All rights reserved.
//

import UIKit

class HSAViewController: BaseViewCodeViewController<HSAView> {
    // MARK: Lifecycle Methods

    override func loadView() {
        super.loadView()
        customView.backgroundColor = .white
        customView.render()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        customView.forageHSAPaymentSheet.cardHolderNameTextField.becomeFirstResponder()
    }
}
