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
    ///  - foragePanTextField: A text field capturing the PAN (Primary Account Number) of the EBT card.
    ///  - customerID: A unique ID for the end customer making the payment. We recommend that you hash this value.
    ///  - completion: The closure returns a `Result` containing either a `PaymentMethodModel` or an `Error`. [Read more](https://docs.joinforage.app/reference/create-payment-method)
    func tokenizeEBTCard(
        foragePanTextField: ForagePANTextField,
        customerID: String,
        reusable: Bool?,
        completion: @escaping (Result<PaymentMethodModel, Error>) -> Void)
    
    /// Check balance for a given EBT Card
    ///
    /// - Parameters:
    ///  - foragePinTextField: A specialized text field for securely capturing the PIN to check the balance of the EBT card.
    ///  - paymentMethodReference: PaymentMethod's unique reference hash
    ///  - completion: The closure returns a `Result` containing either a `BalanceModel` or an `Error`.
    func checkBalance(
        foragePinTextField: ForagePINTextField,
        paymentMethodReference: String,
        completion: @escaping (Result<BalanceModel, Error>) -> Void)
    
    /// Capture a payment for a given payment reference
    ///
    /// - Parameters:
    ///  - foragePinTextField: A specialized text field  for securely capturing the PIN to capture the EBT payment.
    ///  - paymentReference: The reference hash of the Payment
    ///  - completion: The closure returns a `Result` containing either a `PaymentModel` or an `Error`. [Read more](https://docs.joinforage.app/reference/capture-payment)
    func capturePayment(
        foragePinTextField: ForagePINTextField,
        paymentReference: String,
        completion: @escaping (Result<PaymentModel, Error>) -> Void)
}

extension ForageSDK: ForageSDKService {
    
    public func tokenizeEBTCard(
        foragePanTextField: ForagePANTextField,
        customerID: String,
        reusable: Bool? = true,
        completion: @escaping (Result<PaymentMethodModel, Error>) -> Void
    ) {
        _ = self.logger?
            .setPrefix("tokenizeEBTCard")
            .addContext(ForageLogContext(
                customerID: customerID,
                merchantRef: merchantID
            ))
            .notice("Called ForageSDK.shared.tokenizeEBTCard", attributes: nil)
        
        let request = ForagePANRequestModel(
            authorization: ForageSDK.shared.sessionToken,
            merchantID: ForageSDK.shared.merchantID,
            panNumber: foragePanTextField.getActualPAN(),
            type: CardType.EBT.rawValue,
            customerID: customerID,
            reusable: reusable ?? true,
            traceId: ForageSDK.shared.traceId
        )
        service?.tokenizeEBTCard(request: request, completion: completion)
    }
    
    public func checkBalance(
        foragePinTextField: ForagePINTextField,
        paymentMethodReference: String,
        completion: @escaping (Result<BalanceModel, Error>) -> Void) {
            _ = self.logger?
                .setPrefix("checkBalance")
                .addContext(ForageLogContext(
                    merchantRef: merchantID,
                    paymentMethodRef: paymentMethodReference
                ))
                .notice("Called ForageSDK.shared.checkBalance for Payment Method \(paymentMethodReference)", attributes: nil)
                        
            let sessionToken = ForageSDK.shared.sessionToken
            let merchantID = ForageSDK.shared.merchantID
            
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
                                xKey: ["vgsXKey": model.alias, "btXKey": model.bt_alias],
                                traceId: ForageSDK.shared.traceId
                            )
                            self.service?.checkBalance(pinCollector: foragePinTextField.collector!, request: request, completion: completion)
                            
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
        foragePinTextField: ForagePINTextField,
        paymentReference: String,
        completion: @escaping (Result<PaymentModel, Error>) -> Void) {
            _ = self.logger?
                .setPrefix("capturePayment")
                .addContext(ForageLogContext(
                    merchantRef: merchantID,
                    paymentRef: paymentReference
                ))
                .notice("Called ForageSDK.shared.capturePayment for Payment \(paymentReference)", attributes: nil)

            let sessionToken = ForageSDK.shared.sessionToken
            let merchantID = ForageSDK.shared.merchantID
            
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
                                        xKey: ["vgsXKey": model.alias, "btXKey": model.bt_alias],
                                        traceId: ForageSDK.shared.traceId
                                    )
                                    self.service?.capturePayment(pinCollector: foragePinTextField.collector!, request: request, completion: completion)
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
