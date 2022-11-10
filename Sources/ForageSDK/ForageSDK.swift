//
//  ForageSDK.swift
//  ForageSDK
//
//  Created by Symphony on 18/10/22.
//

import VGSCollectSDK
import Foundation

public enum EnvironmentTarget: String {
    case sandbox = "api.sandbox.joinforage.app"
    case cert = "api.cert.joinforage.app"
    case prod = "api.joinforage.app"
}

private enum VaultId: String {
    case sandbox = "tntagcot4b1"
    case cert = "tntpnht7psv"
    case prod = "tntbcrncmgi"
}

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
    
    private static var config: Config?
    internal var collector: VGSCollect?
    internal var service: ForageService?
    internal var panNumber: String = ""
    internal var environment: EnvironmentTarget = .sandbox
    
    public static let shared = ForageSDK()
    
    // MARK: Init
    
    private init() {
        guard let config = ForageSDK.config else {
            assertionFailure("ForageSDK missing Config setup")
            return
        }
        
        VGSCollectLogger.shared.disableAllLoggers()
        self.environment = config.environment
        self.collector = VGSCollect(id: vaultID(config.environment).rawValue, environment: environmentVGS(config.environment))
        self.service = LiveForageService(collector)
    }
    
    public struct Config {
        let environment: EnvironmentTarget

        public init(environment: EnvironmentTarget = .sandbox) {
            self.environment = environment
        }
    }
    
    public class func setup(_ config: Config) {
        ForageSDK.config = config
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
    
    private func vaultID(_ environment: EnvironmentTarget) -> VaultId {
        switch environment {
        case .sandbox: return .sandbox
        case .cert: return .cert
        case .prod: return .prod
        }
    }
    
    private func environmentVGS(_ environment: EnvironmentTarget) -> VGSCollectSDK.Environment {
        switch environment {
        case .cert, .sandbox: return .sandbox
        case .prod: return .live
        }
    }
}
