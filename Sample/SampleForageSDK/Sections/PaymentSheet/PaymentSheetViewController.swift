//
//  PaymentSheetViewController.swift
//  SampleForageSDK
//
//  Created by Danilo Joksimovic on 2023-12-07.
//  Copyright © 2022-Present Forage Technology Corporation. All rights reserved.

import Foundation
import UIKit

class PaymentSheetViewController: BaseViewCodeViewController<PaymentSheetView> {
    // MARK: Lifecycle Methods

    override func loadView() {
        super.loadView()
        customView.backgroundColor = .white
        customView.render()
    }
}
