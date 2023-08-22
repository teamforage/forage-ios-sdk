//
//  ForageSDK+ForageServices.swift
//  ForageSDK
//
//  Created by Symphony on 22/11/22.
//

import Foundation

/**
 Interface for Forage SDK Services
 */
protocol ForageSDKService: AnyObject {
    /// Tokenize a given EBT Card
    ///
    /// - Parameters:
    ///  - bearerToken: Authorization token.
    ///  - merchantAccount: Merchant account identifier, `merchant id`.
    ///  - customerID: A unique ID for the end customer making the payment. We recommend that you hash this value.
    ///  - completion: Which will return the result. See more [here](https://docs.joinforage.app/reference/create-payment-method-1)
    func tokenizeEBTCard(
        bearerToken: String,
        merchantAccount: String,
        customerID: String,
        reusable: Bool?,
        completion: @escaping (Result<PaymentMethodModel, Error>) -> Void)
    
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
        customerID: String,
        reusable: Bool? = true,
        completion: @escaping (Result<PaymentMethodModel, Error>) -> Void
    ) {
        _ = self.logger?
            .setPrefix("tokenizeEBTCard")
            .addContext(ForageLogContext(
                customerID: customerID,
                merchantRef: merchantAccount
            ))
            .notice("Called ForageSDK.shared.tokenizeEBTCard", attributes: nil)
        
        let request = ForagePANRequestModel(
            authorization: bearerToken,
            merchantAccount: merchantAccount,
            panNumber: panNumber,
            type: CardType.EBT.rawValue,
            customerID: customerID,
            reusable: reusable ?? true
        )
        service?.tokenizeEBTCard(request: request, completion: completion)
    }
    
    public func checkBalance(
        bearerToken: String,
        merchantAccount: String,
        paymentMethodReference: String,
        foragePinTextEdit: ForagePINTextField,
        completion: @escaping (Result<BalanceModel, Error>) -> Void) {
            _ = self.logger?
                .setPrefix("checkBalance")
                .addContext(ForageLogContext(
                    merchantRef: merchantAccount,
                    paymentMethodRef: paymentMethodReference
                ))
                .notice("Called ForageSDK.shared.checkBalance for Payment Method \(paymentMethodReference)", attributes: nil)
            
            foragePinTextEdit.disable()
            
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
                                xKey: ["vgsXKey": model.alias, "btXKey": model.bt_alias]
                            )
                            self.service?.checkBalance(pinCollector: foragePinTextEdit.collector!, request: request) { result in
                                foragePinTextEdit.handleSubmissionCompletion()
                                completion(result)
                            }
                            
                        case .failure(let error):
                            foragePinTextEdit.handleSubmissionCompletion()
                            completion(.failure(error))
                        }
                    }
                case .failure(let error):
                    foragePinTextEdit.handleSubmissionCompletion()
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
            _ = self.logger?
                .setPrefix("capturePayment")
                .addContext(ForageLogContext(
                    merchantRef: merchantAccount,
                    paymentRef: paymentReference
                ))
                .notice("Called ForageSDK.shared.capturePayment for Payment \(paymentReference)", attributes: nil)
            
            foragePinTextEdit.disable()
            
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
                                        xKey: ["vgsXKey": model.alias, "btXKey": model.bt_alias]
                                    )
                                    self.service?.capturePayment(pinCollector: foragePinTextEdit.collector!, request: request) { result in
                                        foragePinTextEdit.handleSubmissionCompletion()
                                        completion(result)
                                    }
                                case .failure(let error):
                                    foragePinTextEdit.handleSubmissionCompletion()
                                    completion(.failure(error))
                                }
                            }
                        case .failure(let error):
                            foragePinTextEdit.handleSubmissionCompletion()
                            completion(.failure(error))
                        }
                    }
                case .failure(let error):
                    foragePinTextEdit.handleSubmissionCompletion()
                    completion(.failure(error))
                }
            }
        }
}
