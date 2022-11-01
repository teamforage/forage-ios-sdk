//
//  ForageSDK.swift
//  ForageSDK
//
//  Created by Symphony on 18/10/22.
//

import VGSCollectSDK
import Foundation

private enum CardType: String {
    case ebt = "ebt"
}

protocol ForageSDKService: AnyObject {
    var collector: VGSCollect? { get }
    var service: ForageService? { get }
    
    func tokenizeEBTCard(
        merchantAccount: String,
        bearerToken: String,
        completion: @escaping (Result<Data?, Error>) -> Void)
        
    func checkBalance(
        bearerToken: String,
        merchantAccount: String,
        paymentMethodReference: String,
        cardNumberToken: String,
        completion: @escaping (Result<Data?, Error>) -> Void)
    
    func capturePayment(
        bearerToken: String,
        merchantAccount: String,
        paymentReference: String,
        cardNumberToken: String,
        completion: @escaping (Result<Data?, Error>) -> Void)
    
    func cancelRequest()
}

public class ForageSDK: ForageSDKService {
    
    // MARK: Properties
    
    internal var collector: VGSCollect?
    internal var service: ForageService?
    internal var panNumber: String = ""
    
    public static let shared: ForageSDK = {
        let instance = ForageSDK()
        return instance
    }()
    
    // MARK: Init
    
    private init() {
        self.collector = VGSCollect(id: "tntagcot4b1", environment: .sandbox)
        self.service = LiveForageService(collector)
    }
    
    // MARK: ForageSDKService Methods
    
    public func tokenizeEBTCard(
        merchantAccount: String,
        bearerToken: String,
        completion: @escaping (Result<Data?, Error>) -> Void) {
        let request = ForagePANRequest(
            authorization: bearerToken,
            merchantAccount: merchantAccount,
            panNumber: panNumber,
            type: CardType.ebt.rawValue,
            reusable: true
        )
        service?.tokenizeEBTCard(request: request, completion: completion)
    }
    
    public func checkBalance(
        bearerToken: String,
        merchantAccount: String,
        paymentMethodReference: String,
        cardNumberToken: String,
        completion: @escaping (Result<Data?, Error>) -> Void) {
        service?.getXKey(bearerToken: bearerToken) { result in
            switch result {
            case .success(let model):
                let request = ForageBalanceRequest(
                    authorization: bearerToken,
                    paymentMethodReference: paymentMethodReference,
                    cardNumberToken: cardNumberToken,
                    merchantID: merchantAccount,
                    xKey: model.alias
                )
                self.service?.getBalance(request: request, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func capturePayment(
        bearerToken: String,
        merchantAccount: String,
        paymentReference: String,
        cardNumberToken: String,
        completion: @escaping (Result<Data?, Error>) -> Void) {
        service?.getXKey(bearerToken: bearerToken) { result in
            switch result {
            case .success(let model):
                let request = ForageCaptureRequest(
                    authorization: bearerToken,
                    paymentReference: paymentReference,
                    cardNumberToken: cardNumberToken,
                    merchantID: merchantAccount,
                    xKey: model.alias
                )
                
                self.service?.requestCapturePayment(request: request, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func cancelRequest() {
        service?.provider.stopRequestOnGoing()
    }
    
    private func getXKey(
        _ bearerToken: String,
        completion: @escaping (Result<ForageXKeyModel, Error>) -> Void)
    -> Void {
        service?.getXKey(bearerToken: bearerToken) { result in
            completion(result)
        }
    }
}
