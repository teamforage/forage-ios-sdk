//
//  BaseViewCodeViewController.swift
//  SampleForageSDK
//
//  Created by Tiago Oliveira on 18/10/22.
//  Copyright © 2022-Present Forage Technology Corporation. All rights reserved.
//

import Foundation
import UIKit

class BaseViewCodeViewController<CustomViewProtocol: UIView>: UIViewController {
    typealias Handler = () -> Void

    var customView: CustomViewProtocol {
        return view as! CustomViewProtocol
    }

    override func loadView() {
        view = CustomViewProtocol()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        dismissKeyboardTapOutside()
    }

    func alert(message: String, title: String = "", completion: Handler? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default) { (_) in
            completion?()
        }

        alert.addAction(OKAction)

        self.present(alert, animated: true, completion: nil)
    }

    @objc func dismissKeyboardTapOutside() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(BaseViewCodeViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
