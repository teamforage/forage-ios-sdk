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
    
    private var logger: ForageLogger?
    private var maxAttempts: Int = 10
    private var intervalBetweenAttempts: Double = 1.0
    private var retryCount = 0
    
    init(provider: Provider = Provider(), logger: ForageLogger? = nil) {
        self.provider = provider
        self.logger = logger?.setPrefix("")
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
    ///  - sessionToken: Session authorization token.
    ///  - completion: Returns *ForageXKeyModel* object.
    internal func getXKey(sessionToken: String, merchantID: String, completion: @escaping (Result<ForageXKeyModel, Error>) -> Void) {
        do { try provider.execute(model: ForageXKeyModel.self, endpoint: ForageAPI.xKey(sessionToken: sessionToken, merchantID: merchantID), completion: completion) }
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
        pinCollector: VaultCollector,
        request: ForageRequestModel,
        completion: @escaping (Result<BalanceModel, Error>) -> Void) -> Void
    {
        let paymentMethodRef = request.paymentMethodReference
        self.logger?.info("Polling for balance check response for Payment Method \(paymentMethodRef)", attributes: nil)
        
        pinCollector.setCustomHeaders(headers: [
            "IDEMPOTENCY-KEY": UUID.init().uuidString,
            "Merchant-Account": request.merchantID,
            "x-datadog-trace-id": ForageSDK.shared.traceId
        ], xKey: request.xKey)

        let extraData = [
            "card_number_token": request.cardNumberToken
        ]

        pinCollector.sendData(
            path: "/api/payment_methods/\(request.paymentMethodReference)/balance/",
            vaultAction: VaultAction.balanceCheck,
            extraData: extraData) { [weak self] result in
                self?.polling(response: result, request: request, completion: { pollingResult in
                    switch pollingResult {
                    case .success:
                        self?.getPaymentMethod(
                            sessionToken: request.authorization,
                            merchantID: request.merchantID,
                            paymentMethodRef: request.paymentMethodReference,
                            completion: { paymentMethodResult in
                                switch paymentMethodResult {
                                case .success(let paymentMethod):
                                    if (paymentMethod.balance == nil) {
                                        let forageError = ForageError(errors:[ForageErrorObj(httpStatusCode: 500, code:"invalid_data", message:"Invalid Data")])
                                        self?.logger?.error(
                                            "Balance check failed for Payment Method \(paymentMethodRef). Balance not attached",
                                            error: forageError,
                                            attributes: nil
                                        )
                                        
                                        completion(.failure(forageError))
                                        return
                                    }
                                    self?.logger?.notice(
                                        "Balance check succeeded for Payment Method \(paymentMethodRef)",
                                        attributes: nil
                                    )
                                    completion(.success(paymentMethod.balance!))
                                case .failure(let error):
                                    completion(.failure(error))
                                }
                                
                            }
                        )
                    case .failure(let error):
                        self?.logger?.error(
                            "Balance check failed for Payment Method \(paymentMethodRef)",
                            error: error,
                            attributes: nil
                        )
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
    internal func getPaymentMethod(sessionToken: String, merchantID: String, paymentMethodRef: String, completion: @escaping (Result<PaymentMethodModel, Error>) -> Void) {
        do { try provider.execute(model: PaymentMethodModel.self, endpoint: ForageAPI.getPaymentMethod(sessionToken: sessionToken, merchantID: merchantID, paymentMethodRef: paymentMethodRef), completion: completion) }
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
        pinCollector: VaultCollector,
        request: ForageRequestModel,
        completion: @escaping (Result<PaymentModel, Error>) -> Void)
    {
        pinCollector.setCustomHeaders(headers: [
            "IDEMPOTENCY-KEY": UUID.init().uuidString,
            "Merchant-Account": request.merchantID,
            "x-datadog-trace-id": ForageSDK.shared.traceId
        ], xKey: request.xKey)

        let extraData = [
            "card_number_token": request.cardNumberToken
        ]

        pinCollector.sendData(
            path: "/api/payments/\(request.paymentReference)/capture/",
            vaultAction: VaultAction.capture,
            extraData: extraData) { [weak self] result in
                self?.polling(response: result, request: request, completion: { pollingResult in
                    switch pollingResult {
                    case .success:
                        self?.getPayment(
                            sessionToken: request.authorization,
                            merchantID: request.merchantID,
                            paymentRef: request.paymentReference,
                            completion: { [weak self] paymentResult in
                                switch paymentResult {
                                case .success(let payment):
                                    self?.logger?.notice("Capture succeeded for Payment \(request.paymentReference)", attributes: nil)
                                    completion(.success(payment))
                                case .failure(let error):
                                    self?.logger?.error("Capture failed for Payment \(request.paymentReference)", error: error, attributes: nil)
                                    completion(.failure(error))
                                }
                            }
                        )
                    case .failure(let error):
                        self?.logger?.error(
                            "Capture failed for Payment \(request.paymentReference)",
                            error: error,
                            attributes: nil
                        )
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
    internal func getPayment(sessionToken: String, merchantID: String, paymentRef: String, completion: @escaping (Result<PaymentModel, Error>) -> Void) {
        do { try provider.execute(model: PaymentModel.self, endpoint: ForageAPI.getPayment(sessionToken: sessionToken, merchantID: merchantID, paymentRef: paymentRef), completion: completion) }
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
    internal func polling(response: VaultResponse, request: ForageRequestModel, completion: @escaping (Result<Data?, Error>) -> Void) {
        retryCount = 0
        
        if let error = response.error {
            completion(.failure(error))
        } else if let data = response.data, let urlResponse = response.urlResponse {
            provider.processVGSData(model: MessageResponseModel.self, code: response.statusCode, data: data, response: urlResponse) { [weak self] messageResponse in
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
                    self?.logger?.error("Failed to process vault proxy response for \(self?.getLogSuffix(request) ?? "N/A")", error: error, attributes: nil)
                    completion(.failure(error))
                }
            }
        } else {
            let emptyError = ServiceError.emptyError
            logger?.error(emptyError.rawValue, error: emptyError, attributes: nil)
            completion(.failure(emptyError))
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
            try provider.execute(model: MessageResponseModel.self, endpoint: ForageAPI.message(request: message, sessionToken: request.authorization, merchantID: request.merchantID), completion: { [weak self] result in
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
                        let details = error.details
                        let forageError = ForageError(errors: [
                            ForageErrorObj(
                                httpStatusCode: statusCode,
                                code: forageErrorCode,
                                message: message,
                                details: details
                            )
                        ])
                        
                        self.logger?.error(
                            "Received SQS Error message for \(self.getLogSuffix(request))",
                            error: forageError,
                            attributes: nil)
                        completion(.failure(forageError))
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
                        self.logger?.error(
                            "Max polling attempts reached for \(self.getLogSuffix(request))",
                            error: nil,
                            attributes: nil
                        )
                        completion(.failure(ForageError(errors: [ForageErrorObj(httpStatusCode: 500, code: "unknown_server_error", message: "Unknown Server Error")])))
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
    
    // get the log suffix (action + resource name + resource ref)
    // using the given ForageRequestModel
    private func getLogSuffix(_ request: ForageRequestModel) -> String {
        let paymentReference = request.paymentMethodReference
        let paymentMethodReference = request.paymentMethodReference
        
        if !paymentReference.isEmpty {
            return "capture of Payment \(paymentReference)"
        }
        return "balance check of Payment Method \(paymentMethodReference)"
    }
}
