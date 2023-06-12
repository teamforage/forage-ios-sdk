//
//  File.swift
//  
//
//  Created by Danny Leiser on 3/8/23.
//

import Foundation
import VGSCollectSDK
import BasisTheoryElements

public protocol VaultCollector {
    func setCustomHeaders(headers: [String: String])
    func sendData(
        path: String,
        extraData: [String: Any],
        completion: @escaping (VaultResponse) -> Void)
    
}

struct VGSCollectConfig {
    let id: String
    let environment: VGSCollectSDK.Environment
}

struct BasisTheoryConfig {
    let publicKey: String
    let proxyKey: String
}

// Wrapper class for VGSCollect
class VGSCollectWrapper: VaultCollector {
    
    public let vgsCollect: VGSCollect
    
    init(config: VGSCollectConfig) {
        self.vgsCollect = VGSCollect(id: config.id, environment: config.environment)
    }
    
    func setCustomHeaders(headers: [String: String]) {
        vgsCollect.customHeaders = headers
    }
    
    func sendData(path: String, extraData: [String: Any], completion: @escaping (VaultResponse) -> Void) {
        vgsCollect.sendData(path: path, extraData: extraData) { (response) in
            switch response {
            case .success(let code, let data, let urlResponse):
                completion(VaultResponse(statusCode: code, urlResponse: urlResponse, data: data, error: nil))
            case .failure(let code, let data, let urlResponse, let error):
                completion(VaultResponse(statusCode: code, urlResponse: urlResponse, data: data, error: error))
            }
        }
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
    var customHeaders: [String: String] = [:]
    let textElement: TextElementUITextField
    
    private let basisTheoryConfig: BasisTheoryConfig
    
    
    func setCustomHeaders(headers: [String: String]) {
        self.customHeaders = headers
    }
    
    init(textElement: TextElementUITextField, basisTheoryconfig: BasisTheoryConfig) {
        self.textElement = textElement
        self.customHeaders = [:]
        self.basisTheoryConfig = basisTheoryconfig
    }
    
    func sendData(path: String, extraData: [String : Any], completion: @escaping (VaultResponse) -> Void) {
        var body: [String: Any] = ["pin": textElement]
        for (key, value) in extraData {
            body[key] = value
        }
        let proxyHttpRequest = ProxyHttpRequest(method: .post, path: path, body: body, headers: self.customHeaders)
        
        BasisTheoryElements.proxy(
            apiKey: basisTheoryConfig.publicKey, proxyKey: basisTheoryConfig.proxyKey,
            proxyHttpRequest: proxyHttpRequest
        ) { response, data, error in
            var rawData: Data? = nil
            if let data = data {
                let dataDictionary = convertJsonToDictionary(data)
                rawData = try? JSONSerialization.data(withJSONObject: dataDictionary, options: [])
            }
            let vaultResponse = VaultResponse(
                statusCode: (response as? HTTPURLResponse)?.statusCode,
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
