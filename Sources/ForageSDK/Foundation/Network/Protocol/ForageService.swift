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
    /// Provider provides the interface for performing HTTP requests.
    var provider: Provider { get }
    
    /// Retrieve X-key header for requests
    ///
    /// - Parameters:
    ///  - bearerToken: Authorization token.
    ///  - merchantAccount: merchant ID.
    ///  - completion: Which will return the x-key object.
    func getXKey(
        bearerToken: String,
        merchantAccount: String,
        completion: @escaping (Result<ForageXKeyModel, Error>) -> Void) -> Void
    
    /// Perform a GET request for the PaymentMethod
    ///
    /// - Parameters:
    ///  - bearerToken: Authorization token.
    ///  - merchantAccount: merchant ID.
    ///  - paymentMethodRef: The PaymentMethod ref.
    ///  - completion: Returns the PaymentMethod
    func getPaymentMethod(
        bearerToken: String,
        merchantAccount: String,
        paymentMethodRef: String,
        completion: @escaping (Result<PaymentMethodModel, Error>) -> Void) -> Void
    
    /// Perform a GET request for the Payment
    ///
    /// - Parameters:
    ///  - bearerToken: Authorization token.
    ///  - merchantAccount: merchant ID.
    ///  - paymentRef: The Payment ref.
    ///  - completion: Returns the Payment
    func getPayment(
        bearerToken: String,
        merchantAccount: String,
        paymentRef: String,
        completion: @escaping (Result<PaymentModel, Error>) -> Void)
    
    /// Tokenize a given *ForagePANRequestModel* object
    ///
    /// - Parameters:
    ///  - request: *ForagePANRequestModel* contains ebt card object.
    ///  - completion: Returns tokenized object. (See more [here](https://docs.joinforage.app/reference/create-payment-method-1))
    func tokenizeEBTCard(
        request: ForagePANRequestModel,
        completion: @escaping (Result<PaymentMethodModel, Error>) -> Void) -> Void
    
    /// Perform request through VGS to retrieve balance
    ///
    /// - Parameters:
    ///  - pinCollector: The pin collection service
    ///  - request: `ForageRequestModel` info to request balance.
    ///  - completion: Which will return the balance object.
    func checkBalance(
        pinCollector: VaultCollector,
        request: ForageRequestModel,
        completion: @escaping (Result<BalanceModel, Error>) -> Void) -> Void
    
    /// Perform request through VGS to capture payment
    ///
    /// - Parameters:
    ///  - pinCollector: The pin collection service
    ///  - request: `ForageRequestModel` info to request balance.
    ///  - completion: Which will return the payment object.
    func capturePayment(
        pinCollector: VaultCollector,
        request: ForageRequestModel,
        completion: @escaping (Result<PaymentModel, Error>) -> Void)
}
