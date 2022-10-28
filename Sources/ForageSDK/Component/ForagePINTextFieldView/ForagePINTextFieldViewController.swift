//
//  ForagePINTextFieldViewController.swift
//  ForageSDK
//
//  Created by Symphony on 21/10/22.
//

import Foundation
import VGSCollectSDK

protocol ForagePINTextFieldViewController: AnyObject {
    func requestBalance(
        paymentMethodReference: String,
        cardNumberToken: String,
        completion: @escaping (Result<ForageBalanceModel, Error>) -> Void) -> Void
    
    func capturePayment(
        paymentReference: String,
        cardNumberToken: String,
        merchantID: String,
        completion: @escaping (Result<ForageCaptureModel, Error>) -> Void) -> Void
    
    var collector: VGSCollect { get }
}

internal class LiveForagePINTextFieldViewController: ForagePINTextFieldViewController {
    
    /// Init VGS Collector
    ///
    /// - Parameters:
    ///
    ///  - id: client vaultid
    ///  - environment: client environment
    ///
    var collector = VGSCollect(id: "tntagcot4b1", environment: .sandbox)
    
    // MARK: Methods
    
    internal func requestBalance(
        paymentMethodReference: String,
        cardNumberToken: String,
        completion: @escaping (Result<ForageBalanceModel, Error>) -> Void)
    -> Void {
        getXKey { result in
            switch result {
            case .success(let model):
                debugPrint(model)
                let request = ForageBalanceRequest(
                    authorization: ForageSDK.shared.bearerToken,
                    paymentMethodReference: paymentMethodReference,
                    cardNumberToken: cardNumberToken,
                    merchantID: ForageSDK.shared.merchantID,
                    xKey: model.alias
                )
                
                self.getBalance(request: request) { result in
                    switch result {
                    case .success(let model):
                        debugPrint(model)
                        completion(.success(model))
                    case .failure(let error):
                        debugPrint(error)
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                debugPrint(error)
            }
        }
    }
    
    internal func capturePayment(
        paymentReference: String,
        cardNumberToken: String,
        merchantID: String,
        completion: @escaping (Result<ForageCaptureModel, Error>) -> Void)
    -> Void {
        getXKey { result in
            switch result {
            case .success(let model):
                self.requestCapturePayment(
                    paymentReference: paymentReference,
                    cardNumberToken: cardNumberToken,
                    merchantID: merchantID,
                    xKey: model.alias) { result in
                    switch result {
                    case .success(let model):
                        completion(.success(model))
                   case .failure(let error):
                        completion(.failure(error))
                    }
                }
                                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func getXKey(
        completion: @escaping (Result<ForageXKeyModel, Error>) -> Void)
    -> Void {
        let service = ForagePINTextFieldViewService()
        service.getXKey(bearerToken: ForageSDK.shared.bearerToken) { result in
            completion(result)
        }
    }
    
    private func requestCapturePayment(
        paymentReference: String,
        cardNumberToken: String,
        merchantID: String,
        xKey: String,
        completion: @escaping (Result<ForageCaptureModel, Error>) -> Void)
    {
        collector.customHeaders = [
            "X-KEY": xKey,
            "IDEMPOTENCY-KEY": paymentReference,
            "Merchant-Account": merchantID
        ]

        let extraData = [
            "card_number_token": cardNumberToken
        ]

        collector.sendData(
            path: "/api/payments/\(paymentReference)/capture/",
            extraData: extraData) { result in
                switch result {
                case .success(let code, let data, let response):
                    let provider = Provider()
                    provider.processVGSData(
                        model: ForageCaptureModel.self,
                        code: code,
                        data: data,
                        response: response
                    ) { end in
                        switch end {
                        case .success(let model):
                            debugPrint(model)
                            completion(.success(model))
                        case .failure(let error):
                            debugPrint(error)
                            completion(.failure(error))
                        }
                    }
                case .failure(let code, _, _, _):
                    debugPrint("""
                    code: \(code)\n
                    """)
                }
            }
    }

    private func getBalance(
        request: ForageBalanceRequest,
        completion: @escaping (Result<ForageBalanceModel, Error>) -> Void) -> Void {
            collector.customHeaders = [
                "X-KEY": request.xKey,
                "IDEMPOTENCY-KEY": request.paymentMethodReference,
                "Merchant-Account": request.merchantID
            ]

            let extraData = [
                "card_number_token": request.cardNumberToken
            ]

            collector.sendData(
                path: "/api/payment_methods/\(request.paymentMethodReference)/balance/",
                extraData: extraData) { result in
                    switch result {
                    case .success(let code, let data, let response):
                        let provider = Provider()
                        provider.processVGSData(
                            model: ForageBalanceModel.self,
                            code: code,
                            data: data,
                            response: response
                        ) { end in
                            switch end {
                            case .success(let model):
                                debugPrint(model)
                                completion(.success(model))
                            case .failure(let error):
                                debugPrint(error)
                                completion(.failure(error))
                            }
                        }
                    case .failure:
                        debugPrint("Error")
                    }
                }
        }
}
