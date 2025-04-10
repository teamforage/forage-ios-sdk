//
//  CapturePaymentViewController.swift
//  SampleForageSDK
//
//  Created by Tiago Oliveira on 26/10/22.
//  © 2022-Present Forage Technology Corporation. All rights reserved.
//

import UIKit

class CapturePaymentViewController: BaseViewCodeViewController<CapturePaymentView> {
    // MARK: Lifecycle Methods

    override func loadView() {
        super.loadView()
        customView.backgroundColor = .white
        customView.render()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        customView.snapTextField.becomeFirstResponder()
    }
}
