//
//  ForageService.swift
//  ForageSDK
//
//  Created by Symphony on 30/10/22.
//

import Foundation
import VGSCollectSDK

internal protocol ForageService: AnyObject {
    var provider: Provider { get }
    
    func tokenizeEBTCard(
        request: ForagePANRequestModel,
        completion: @escaping (Result<Data?, Error>) -> Void) -> Void
    
    func getXKey(
        bearerToken: String,
        completion: @escaping (Result<ForageXKeyModel, Error>) -> Void) -> Void
    
    func getBalance(
        request: ForageRequestModel,
        completion: @escaping (Result<Data?, Error>) -> Void) -> Void
    
    func retrieveCheckBalance(
        request: ForageRequestModel,
        completion: @escaping (Result<Data?, Error>) -> Void)
    
    func requestCapturePayment(
        request: ForageRequestModel,
        completion: @escaping (Result<Data?, Error>) -> Void)
    
    func retrieveCapturedPayment(
        request: ForageRequestModel,
        completion: @escaping (Result<Data?, Error>) -> Void)
    
    func cancelRequest()
}

internal protocol Polling: AnyObject {
    func polling(
        response: VGSResponse,
        request: ForageRequestModel,
        completion: @escaping (Result<Data?, Error>) -> Void)
    
    func pollingMessage(
        message: MessageResponseModel,
        request: ForageRequestModel,
        completion: @escaping (Result<MessageResponseModel, Error>) -> Void) -> Void
}

internal class LiveForageService: ForageService {
    
    // MARK: Properties
    
    internal let provider = Provider()
    private var collector: VGSCollect?
    private var maxAttempts: Int = 10
    private var intervalBetweenAttempts: Double = 1.0
    
    init(_ collector: VGSCollect?) {
        self.collector = collector
    }
    
    // MARK: Tokenize EBT card
    
    internal func tokenizeEBTCard(request: ForagePANRequestModel, completion: @escaping (Result<Data?, Error>) -> Void) {
        do { try provider.execute(endpoint: ForageAPI.panNumber(request: request), completion: completion) }
        catch { completion(.failure(error)) }
    }
    
    // MARK: X-key
    
    internal func getXKey(bearerToken: String, completion: @escaping (Result<ForageXKeyModel, Error>) -> Void) {
        do { try provider.execute(model: ForageXKeyModel.self, endpoint: ForageAPI.xKey(bearerToken: bearerToken), completion: completion) }
        catch { completion(.failure(error)) }
    }
    
    // MARK: Cancel request
    
    internal func cancelRequest() { provider.stopRequestOnGoing() }
    
    // MARK: Check balance
    
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
    
    internal func retrieveCheckBalance(request: ForageRequestModel,
                                       completion: @escaping (Result<Data?, Error>) -> Void) {
        do {
            try provider.execute(endpoint: ForageAPI.retrieveBalance(request: request), completion: completion)
        } catch {
            completion(.failure(error))
        }
    }
    
    // MARK: Capture payment
    
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
    internal func polling(response: VGSResponse, request: ForageRequestModel, completion: @escaping (Result<Data?, Error>) -> Void) {
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
    
    internal func pollingMessage(
        message: MessageResponseModel,
        request: ForageRequestModel,
        completion: @escaping (Result<MessageResponseModel, Error>) -> Void) -> Void
    {
        var retryCount = 0
        do {
            try provider.execute(model: MessageResponseModel.self, endpoint: ForageAPI.message(request: message, bearerToken: request.authorization, merchantID: request.merchantID), completion: { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let data):
                    if data.failed == false && data.status == .completed {
                        autoreleasepool {
                            completion(.success(data))
                        }
                    } else if data.failed == true {
                        autoreleasepool {
                            completion(.failure(NSError(domain: "Message failed", code: 001, userInfo: nil)))
                        }
                    } else if retryCount < self.maxAttempts {
                        retryCount += 1
                        DispatchQueue.main.asyncAfter(deadline: .now() + self.intervalBetweenAttempts) {
                            self.pollingMessage(
                                message: data,
                                request: request,
                                completion: completion
                            )
                        }
                    } else {
                        autoreleasepool {
                            completion(.failure(NSError(domain: "Reached max attempts", code: 002, userInfo: nil)))
                        }
                    }
                    
                case .failure(let error):
                    autoreleasepool {
                        completion(.failure(error))
                    }
                }
            })
        } catch {
            completion(.failure(error))
        }
    }
}
