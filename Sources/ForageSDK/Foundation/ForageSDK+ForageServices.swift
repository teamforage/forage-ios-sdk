//
//  ForageSDK+ForageServices.swift
//  ForageSDK
//
//  Created by Symphony on 22/11/22.
//

import VGSCollectSDK
import Foundation

/**
 Interface for Forage SDK Services
 */
protocol ForageSDKService: AnyObject {
    /// Tokenize a given EBT Card
    ///
    /// - Parameters:
    ///  - customerID: A unique ID for the end customer making the payment. We recommend that you hash this value.
    ///  - completion: Which will return the result. See more [here](https://docs.joinforage.app/reference/create-payment-method-1)
    func tokenizeEBTCard(
        customerID: String,
        completion: @escaping (Result<PaymentMethodModel, Error>) -> Void)
    
    /// Check balance for a given EBT Card
    ///
    /// - Parameters:
    ///  - paymentMethodReference: PaymentMethod's unique reference hash
    ///  - completion: Which will return the result. (See more [here](https://docs.joinforage.app/reference/check-balance))
    func checkBalance(
        paymentMethodReference: String,
        foragePinTextEdit: ForagePINTextField,
        completion: @escaping (Result<BalanceModel, Error>) -> Void)
    
    /// Capture a payment for a given payment reference
    ///
    /// - Parameters:
    ///  - paymentReference: The reference hash of the payment
    ///  - completion: Which will return the result. (See more [here](https://docs.joinforage.app/reference/capture-payment))
    func capturePayment(
        paymentReference: String,
        foragePinTextEdit: ForagePINTextField,
        completion: @escaping (Result<PaymentModel, Error>) -> Void)
}

extension ForageSDK: ForageSDKService {
    
    public func tokenizeEBTCard(
        customerID: String,
        completion: @escaping (Result<PaymentMethodModel, Error>) -> Void
    ) {
        let request = ForagePANRequestModel(
            authorization: self.sessionToken,
            merchantID: self.merchantID,
            panNumber: panNumber,
            type: CardType.EBT.rawValue,
            reusable: true,
            customerID: customerID
        )
        service?.tokenizeEBTCard(request: request, completion: completion)
    }
    
    public func checkBalance(
        paymentMethodReference: String,
        foragePinTextEdit: ForagePINTextField,
        completion: @escaping (Result<BalanceModel, Error>) -> Void) {
            let sessionToken = self.sessionToken
            let merchantID = self.merchantID
            
            service?.getXKey(sessionToken: sessionToken, merchantID: merchantID) { result in
                switch result {
                case .success(let model):
                    self.service?.getPaymentMethod(sessionToken: sessionToken, merchantID: merchantID, paymentMethodRef: paymentMethodReference) { result in
                        switch result {
                        case .success(let paymentMethod):
                            let request = ForageRequestModel(
                                authorization: sessionToken,
                                paymentMethodReference: paymentMethodReference,
                                paymentReference: "",
                                cardNumberToken: paymentMethod.card.token,
                                merchantID: merchantID,
                                xKey: ["vgsXKey": model.alias, "btXKey": model.bt_alias]
                            )
                            self.service?.checkBalance(pinCollector: foragePinTextEdit.collector!, request: request, completion: completion)
                            
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    
    public func capturePayment(
        paymentReference: String,
        foragePinTextEdit: ForagePINTextField,
        completion: @escaping (Result<PaymentModel, Error>) -> Void) {
            let sessionToken = self.sessionToken
            let merchantID = self.merchantID
            
            service?.getXKey(sessionToken: sessionToken, merchantID: merchantID) { result in
                switch result {
                case .success(let model):
                    self.service?.getPayment(sessionToken: sessionToken, merchantID: merchantID, paymentRef: paymentReference) { result in
                        switch result {
                        case .success(let payment):
                            self.service?.getPaymentMethod(sessionToken: sessionToken, merchantID: merchantID, paymentMethodRef: payment.paymentMethodRef) { result in
                                switch result {
                                case .success(let paymentMethod):
                                    let request = ForageRequestModel(
                                        authorization: sessionToken,
                                        paymentMethodReference: "",
                                        paymentReference: paymentReference,
                                        cardNumberToken: paymentMethod.card.token,
                                        merchantID: merchantID,
                                        xKey: ["vgsXKey": model.alias, "btXKey": model.bt_alias]
                                    )
                                    self.service?.capturePayment(pinCollector: foragePinTextEdit.collector!, request: request, completion: completion)
                                case .failure(let error):
                                    completion(.failure(error))
                                }
                            }
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
}
