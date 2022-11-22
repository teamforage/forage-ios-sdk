//
//  ForageService.swift
//  ForageSDK
//
//  Created by Symphony on 30/10/22.
//

import Foundation
import VGSCollectSDK

internal class LiveForageService: ForageService {
    
    // MARK: Properties
    
    internal let provider = Provider()
    private var collector: VGSCollect?
    private var maxAttempts: Int = 10
    private var intervalBetweenAttempts: Double = 1.0
    private var retryCount = 0
    
    init(_ collector: VGSCollect?) {
        self.collector = collector
    }
    
    // MARK: Tokenize EBT card
    
    /// Tokenize a given *ForagePANRequestModel* object
    ///
    /// - Parameters:
    ///  - request: *ForagePANRequestModel* contains ebt card object.
    ///  - completion: Returns tokenized object.
    internal func tokenizeEBTCard(request: ForagePANRequestModel, completion: @escaping (Result<Data?, Error>) -> Void) {
        do { try provider.execute(endpoint: ForageAPI.tokenizeNumber(request: request), completion: completion) }
        catch { completion(.failure(error)) }
    }
    
    // MARK: X-key
    
    /// Retrieve from ForageAPI the X-Key header to perform request.
    ///
    /// - Parameters:
    ///  - bearerToken: Session authorization token.
    ///  - completion: Returns *ForageXKeyModel* object.
    internal func getXKey(bearerToken: String, completion: @escaping (Result<ForageXKeyModel, Error>) -> Void) {
        do { try provider.execute(model: ForageXKeyModel.self, endpoint: ForageAPI.xKey(bearerToken: bearerToken), completion: completion) }
        catch { completion(.failure(error)) }
    }
    
    // MARK: Cancel request
    
    /// Cancel any ongoing request.
    internal func cancelRequest() { provider.stopRequestOnGoing() }
    
    // MARK: Check balance
    
    /// Perform VGS SDK request to retrieve balance.
    ///
    /// - Parameters:
    ///  - request: Model element with data to perform request.
    ///  - completion: Returns balance object.
    internal func getBalance(
        request: ForageRequestModel,
        completion: @escaping (Result<Data?, Error>) -> Void) -> Void
    {
        collector?.customHeaders = [
            "X-KEY": request.xKey,
            "IDEMPOTENCY-KEY": UUID.init().uuidString,
            "Merchant-Account": request.merchantID
        ]

        let extraData = [
            "card_number_token": request.cardNumberToken
        ]

        collector?.sendData(
            path: "/api/payment_methods/\(request.paymentMethodReference)/balance/",
            extraData: extraData) { [weak self] result in
                self?.polling(response: result, request: request, completion: { pollingResult in
                    switch pollingResult {
                    case .success:
                        self?.retrieveCheckBalance(
                            request: request,
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
    internal func retrieveCheckBalance(request: ForageRequestModel,
                                       completion: @escaping (Result<Data?, Error>) -> Void) {
        do {
            try provider.execute(endpoint: ForageAPI.retrieveBalance(request: request), completion: completion)
        } catch {
            completion(.failure(error))
        }
    }
    
    // MARK: Capture payment
    
    /// Perform VGS SDK request to capture payment.
    ///
    /// - Parameters:
    ///  - request: Model element with data to perform request.
    ///  - completion: Returns captured payment object.
    internal func requestCapturePayment(
        request: ForageRequestModel,
        completion: @escaping (Result<Data?, Error>) -> Void)
    {
        collector?.customHeaders = [
            "X-KEY": request.xKey,
            "IDEMPOTENCY-KEY": request.paymentReference,
            "Merchant-Account": request.merchantID
        ]

        let extraData = [
            "card_number_token": request.cardNumberToken
        ]

        collector?.sendData(
            path: "/api/payments/\(request.paymentReference)/capture/",
            extraData: extraData) { result in
                self.polling(response: result, request: request, completion: { pollingResult in
                    switch pollingResult {
                    case .success:
                        self.retrieveCapturedPayment(
                            request: request,
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
    ///  - completion: Returns captured payment object.
    internal func retrieveCapturedPayment(
        request: ForageRequestModel,
        completion: @escaping (Result<Data?, Error>) -> Void)
    {
        do { try provider.execute(endpoint: ForageAPI.retrieveCapturedPayment(request: request), completion: completion) }
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
        case .success(_, let data, _):
            provider.processVGSData(model: MessageResponseModel.self, code: nil, data: data, response: nil) { [weak self] messageResponse in
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

        case .failure(_, _, _, let error):
            guard let error = error else {
                return completion(.failure(ServiceError.emptyError))
            }
            completion(.failure(error))
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
                    if data.failed == false && data.status == .completed {
                        completion(.success(data))
                    /// check message is failed to return error immediately
                    } else if data.failed == true {
                        completion(.failure(NSError(domain: "Message failed", code: 001, userInfo: nil)))
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
                        completion(.failure(NSError(domain: "Reached max attempts", code: 429, userInfo: nil)))
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