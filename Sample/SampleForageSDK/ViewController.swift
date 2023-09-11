//
//  ViewController.swift
//  SampleForageSDK
//
//  Created by Tiago Oliveira on 16/10/22.
//  Copyright © 2022-Present Forage Technology Corporation. All rights reserved.
//

import UIKit
import ForageSDK

class ViewController: UIViewController {
    
    // MARK: IBOutlets
    
    @IBOutlet private weak var sessionTokenTextField: UITextField!
    @IBOutlet private weak var merchantIdTextField: UITextField!
    
    // MARK: Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: IBActions
    
    @IBAction func didTapOnStartSDK(_ sender: Any) {
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
        
        let cardNumberViewController = CardNumberViewController()
        navigationController?.pushViewController(cardNumberViewController, animated: true)
    }
}
