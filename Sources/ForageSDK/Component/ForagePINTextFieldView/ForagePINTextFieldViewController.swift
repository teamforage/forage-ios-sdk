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
        paymentReference: String,
        cardNumberToken: String,
        completion: @escaping (Result<ForageBalanceModel, Error>) -> Void) -> Void
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
        paymentReference: String,
        cardNumberToken: String,
        completion: @escaping (Result<ForageBalanceModel, Error>) -> Void) -> Void {
            requestXKey(
                paymentReference: paymentReference,
                cardNumberToken: cardNumberToken,
                completion: completion
            )
        }
    
    private func requestXKey(
        paymentReference: String,
        cardNumberToken: String,
        completion: @escaping (Result<ForageBalanceModel, Error>) -> Void) -> Void {
            let service = ForagePINTextFieldViewService()
            service.getXKey(bearerToken: ForageSDK.shared.bearerToken) { result in
                switch result {
                case .success(let model):
                    debugPrint(model)
                    let request = ForageBalanceRequest(
                        authorization: ForageSDK.shared.bearerToken,
                        paymentReference: paymentReference,
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
    
    private func getBalance(
        request: ForageBalanceRequest,
        completion: @escaping (Result<ForageBalanceModel, Error>) -> Void) -> Void {
            collector.customHeaders = [
                "X-KEY": request.cardNumberToken,
                "IDEMPOTENCY-KEY": request.paymentReference,
                "Merchant-Account": request.merchantID
            ]
            
            let extraData = [
                "card_number_token": request.cardNumberToken
            ]
            
            collector.sendData(
                path: "/api/payment_methods/\(request.paymentReference)/balance/",
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
