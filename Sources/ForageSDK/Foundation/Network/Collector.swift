//
//  Collector.swift
//
//
//  Created by Danny Leiser on 3/8/23.
//  Copyright © 2023-Present Forage Technology Corporation. All rights reserved.
//

import BasisTheoryElements
import Foundation
import VGSCollectSDK

let tokenDelimiter = ","
let tokenKey = "card_number_token"

/// Defines actions performed against the Vault (VGS or Basis Theory) Proxy.
enum VaultAction: String {
    case balanceCheck = "balance"
    case capturePayment = "capture"
    case collectPin = "collect_pin"

    var endpointSuffix: String {
        switch self {
        case .balanceCheck:
            return "/balance/"
        case .capturePayment:
            return "/capture/"
        case .collectPin:
            return "/collect_pin/"
        }
    }
}

protocol VaultCollector {
    func setCustomHeaders(headers: [String: String], xKey: [String: String])
    func sendData(
        path: String,
        vaultAction: VaultAction,
        extraData: [String: Any],
        completion: @escaping (VaultResponse) -> Void
    )
    func getPaymentMethodToken(paymentMethodToken: String) throws -> String
    func getVaultType() -> VaultType
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
    private let logger: ForageLogger?

    init(config: VGSCollectConfig, logger: ForageLogger? = DatadogLogger(ForageLoggerConfig(prefix: "VGS"))) {
        vgsCollect = VGSCollect(id: config.id, environment: config.environment)
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
                logger?.error(
                    "Failed to send data. VGS token not found on card",
                    error: nil,
                    attributes: nil
                )
            }
            mutableExtraData[tokenKey] = token
        }

        let measurement = VaultProxyResponseMonitor.newMeasurement(vault: VaultType.vgs, action: vaultAction)
            .setPath(path)
            .setMethod(.post)

        measurement.start()

        // VGS performs UI actions in this method, which should run on the main thread
        DispatchQueue.main.async { [self] in
            vgsCollect.sendData(path: path, extraData: mutableExtraData) { response in
                switch response {
                case let .success(code, data, urlResponse):
                    measurement.end()
                    measurement.setHttpStatusCode(code).logResult()
                    completion(VaultResponse(statusCode: code, urlResponse: urlResponse, data: data, error: nil))
                case let .failure(code, data, urlResponse, error):
                    measurement.end()
                    self.logger?.error("Failed to send data to VGS proxy", error: error, attributes: [
                        "http_status": code
                    ])
                    measurement.setHttpStatusCode(code).logResult()
                    completion(VaultResponse(statusCode: code, urlResponse: urlResponse, data: data, error: error ?? CommonErrors.UNKNOWN_SERVER_ERROR))
                }
            }
        }
    }

    func getPaymentMethodToken(paymentMethodToken: String) -> String {
        if paymentMethodToken.contains(tokenDelimiter) {
            return paymentMethodToken.components(separatedBy: tokenDelimiter)[0]
        }
        return paymentMethodToken
    }

    func getVaultType() -> VaultType {
        VaultType.vgs
    }
}

func convertJsonToDictionary(_ json: JSON) -> [String: Any] {
    var result: [String: Any] = [:]

    if case let .dictionaryValue(dictionary) = json {
        for (key, value) in dictionary {
            if case let .rawValue(rawValue) = value {
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
        customHeaders = headers
        customHeaders["X-KEY"] = xKey["btXKey"]
    }

    init(textElement: TextElementUITextField, basisTheoryconfig: BasisTheoryConfig, logger: ForageLogger? = DatadogLogger(ForageLoggerConfig(prefix: "BasisTheory"))) {
        self.textElement = textElement
        customHeaders = [:]
        basisTheoryConfig = basisTheoryconfig
        self.logger = logger
    }

    func sendData(path: String, vaultAction: VaultAction, extraData: [String: Any], completion: @escaping (VaultResponse) -> Void) {
        var body: [String: Any] = ["pin": textElement]
        for (key, value) in extraData {
            if key == tokenKey, let paymentMethodToken = value as? String {
                do {
                    let token = try getPaymentMethodToken(paymentMethodToken: paymentMethodToken)
                    body[key] = token
                } catch {
                    logger?.error(
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

        let measurement = VaultProxyResponseMonitor.newMeasurement(vault: VaultType.basisTheory, action: vaultAction)
            .setPath(path)
            .setMethod(.post)

        let proxyHttpRequest = ProxyHttpRequest(method: .post, path: path, body: body, headers: customHeaders)

        measurement.start()

        // Basis Theory performs UI actions in this method, which should run on the main thread
        DispatchQueue.main.async { [self] in
            BasisTheoryElements.proxy(
                apiKey: basisTheoryConfig.publicKey,
                proxyKey: basisTheoryConfig.proxyKey,
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

                var rawData: Data?
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

    func getVaultType() -> VaultType {
        VaultType.basisTheory
    }
}

enum CollectorFactory {
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
        VGSCollect(id: vaultID(ForageSDK.shared.environment).rawValue, environment: environmentVGS(ForageSDK.shared.environment))
    }

    private static func vaultID(_ environment: Environment) -> VaultId {
        switch environment {
        case .sandbox: return .sandbox
        case .cert: return .cert
        case .prod: return .prod
        case .staging: return .staging
        case .dev: return .dev
        }
    }

    private static func environmentVGS(_ environment: Environment) -> VGSCollectSDK.Environment {
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

    private static func publicKey(_ environment: Environment) -> PublicKey {
        switch environment {
        case .sandbox: return .sandbox
        case .cert: return .cert
        case .prod: return .prod
        case .staging: return .staging
        case .dev: return .dev
        }
    }

    private static func proxyKey(_ environment: Environment) -> ProxyKey {
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

    static func createVGS(environment: Environment) -> VGSCollectWrapper {
        let id = vaultID(environment).rawValue
        let environmentVGS = environmentVGS(environment)
        let config = VGSCollectConfig(id: id, environment: environmentVGS)
        return VGSCollectWrapper(config: config)
    }

    static func createBasisTheory(environment: Environment, textElement: TextElementUITextField) -> BasisTheoryWrapper {
        let publicKey = publicKey(environment).rawValue
        let proxyKey = proxyKey(environment).rawValue
        let config = BasisTheoryConfig(publicKey: publicKey, proxyKey: proxyKey)
        return BasisTheoryWrapper(textElement: textElement, basisTheoryconfig: config)
    }
}
