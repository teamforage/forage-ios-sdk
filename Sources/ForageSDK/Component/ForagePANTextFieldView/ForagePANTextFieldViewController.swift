//
//  ForagePANTextFieldViewController.swift
//  ForageSDK
//
//  Created by Symphony on 21/10/22.
//

import Foundation

protocol ForagePANTextFieldViewController: AnyObject {
    var service: ForageService { get }
    
    func sendPanCardNumber(
        request: ForagePANRequest,
        completion: @escaping (Result<ForagePANModel, Error>) -> Void) -> Void
    
    func cancelRequest()
}

internal class LiveForagePANTextFieldViewController: ForagePANTextFieldViewController {
    
    // MARK: Properties
    
    let service: ForageService = LiveForageService()
    
    // MARK: Methods
    
    internal func sendPanCardNumber(
        request: ForagePANRequest,
        completion: @escaping (Result<ForagePANModel, Error>) -> Void) -> Void {
            return service.sendPanCardNumber(request: request, completion: completion)
    }
    
    internal func cancelRequest() {
        service.cancelRequest()
    }
}
