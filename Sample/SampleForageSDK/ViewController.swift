//
//  ViewController.swift
//  SampleForageSDK
//
//  Created by Symphony on 16/10/22.
//

import UIKit
import ForageSDK

class ViewController: UIViewController {
    
    // MARK: IBOutlets
    
    @IBOutlet private weak var bearerTokenTextField: UITextField!
    @IBOutlet private weak var merchantIdTextField: UITextField!
    
    // MARK: Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: IBActions
    
    @IBAction func didTapOnStartSDK(_ sender: Any) {
        guard
            let merchantID = merchantIdTextField.text,
            let bearerToken = bearerTokenTextField.text
        else { return }
        
        ClientSharedData.shared.merchantID = merchantID
        ClientSharedData.shared.bearerToken = bearerToken
        
        ForageSDK.setup(
            ForageSDK.Config(
                environment: ClientSharedData.shared.environment,
                merchantAccount: merchantID,
                bearerToken: bearerToken
            )
        )
        
        let cardNumberViewController = CardNumberViewController()
        navigationController?.pushViewController(cardNumberViewController, animated: true)
    }
}
