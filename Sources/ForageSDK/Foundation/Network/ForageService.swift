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
    
    func pollingMessage(
        message: MessageResponseModel,
        bearerToken: String,
        merchantID: String,
        completion: @escaping (Result<MessageResponseModel, Error>) -> Void) -> Void
    
    func cancelRequest()
}

internal protocol Polling: AnyObject {
    func polling(
        _ pinType: PinType,
        response: VGSResponse,
        request: ForageRequestModel,
        completion: @escaping (Result<Data?, Error>) -> Void)
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
    
    internal func tokenizeEBTCard(request: ForagePANRequestModel, completion: @escaping (Result<Data?, Error>) -> Void) {
        do {
            try provider.execute(endpoint: ForageAPI.panNumber(request: request), completion: { result in
                switch result {
                case .success(let data): completion(.success(data))
                case .failure(let error): completion(.failure(error))
                }
            })
        } catch {
            completion(.failure(error))
        }
    }
    
    internal func getXKey(bearerToken: String, completion: @escaping (Result<ForageXKeyModel, Error>) -> Void)
    {
        do {
            try provider.execute(model: ForageXKeyModel.self, endpoint: ForageAPI.xKey(bearerToken: bearerToken), completion: { result in
                switch result {
                case .success(let data):
                    completion(.success(data))
                case .failure(let error):
                    completion(.failure(error))
                }
            })
        } catch {
            completion(.failure(error))
        }
    }
    
    internal func cancelRequest() {
        provider.stopRequestOnGoing()
    }
    
    // MARK: Implementations
    
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
                self?.polling(.balance, response: result, request: request, completion: { pollingResult in
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
            try provider.execute(endpoint: ForageAPI.retrieveBalance(request: request), completion: { result in
                completion(result)
            })
        } catch {
            completion(.failure(error))
        }
    }
    
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
                self.polling(.snap, response: result, request: request, completion: { pollingResult in
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
        do {
            try provider.execute(endpoint: ForageAPI.retrieveCapturedPayment(request: request), completion: { result in
                completion(result)
            })
        } catch {
            completion(.failure(error))
        }
    }
    
    // TODO: SYM-80 Polish polling message
    internal func pollingMessage(
        message: MessageResponseModel,
        bearerToken: String,
        merchantID: String,
        completion: @escaping (Result<MessageResponseModel, Error>) -> Void) -> Void
    {
        var retryCount = 0
        do {
            try provider.execute(model: MessageResponseModel.self, endpoint: ForageAPI.message(request: message, bearerToken: bearerToken, merchantID: merchantID), completion: { [weak self] result in
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
                                bearerToken: bearerToken,
                                merchantID: merchantID,
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

extension LiveForageService: Polling {
    func polling(_ pinType: PinType, response: VGSResponse, request: ForageRequestModel, completion: @escaping (Result<Data?, Error>) -> Void) {
        switch response {
        case .success(_, let data, _):
            // TODO: SYM-81 - Padronize implementation for message, remove this IF-ELSE, keep only the implementation inside this IF
            if pinType == .balance {
                
                self.parseVGSData(model: MessageResponseModel.self, data: data) { [weak self] messageResponse in
                    switch messageResponse {
                    case .success(let message):
                        self?.pollingMessage(
                            message: message,
                            bearerToken: request.authorization,
                            merchantID: request.merchantID) { pollingResult in
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
                
            } else {
                self.parseVGSData(model: MessageBigModel.self, data: data) { [weak self] messageResponse in
                    switch messageResponse {
                    case .success(let message):
                        self?.pollingMessage(
                            message: message.message,
                            bearerToken: request.authorization,
                            merchantID: request.merchantID) { pollingResult in
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
            }

        case .failure(_, _, _, let error):
            guard let error = error else {
                return completion(.failure(ServiceError.emptyError))
            }
            completion(.failure(error))
        }
    }
}

// MARK: - Parse VGS Data

extension LiveForageService {
    private func parseVGSData<T: Decodable>(model: T.Type, data: Data?, completion: @escaping (Result<T, Error>) -> Void) {
        provider.processVGSData(model: model, code: nil, data: data, response: nil) { resultMessage in
            switch resultMessage {
            case .success(let message):
                // TODO: SYM-80 Handle success of all messages before moving on, or any error (check rules)
                completion(.success(message))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
