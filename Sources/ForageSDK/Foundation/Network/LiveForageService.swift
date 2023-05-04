//
//  LiveForageService.swift
//  ForageSDK
//
//  Created by Symphony on 30/10/22.
//

import Foundation
import VGSCollectSDK

internal class LiveForageService: ForageService {
    // MARK: Properties
    
    internal var provider: Provider
    private var maxAttempts: Int = 10
    private var intervalBetweenAttempts: Double = 1.0
    private var retryCount = 0
    
    init(provider: Provider = Provider()) {
        self.provider = provider
    }
    
    // MARK: Tokenize EBT card
    
    /// Tokenize a given *ForagePANRequestModel* object
    ///
    /// - Parameters:
    ///  - request: *ForagePANRequestModel* contains ebt card object.
    ///  - completion: Returns tokenized object.
    internal func tokenizeEBTCard(request: ForagePANRequestModel, completion: @escaping (Result<PaymentMethodModel, Error>) -> Void) {
        do {
            try provider.execute(model: PaymentMethodModel.self, endpoint: ForageAPI.tokenizeNumber(request: request), completion: completion) }
        catch { completion(.failure(error)) }
    }
    
    // MARK: X-key
    
    /// Retrieve from ForageAPI the X-Key header to perform request.
    ///
    /// - Parameters:
    ///  - bearerToken: Session authorization token.
    ///  - completion: Returns *ForageXKeyModel* object.
    internal func getXKey(bearerToken: String, merchantAccount: String, completion: @escaping (Result<ForageXKeyModel, Error>) -> Void) {
        do { try provider.execute(model: ForageXKeyModel.self, endpoint: ForageAPI.xKey(bearerToken: bearerToken, merchantAccount: merchantAccount), completion: completion) }
        catch { completion(.failure(error)) }
    }
    
    // MARK: Check balance
    
    /// Perform VGS SDK request to retrieve balance.
    ///
    /// - Parameters:
    ///  - pinCollector: The pin collection service
    ///  - request: Model element with data to perform request.
    ///  - completion: Returns BalanceModel.
    internal func checkBalance(
        pinCollector: VGSCollect,
        request: ForageRequestModel,
        completion: @escaping (Result<BalanceModel, Error>) -> Void) -> Void
    {
        pinCollector.customHeaders = [
            "X-KEY": request.xKey,
            "IDEMPOTENCY-KEY": UUID.init().uuidString,
            "Merchant-Account": request.merchantID
        ]

        let extraData = [
            "card_number_token": request.cardNumberToken
        ]

        pinCollector.sendData(
            path: "/api/payment_methods/\(request.paymentMethodReference)/balance/",
            extraData: extraData) { [weak self] result in
                self?.polling(response: result, request: request, completion: { pollingResult in
                    switch pollingResult {
                    case .success:
                        self?.getPaymentMethod(
                            bearerToken: request.authorization,
                            merchantAccount: request.merchantID,
                            paymentMethodRef: request.paymentMethodReference,
                            completion: { paymentMethodResult in
                                switch paymentMethodResult {
                                case .success(let paymentMethod):
                                    if (paymentMethod.balance == nil) {
                                        completion(.failure(ForageError(errors:[ForageErrorObj(httpStatusCode: 500, code:"invalid_data", message:"Invalid Data")])))
                                        return
                                    }
                                    completion(.success(paymentMethod.balance!))
                                case .failure(let error):
                                    completion(.failure(error))
                                }
                                
                            }
                        )
                    case .failure(let error):
                        completion(.failure(error))
                    }
                })
            }
    }
    
    /// Perform request to Forage API after polling got message success.
    ///
    /// - Parameters:
    ///  - request: Model element with data to perform request.
    ///  - completion: Returns balance object.
    internal func getPaymentMethod(bearerToken: String, merchantAccount: String, paymentMethodRef: String, completion: @escaping (Result<PaymentMethodModel, Error>) -> Void) {
        do { try provider.execute(model: PaymentMethodModel.self, endpoint: ForageAPI.getPaymentMethod(bearerToken: bearerToken, merchantAccount: merchantAccount, paymentMethodRef: paymentMethodRef), completion: completion) }
        catch { completion(.failure(error)) }
    }
    
    // MARK: Capture payment
    
