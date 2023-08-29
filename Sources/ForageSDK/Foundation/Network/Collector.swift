//
//  File.swift
//  
//
//  Created by Danny Leiser on 3/8/23.
//

import Foundation
import VGSCollectSDK
import BasisTheoryElements

let tokenDelimiter = ","
let tokenKey = "card_number_token"

internal protocol VaultCollector {
    func setCustomHeaders(headers: [String: String], xKey: [String:String])
    func sendData(
        path: String,
        vaultAction: VaultAction,
        extraData: [String: Any],
        completion: @escaping (VaultResponse) -> Void)
    func getPaymentMethodToken(paymentMethodToken: String) throws -> String
    
}

struct VGSCollectConfig {
    let id: String
    let environment: VGSCollectSDK.Environment
}

struct BasisTheoryConfig {
    let publicKey: String
    let proxyKey: String
}

internal enum VaultAction: String {
    case balanceCheck = "balance"
    case capture
}

// Wrapper class for VGSCollect
class VGSCollectWrapper: VaultCollector {
    
    public let vgsCollect: VGSCollect
    private let logger: ForageLogger?
    
    init(config: VGSCollectConfig, logger: ForageLogger? = DatadogLogger(ForageLoggerConfig(prefix: "VGS"))) {
        self.vgsCollect = VGSCollect(id: config.id, environment: config.environment)
        self.logger = logger
    }
    
    func setCustomHeaders(headers: [String: String], xKey: [String: String]) {
        var mutableHeaders = headers
        mutableHeaders["X-KEY"] = xKey["vgsXKey"]
        vgsCollect.customHeaders = mutableHeaders
    }
    
    func sendData(path: String, vaultAction: VaultAction, extraData: [String: Any], completion: @escaping (VaultResponse) -> Void) {
        var mutableExtraData = extraData
        if let paymentMethodToken = extraData[tokenKey] as? String {
            let token = getPaymentMethodToken(paymentMethodToken: paymentMethodToken)
            if token.isEmpty {
                self.logger?.error(
                    "Failed to send data. VGS token not found on card",
                    error: nil,
                    attributes: nil
                )
            }
            mutableExtraData[tokenKey] = token
        }
        
        let measurement = VaultProxyResponseMonitor.newMeasurement(vault: VaultType.vgsVaultType, action: vaultAction)
            .setPath(path)
            .setMethod(.post)

        measurement.start()
        vgsCollect.sendData(path: path, extraData: mutableExtraData) { (response) in
            switch response {
            case .success(let code, let data, let urlResponse):
                measurement.end()
                measurement.setHttpStatusCode(code).logResult()
                completion(VaultResponse(statusCode: code, urlResponse: urlResponse, data: data, error: nil))
            case .failure(let code, let data, let urlResponse, let error):
                measurement.end()
                self.logger?.error("Failed to send data to VGS proxy", error: error, attributes: [
                    "http_status": code
                ])
                measurement.setHttpStatusCode(code).logResult()
                completion(VaultResponse(statusCode: code, urlResponse: urlResponse, data: data, error: error))
            }
        }
    }
    
    func getPaymentMethodToken(paymentMethodToken: String) -> String {
        if paymentMethodToken.contains(tokenDelimiter) {
            return paymentMethodToken.components(separatedBy: tokenDelimiter)[0]
        }
        return paymentMethodToken
    }
}

func convertJsonToDictionary(_ json: JSON) -> [String: Any] {
    var result: [String: Any] = [:]
    
    if case .dictionaryValue(let dictionary) = json {
        for (key, value) in dictionary {
            if case .rawValue(let rawValue) = value {
                result[key] = rawValue
            } else {
                result[key] = convertJsonToDictionary(value)
            }
        }
    }
    return result
}

// Wrapper class for BasisTheory
class BasisTheoryWrapper: VaultCollector {
    func getPaymentMethodToken(paymentMethodToken: String) throws -> String {
        if paymentMethodToken.contains(tokenDelimiter) {
            return paymentMethodToken.components(separatedBy: tokenDelimiter)[1]
        }
        throw ServiceError.parseError
    }
    
    var customHeaders: [String: String] = [:]
    let textElement: TextElementUITextField
    
    private let basisTheoryConfig: BasisTheoryConfig
    private let logger: ForageLogger?
    
    func setCustomHeaders(headers: [String: String], xKey: [String: String]) {
        self.customHeaders = headers
        self.customHeaders["X-KEY"] = xKey["btXKey"]
    }
    
    init(textElement: TextElementUITextField, basisTheoryconfig: BasisTheoryConfig, logger: ForageLogger? = DatadogLogger(ForageLoggerConfig(prefix: "BasisTheory"))) {
        self.textElement = textElement
        self.customHeaders = [:]
        self.basisTheoryConfig = basisTheoryconfig
        self.logger = logger
    }
    
