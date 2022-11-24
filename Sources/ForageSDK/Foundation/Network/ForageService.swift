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
        completion: @escaping (Result<Data?, Error>) -> Void) -> Void
    
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
    
    internal func getXKey(bearerToken: String, completion: @escaping (Result<ForageXKeyModel, Error>) -> Void) {
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
        completion: @escaping (Result<Data?, Error>) -> Void) -> Void {
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
                extraData: extraData) { result in
                    switch result {
                    case .success(_, let data, _):
                        completion(.success(data))
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
                    return completion(.success(data))
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
    }
}
