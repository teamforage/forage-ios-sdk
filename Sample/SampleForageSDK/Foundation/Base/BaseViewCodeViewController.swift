//
//  BaseViewCodeViewController.swift
//  SampleForageSDK
//
//  Created by Symphony on 18/10/22.
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
    
    func alert(message: String, title: String = "", completion: Handler? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default) { (_) in
            completion?()
        }
        
        alert.addAction(OKAction)
        
        self.present(alert, animated: true, completion: nil)
    }
}