    /// Perform VGS SDK request to capture payment.
    ///
    /// - Parameters:
    ///  - pinCollector: The pin collection service
    ///  - request: Model element with data to perform request.
    ///  - completion: Returns captured payment object.
    internal func capturePayment(
        pinCollector: VGSCollect,
        request: ForageRequestModel,
        completion: @escaping (Result<PaymentModel, Error>) -> Void)
    {
        pinCollector.customHeaders = [
            "X-KEY": request.xKey,
            "IDEMPOTENCY-KEY": request.paymentReference,
            "Merchant-Account": request.merchantID
        ]

        let extraData = [
            "card_number_token": request.cardNumberToken
        ]

        pinCollector.sendData(
            path: "/api/payments/\(request.paymentReference)/capture/",
            extraData: extraData) { [weak self] result in
                self?.polling(response: result, request: request, completion: { pollingResult in
                    switch pollingResult {
                    case .success:
                        self?.getPayment(
                            bearerToken: request.authorization,
                            merchantAccount: request.merchantID,
                            paymentRef: request.paymentReference,
                            completion: completion
                        )
                    case .failure(let error):
                        completion(.failure(error))
                    }
                })
            }
    }
    
    /// Perform request to Forage API after polling got message success.
    ///
    /// - Parameters:
    ///  - request: Model element with data to perform request.
    ///  - completion: Returns balance object.
    internal func getPayment(bearerToken: String, merchantAccount: String, paymentRef: String, completion: @escaping (Result<PaymentModel, Error>) -> Void) {
        do { try provider.execute(model: PaymentModel.self, endpoint: ForageAPI.getPayment(bearerToken: bearerToken, merchantAccount: merchantAccount, paymentRef: paymentRef), completion: completion) }
        catch { completion(.failure(error)) }
    }
}

// MARK: - Polling

extension LiveForageService: Polling {
    /// Process VGSData for polling message.
    ///
    /// - Parameters:
    ///  - response: The *VGSResponse* which contains the result from VGS SDK.
    ///  - request: Model element with data to perform request.
    ///  - completion: Which will return the result.
    internal func polling(response: VGSResponse, request: ForageRequestModel, completion: @escaping (Result<Data?, Error>) -> Void) {
        retryCount = 0
        
        switch response {
        case .success(_, let data, let response):
            provider.processVGSData(model: MessageResponseModel.self, code: nil, data: data, response: response) { [weak self] messageResponse in
                switch messageResponse {
                case .success(let message):
                    self?.pollingMessage(
                        message: message,
                        request: request) { pollingResult in
                            switch pollingResult {
                            case .success:
                                completion(.success(nil))
                            case .failure(let error):
                                completion(.failure(error))
                            }
                        }
                case .failure(let error):
                    completion(.failure(error))
                }
            }

        case .failure(let code, let data, let response, let error):
            if let data = data {
                self.provider.processVGSData(
                    model: ForageServiceError.self,
                    code: code,
                    data: data,
                    response: response) { errorResult in
                    switch errorResult {
                    case .success(let errorParsed):
                        return completion(.failure(errorParsed))
                    case .failure(let error):
                        return completion(.failure(error))
                    }
                }
            } else if let error = error {
                return completion(.failure(error))
            } else {
                return completion(.failure(ServiceError.emptyError))
            }
        }
    }
    
    /// Polls message to check payment status
    ///
    /// - Parameters:
    ///  - message: The *MessageResponseModel* which contains the message.
    ///  - request: Model element with data to perform request.
    ///  - completion: Which will return the message for another retry or success.
    internal func pollingMessage(
        message: MessageResponseModel,
        request: ForageRequestModel,
        completion: @escaping (Result<MessageResponseModel, Error>) -> Void) -> Void
    {
        do {
            try provider.execute(model: MessageResponseModel.self, endpoint: ForageAPI.message(request: message, bearerToken: request.authorization, merchantID: request.merchantID), completion: { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let data):
                    /// check message is not failed and is completed
                    if data.failed == false && data.status == "completed" {
                        completion(.success(data))
                    /// check message is failed to return error immediately
                    } else if data.failed == true {
                        /// Parse the error returned from SQS message and return it back
                        let error = data.errors[0]
                        let statusCode = error.statusCode
                        let forageErrorCode = error.forageCode
                        let message = error.message
                        completion(.failure(ForageError(errors:[ForageErrorObj(httpStatusCode:statusCode, code:forageErrorCode, message:message)])))
                    /// check maxAttempts to retry
                    } else if self.retryCount < self.maxAttempts {
                        self.waitNextAttempt {
                            self.pollingMessage(
                                message: data,
                                request: request,
                                completion: completion
                            )
                        }
                    /// in case run out of attempts
                    } else {
                        completion(.failure(ForageError(errors:[ForageErrorObj(httpStatusCode:500, code:"unknown_server_error", message:"Unknown Server Error")])))
                    }
                    
                case .failure(let error):
                    completion(.failure(error))
                }
            })
        } catch {
            completion(.failure(error))
        }
    }
    
    /// Support function to update retry count and interval between attempts.
    ///
    /// - Parameters:
    ///  - completion: Which will return after an wait.
    private func waitNextAttempt(completion: @escaping () -> ()) {
        retryCount = retryCount + 1
        DispatchQueue.main.asyncAfter(deadline: .now() + self.intervalBetweenAttempts) {
            completion()
        }
    }
}
