//
//  CapturePaymentViewController.swift
//  SampleForageSDK
//
//  Created by Symphony on 26/10/22.
//

import UIKit

class CapturePaymentViewController: BaseViewCodeViewController<CapturePaymentView> {
    
    // MARK: Lifecycle Methods
    
    override func loadView() {
        super.loadView()
        customView.backgroundColor = .white
        customView.render()
    }
}
