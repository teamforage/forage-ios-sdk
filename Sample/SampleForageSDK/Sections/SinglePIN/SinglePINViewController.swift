//
//  SinglePINViewController.swift
//  SampleForageSDK
//
//  © 2022-2025 Forage Technology Corporation. All rights reserved.
//

import UIKit

class SinglePINViewController: BaseViewCodeViewController<SinglePINView> {
    // MARK: Lifecycle Methods

    override func loadView() {
        super.loadView()
        customView.backgroundColor = .white
        customView.render()
    }
}
