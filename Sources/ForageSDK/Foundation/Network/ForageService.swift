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
        request: ForagePANRequest,
        completion: @escaping (Result<Data?, Error>) -> Void) -> Void
    
    func getXKey(
        bearerToken: String,
        completion: @escaping (Result<ForageXKeyModel, Error>) -> Void) -> Void
    
    func getBalance(
        request: ForageBalanceRequest,
        bearerToken: String,
        merchantID: String,
        completion: @escaping (Result<Data?, Error>) -> Void) -> Void
    
    func pollingMessage(
        message: MessageResponse,
        bearerToken: String,
        merchantID: String,
        completion: @escaping (Result<MessageResponse, Error>) -> Void) -> Void
    
    func retrieveCheckBalance(
        request: ForageBalanceRequest,
        completion: @escaping (Result<Data?, Error>) -> Void)
    
    func requestCapturePayment(
        request: ForageCaptureRequest,
        completion: @escaping (Result<Data?, Error>) -> Void)
    
    func cancelRequest()
}

internal class LiveForageService: ForageService {
    
    // MARK: Properties
    
    internal let provider = Provider()
    private var collector: VGSCollect?
    
    init(_ collector: VGSCollect?) {
        self.collector = collector
    }
    
    internal func tokenizeEBTCard(request: ForagePANRequest, completion: @escaping (Result<Data?, Error>) -> Void) {
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
        request: ForageBalanceRequest,
        bearerToken: String,
        merchantID: String,
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
                switch result {
                case .success(_, let data, _):
                    // TODO: instead of completion we gonna check message array
//                    completion(.success(data))
                    self?.parseVGSData(data: data) { [weak self] messageResponse in
                        switch messageResponse {
                        case .success(let message):
                            self?.pollingMessage(
                                message: message,
                                bearerToken: bearerToken,
                                merchantID: merchantID) { pollingResult in
                                    switch pollingResult {
                                    case .success:
                                        self?.retrieveCheckBalance(
                                            request: request,
                                            completion: completion
                                        )
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
    }
    
    internal func pollingMessage(
        message: MessageResponse,
        bearerToken: String,
        merchantID: String,
        completion: @escaping (Result<MessageResponse, Error>) -> Void) -> Void
    {
        do {
            try provider.execute(model: MessageResponse.self, endpoint: ForageAPI.message(request: message, bearerToken: bearerToken, merchantID: merchantID), completion: { [weak self] result in
                switch result {
                case .success(let data):
                    if data.failed == false && data.status == .completed {
                        autoreleasepool {
                            completion(.success(data))
                        }
                    } else if data.failed == true {
                        autoreleasepool {
                            completion(.success(data))
                        }
                    } else {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self?.pollingMessage(
                                message: data,
                                bearerToken: bearerToken,
                                merchantID: merchantID,
                                completion: completion
                            )
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
    
    internal func retrieveCheckBalance(request: ForageBalanceRequest,
                                      completion: @escaping (Result<Data?, Error>) -> Void) {
        do {
//            try provider.execute(endpoint: ForageAPI.retrieveBalance(request: request), completion: completion)
            try provider.execute(endpoint: ForageAPI.retrieveBalance(request: request), completion: { result in
                switch result {
                case .success(let data):
                    debugPrint(data)
                case .failure(let error):
                    debugPrint(error)
                }
            })
        } catch {
            completion(.failure(error))
        }
    }
    
    internal func requestCapturePayment(
        request: ForageCaptureRequest,
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
                switch result {
                case .success(_, let data, _):
                    completion(.success(data))
                case .failure(_, _, _, let error):
                    guard let error = error else {
                        return completion(.failure(ServiceError.emptyError))
                    }
                    completion(.failure(error))
                }
            }
    }
    
    private func parseVGSData(data: Data?, completion: @escaping (Result<MessageResponse, Error>) -> Void) {
        provider.processVGSData(model: MessageResponse.self, code: nil, data: data, response: nil) { resultMessage in
            switch resultMessage {
            case .success(let message):
                completion(.success(message))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
