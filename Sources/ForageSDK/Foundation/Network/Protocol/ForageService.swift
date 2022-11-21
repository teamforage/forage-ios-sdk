//
//  ForageService.swift
//  ForageSDK
//
//  Created by Symphony on 21/11/22.
//

import Foundation

internal protocol ForageService: AnyObject {
    var provider: Provider { get }
    
    func tokenizeEBTCard(
        request: ForagePANRequestModel,
        completion: @escaping (Result<Data?, Error>) -> Void) -> Void
    
    func getXKey(
        bearerToken: String,
        completion: @escaping (Result<ForageXKeyModel, Error>) -> Void) -> Void
    
    func getBalance(
        request: ForageRequestModel,
        completion: @escaping (Result<Data?, Error>) -> Void) -> Void
    
    func retrieveCheckBalance(
        request: ForageRequestModel,
        completion: @escaping (Result<Data?, Error>) -> Void)
    
    func requestCapturePayment(
        request: ForageRequestModel,
        completion: @escaping (Result<Data?, Error>) -> Void)
    
    func retrieveCapturedPayment(
        request: ForageRequestModel,
        completion: @escaping (Result<Data?, Error>) -> Void)
    
    func cancelRequest()
}
