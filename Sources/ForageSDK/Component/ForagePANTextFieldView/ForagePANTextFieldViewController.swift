//
//  ForagePANTextFieldViewController.swift
//  ForageSDK
//
//  Created by Symphony on 21/10/22.
//

import Foundation

protocol ForagePANTextFieldViewController: AnyObject {
    func sendPanCardNumber(
        request: ForagePANRequest,
        completion: @escaping (Result<ForagePANModel, Error>) -> Void) -> Void
}

internal class LiveForagePANTextFieldViewController: ForagePANTextFieldViewController {
    
    // MARK: Methods
    
    internal func sendPanCardNumber(
        request: ForagePANRequest,
        completion: @escaping (Result<ForagePANModel, Error>) -> Void) -> Void {
            let service = ForagePANTextFieldViewService()
            return service.sendPanCardNumber(request: request, completion: completion)
    }
}
