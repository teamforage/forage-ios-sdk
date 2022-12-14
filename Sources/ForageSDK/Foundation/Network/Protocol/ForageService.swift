//
//  ForageService.swift
//  ForageSDK
//
//  Created by Symphony on 30/10/22.
//

import Foundation
import VGSCollectSDK

/**
 Interface for internal Forage SDK requests
 */
internal protocol ForageService: AnyObject {
    /// Provider provides the interface for perform url requests.
    var provider: Provider { get }
    
    /// Tokenize a given *ForagePANRequestModel* object
    ///
    /// - Parameters:
    ///  - request: *ForagePANRequestModel* contains ebt card object.
    ///  - completion: Returns tokenized object. (See more [here](https://docs.joinforage.app/reference/create-payment-method-1))
    func tokenizeEBTCard(
        request: ForagePANRequestModel,
        completion: @escaping (Result<Data?, Error>) -> Void) -> Void
    
    /// Retrieve X-key header for requests
    ///
    /// - Parameters:
    ///  - bearerToken: Authorization token.
    ///  - completion: Which will return the x-key object.
    func getXKey(
        bearerToken: String,
        completion: @escaping (Result<ForageXKeyModel, Error>) -> Void) -> Void
    
    /// Perform request through VGS to retrieve balance
    ///
    /// - Parameters:
    ///  - request: `ForageRequestModel` info to request balance.
    ///  - completion: Which will return the balance object.
    func getBalance(
        request: ForageRequestModel,
        completion: @escaping (Result<Data?, Error>) -> Void) -> Void
    
    /// Perform request through VGS to capture payment
    ///
    /// - Parameters:
    ///  - request: `ForageRequestModel` info to request balance.
    ///  - completion: Which will return the payment object.
    func requestCapturePayment(
        request: ForageRequestModel,
        completion: @escaping (Result<Data?, Error>) -> Void)
    
    /// Cancel any ongoing request
    func cancelRequest()
}
