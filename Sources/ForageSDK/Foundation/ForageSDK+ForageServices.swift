//
//  ForageSDK+ForageServices.swift
//  ForageSDK
//
//  Created by Symphony on 22/11/22.
//

import VGSCollectSDK
import Foundation

/**
 Card type
 */
private enum CardType: String {
    case ebt = "ebt"
}

/**
 Interface for Forage SDK Services
 */
protocol ForageSDKService: AnyObject {
    /// Tokenize a given EBT Card
    ///
    /// - Parameters:
    ///  - bearerToken: Authorization token.
    ///  - merchantAccount: Merchant account identifier, `merchant id`.
    ///  - userID: A unique ID for the end customer making the payment.
    ///  - completion: Which will return the result. See more [here](https://docs.joinforage.app/reference/create-payment-method-1)
    ///
    ///  - Note: If you're providing your internal user ID for `userID`, then we recommend that you hash the value before sending it on the payload. This field is optional, but omitting it causes resource action endpoints to throttle on the customer's IP.
    func tokenizeEBTCard(
        bearerToken: String,
        merchantAccount: String,
        completion: @escaping (Result<PaymentMethodModel, Error>) -> Void,
        userID: String?)
        
    /// Check balance for a given EBT Card
    ///
    /// - Parameters:
    ///  - bearerToken: Authorization token.
    ///  - merchantAccount: Merchant account identifier, `merchant id`.
    ///  - paymentMethodReference: PaymentMethod's unique reference hash
    ///  - cardNumberToken: The token field of the ``TokenizedPaymentMethod.card`` object
    ///  - completion: Which will return the result. (See more [here](https://docs.joinforage.app/reference/check-balance))
    func checkBalance(
        bearerToken: String,
        merchantAccount: String,
        paymentMethodReference: String,
        foragePinTextEdit: ForagePINTextField,
        completion: @escaping (Result<BalanceModel, Error>) -> Void)
    
    /// Capture a payment for a given payment reference
    ///
    /// - Parameters:
    ///  - bearerToken: Authorization token.
    ///  - merchantAccount: Merchant account identifier, `merchant id`.
    ///  - paymentReference: The reference hash of the payment
    ///  - cardNumberToken: The token field of the ``TokenizedPaymentMethod.card`` object
    ///  - completion: Which will return the result. (See more [here](https://docs.joinforage.app/reference/capture-payment))
    func capturePayment(
        bearerToken: String,
        merchantAccount: String,
        paymentReference: String,
        foragePinTextEdit: ForagePINTextField,
        completion: @escaping (Result<PaymentModel, Error>) -> Void)
}

extension ForageSDK: ForageSDKService {
    
    public func tokenizeEBTCard(
        bearerToken: String,
        merchantAccount: String,
        completion: @escaping (Result<PaymentMethodModel, Error>) -> Void,
        userID: String? = nil
    ) {
        let request = ForagePANRequestModel(
            authorization: bearerToken,
            merchantAccount: merchantAccount,
            panNumber: panNumber,
            type: CardType.ebt.rawValue,
            reusable: true,
            userID: userID
        )
        service?.tokenizeEBTCard(request: request, completion: completion)
    }
    
    public func checkBalance(
        bearerToken: String,
        merchantAccount: String,
        paymentMethodReference: String,
        foragePinTextEdit: ForagePINTextField,
        completion: @escaping (Result<BalanceModel, Error>) -> Void) {
            service?.getXKey(bearerToken: bearerToken, merchantAccount: merchantAccount) { result in
            switch result {
            case .success(let model):
                self.service?.getPaymentMethod(bearerToken: bearerToken, merchantAccount: merchantAccount, paymentMethodRef: paymentMethodReference) { result in
                    switch result {
                    case .success(let paymentMethod):
                        let request = ForageRequestModel(
                            authorization: bearerToken,
                            paymentMethodReference: paymentMethodReference,
                            paymentReference: "",
                            cardNumberToken: paymentMethod.card.token,
                            merchantID: merchantAccount,
                            xKey: model.alias
                        )
                        self.service?.checkBalance(pinCollector: foragePinTextEdit.collector, request: request, completion: completion)
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
        bearerToken: String,
        merchantAccount: String,
        paymentReference: String,
        foragePinTextEdit: ForagePINTextField,
        completion: @escaping (Result<PaymentModel, Error>) -> Void) {
            service?.getXKey(bearerToken: bearerToken, merchantAccount: merchantAccount) { result in
            switch result {
            case .success(let model):
                self.service?.getPayment(bearerToken: bearerToken, merchantAccount: merchantAccount, paymentRef: paymentReference) { result in
                    switch result {
                    case .success(let payment):
                        self.service?.getPaymentMethod(bearerToken: bearerToken, merchantAccount: merchantAccount, paymentMethodRef: payment.paymentMethodRef) { result in
                            switch result {
                            case .success(let paymentMethod):
                                let request = ForageRequestModel(
                                    authorization: bearerToken,
                                    paymentMethodReference: "",
                                    paymentReference: paymentReference,
                                    cardNumberToken: paymentMethod.card.token,
                                    merchantID: merchantAccount,
                                    xKey: model.alias
                                )
                                
                                self.service?.capturePayment(pinCollector: foragePinTextEdit.collector, request: request, completion: completion)
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
