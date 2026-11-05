//
//  ViewController.swift
//  SampleForageSDK
//
//  Created by Tiago Oliveira on 16/10/22.
//  © 2022-2025 Forage Technology Corporation. All rights reserved.
//

import ForageSDK
import UIKit

class ViewController: UIViewController {
    // MARK: IBOutlets

    @IBOutlet private var sessionTokenTextField: UITextField!
    @IBOutlet private var merchantIdTextField: UITextField!

    // MARK: Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Moments",
            style: .plain,
            target: self,
            action: #selector(didTapOnMoments)
        )
    }

    private func initializeSdk() {
        guard
            let merchantID = merchantIdTextField.text,
            let sessionToken = sessionTokenTextField.text
        else { return }

        ClientSharedData.shared.merchantID = merchantID
        ClientSharedData.shared.sessionToken = sessionToken

        ForageSDK.setup(
            ForageSDK.Config(
                merchantID: merchantID,
                sessionToken: sessionToken
            )
        )
    }

    // MARK: IBActions

    @IBAction func didTapOnStartEbtFlow(_ sender: Any) {
        initializeSdk()

        let cardNumberViewController = CardNumberViewController()
        navigationController?.pushViewController(
            cardNumberViewController,
            animated: true
        )
    }
    
    @objc func didTapOnMoments() {
        initializeSdk()

        navigationController?.pushViewController(
            MomentsViewController(),
            animated: true
        )
    }

    @IBAction func didTapOnStartHSAFSAFlow(_ sender: Any) {
        initializeSdk()
        
        let HSAViewController = HSAViewController()
        navigationController?.pushViewController(
            HSAViewController,
            animated: true
        )
    }
}