    func sendData(path: String, vaultAction: VaultAction, extraData: [String : Any], completion: @escaping (VaultResponse) -> Void) {
        var body: [String: Any] = ["pin": textElement]
        for (key, value) in extraData {
            if key == tokenKey, let paymentMethodToken = value as? String {
                do {
                    let token = try getPaymentMethodToken(paymentMethodToken: paymentMethodToken)
                    body[key] = token
                } catch {
                    self.logger?.error(
                        "Failed to send data to Basis Theory proxy. BT token not found on card",
                        error: error,
                        attributes: nil
                    )
                    completion(VaultResponse(
                        statusCode: nil,
                        urlResponse: nil,
                        data: nil,
                        error: error
                    ))
                    return
                }
            } else {
                body[key] = value
            }
        }
        
        let measurement = VaultProxyResponseMonitor.newMeasurement(vault: VaultType.btVaultType, action: vaultAction)
            .setPath(path)
            .setMethod(.post)
        
        let proxyHttpRequest = ProxyHttpRequest(method: .post, path: path, body: body, headers: self.customHeaders)
        
        measurement.start()
        BasisTheoryElements.proxy(
            apiKey: basisTheoryConfig.publicKey, proxyKey: basisTheoryConfig.proxyKey,
            proxyHttpRequest: proxyHttpRequest
        ) { response, data, error in
            measurement.end()
            
            let httpStatusCode = (response as? HTTPURLResponse)?.statusCode
            measurement.setHttpStatusCode(httpStatusCode).logResult()

            if error != nil {
                self.logger?.error("Failed to send data to Basis Theory proxy", error: error, attributes: [
                    "http_status": httpStatusCode
                ])
            }
            
            var rawData: Data? = nil
            if let data = data {
                let dataDictionary = convertJsonToDictionary(data)
                rawData = try? JSONSerialization.data(withJSONObject: dataDictionary, options: [])
            }
            let vaultResponse = VaultResponse(
                statusCode: httpStatusCode,
                urlResponse: response,
                data: rawData,
                error: error
            )
            completion(vaultResponse)
        }
    }
}

class CollectorFactory {
    /**
     VGS VaultId
     */
    private enum VaultId: String {
        case sandbox = "tntagcot4b1"
        case cert = "tntpnht7psv"
        case prod = "tntbcrncmgi"
        case staging = "tnteykuh975"
        case dev = "tntlqkidhc6"
    }
    
    public static func CreateVGS() -> VGSCollect {
        return VGSCollect(id: vaultID(ForageSDK.shared.environment).rawValue, environment: environmentVGS(ForageSDK.shared.environment))
    }
    
    private static func vaultID(_ environment: EnvironmentTarget) -> VaultId {
        switch environment {
        case .sandbox: return .sandbox
        case .cert: return .cert
        case .prod: return .prod
        case .staging: return .staging
        case .dev: return .dev
        }
    }
    
    private static func environmentVGS(_ environment: EnvironmentTarget) -> VGSCollectSDK.Environment {
        switch environment {
        case .cert, .sandbox, .staging, .dev: return .sandbox
        case .prod: return .live
        }
    }
    
    /**
     BT public Keys
     */
    private enum PublicKey: String {
        case sandbox = "key_DQ5NfUAgiqzwX1pxqcrSzK"
        case cert = "key_NdWtkKrZqztEfJRkZA8dmw"
        case prod = "key_BypNREttGMPbZ1muARDUf4"
        case staging = "key_6B4cvpcDCEeNDYNow9zH7c"
        case dev = "key_AZfcBuKUsV38PEeYu6ZV8x"
    }
    
    private static func publicKey(_ environment: EnvironmentTarget) -> PublicKey {
        switch environment {
        case .sandbox: return .sandbox
        case .cert: return .cert
        case .prod: return .prod
        case .staging: return .staging
        case .dev: return .dev
        }
    }
    
    private static func proxyKey(_ environment: EnvironmentTarget) -> ProxyKey {
        switch environment {
        case .sandbox: return .sandbox
        case .cert: return .cert
        case .prod: return .prod
        case .staging: return .staging
        case .dev: return .dev
        }
    }
    
    /**
     BT proxy Keys
     */
    private enum ProxyKey: String {
        case sandbox = "R1CNiogSdhnHeNq6ZFWrG1"
        case cert = "AFSMtyyTGLKgmdWwrLCENX"
        case prod = "UxbU4Jn2RmvCovABjwCwsa"
        case staging = "ScWvAUkp53xz7muae7fW5p"
        case dev = "N31FZgKpYZpo3oQ6XiM6M6"
    }
    
    static func createVGS(environment: EnvironmentTarget) -> VGSCollectWrapper {
        let id = vaultID(environment).rawValue
        let environmentVGS = environmentVGS(environment)
        let config = VGSCollectConfig(id: id, environment: environmentVGS)
        return VGSCollectWrapper(config: config)
    }
    
    static func createBasisTheory(environment: EnvironmentTarget, textElement: TextElementUITextField) -> BasisTheoryWrapper {
        let publicKey = publicKey(environment).rawValue
        let proxyKey = proxyKey(environment).rawValue
        let config = BasisTheoryConfig(publicKey: publicKey, proxyKey: proxyKey)
        return BasisTheoryWrapper(textElement: textElement, basisTheoryconfig: config)
    }
    
}
