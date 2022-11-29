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
    private var collector: VGSCollect?

    init(_ collector: VGSCollect?, provider: Provider = Provider()) {
        self.collector = collector
        self.provider = provider
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
