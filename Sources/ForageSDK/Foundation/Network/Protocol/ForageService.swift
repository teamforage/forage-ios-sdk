//
//  ForageService.swift
//  ForageSDK
//
//  Created by Symphony on 21/11/22.
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
        completion: @escaping (Result<ForagePANResponseModel, Error>) -> Void) -> Void
    
    /// Retrieve X-key header for requests
    ///
    /// - Parameters:
    ///  - bearerToken: Authorization token.
    ///  - merchantAccount: The merchant FNS number.
    ///  - completion: Which will return the x-key object.
    func getXKey(
        bearerToken: String,
        merchantAccount: String,
        completion: @escaping (Result<ForageXKeyModel, Error>) -> Void) -> Void
    
    /// Perform request through VGS to retrieve balance
    ///
    /// - Parameters:
    ///  - pinCollector: The pin collection service
    ///  - request: `ForageRequestModel` info to request balance.
    ///  - completion: Which will return the balance object.
    func getBalance(
        pinCollector: VGSCollect,
        request: ForageRequestModel,
        completion: @escaping (Result<Data?, Error>) -> Void) -> Void
    
    /// After polling balance, this endpoint retrieves the balance object to `getBalance` callback.
    ///
    /// - Parameters:
    ///  - request: `ForageRequestModel` info to request balance.
    ///  - completion: Which will retrieve the balance object. (See more [here](https://docs.joinforage.app/reference/check-balance))
    func retrieveCheckBalance(
        request: ForageRequestModel,
        completion: @escaping (Result<Data?, Error>) -> Void)
    
    /// Perform request through VGS to capture payment
    ///
    /// - Parameters:
    ///  - pinCollector: The pin collection service
    ///  - request: `ForageRequestModel` info to request balance.
    ///  - completion: Which will return the payment object.
    func requestCapturePayment(
        pinCollector: VGSCollect,
        request: ForageRequestModel,
        completion: @escaping (Result<Data?, Error>) -> Void)
    
    /// After polling the payment, this endpoint retrieves the payment object to `requestCapturePayment` callback.
    ///
    /// - Parameters:
    ///  - request: `ForageRequestModel` info to request balance.
    ///  - completion: Which will retrieve the payment object. (See more [here](https://docs.joinforage.app/reference/capture-payment))
    func retrieveCapturedPayment(
        request: ForageRequestModel,
        completion: @escaping (Result<Data?, Error>) -> Void)
    
    /// Cancel any ongoing request
    func cancelRequest()
}
