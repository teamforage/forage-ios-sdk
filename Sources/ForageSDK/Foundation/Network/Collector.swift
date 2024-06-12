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
import UIKit

let tokenDelimiter = ","
let tokenKey = "card_number_token"

/// Defines actions performed against the Vault (VGS or Basis Theory) Proxy.
enum VaultAction: String {
    case balanceCheck = "balance"
    case capturePayment = "capture"
    case deferCapture = "defer_capture"

    var endpointSuffix: String {
        switch self {
        case .balanceCheck:
            return "/balance/"
        case .capturePayment:
            return "/capture/"
        case .deferCapture:
            return "/collect_pin/"
        }
    }
}

protocol VaultCollector {
    func setCustomHeaders(headers: [String: String], xKey: [String: String])
    func sendData<T: Decodable>(
        path: String,
        vaultAction: VaultAction,
        extraData: [String: Any],
        completion: @escaping (T?, ForageError?) -> Void
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

struct ForageVaultConfig {
    let environment: Environment
    var vaultBaseURL: String {
        switch environment {
        case .dev: return "vault.dev.joinforage.app"
        case .staging: return "vault.staging.joinforage.app"
        case .sandbox: return "vault.sandbox.joinforage.app"
        case .cert: return "vault.cert.joinforage.app"
        case .prod: return "vault.joinforage.app"
        }
    }
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

    func handleResponse<T: Decodable>(code: Int, data: Data?, error: Error?, measurement: NetworkMonitor, completion: (T?, ForageError?) -> Void) {
        measurement.end()
        measurement.setHttpStatusCode(code).logResult()

        // If an error is explicitly returned from VGS, log the error and return
        if let error = error {
            logger?.critical(
                "VGS proxy failed with an error",
                error: error,
                attributes: nil
            )
            return completion(nil, CommonErrors.UNKNOWN_SERVER_ERROR)
        }

        // If there was no error AND no data was returned, something went wrong and we should log and return
        guard let data = data else {
            logger?.critical(
                "VGS failed to respond with a data object",
                error: nil,
                attributes: nil
            )
            return completion(nil, CommonErrors.UNKNOWN_SERVER_ERROR)
        }

        // If the response was a Forage error (ex. 429 throttled), catch it here and return
        if let forageServiceError = try? JSONDecoder().decode(ForageServiceError.self, from: data) {
            let forageCode = forageServiceError.errors[0].code
            let message = forageServiceError.errors[0].message
            return completion(nil, ForageError.create(
                code: forageCode,
                httpStatusCode: code,
                message: message
            ))
        }

        // If the code is a 204, we got a successful response from the deferred capture flow.
        // In this scenario, we should just return
        if code == 204 {
            return completion(nil, nil)
        }

        // Try to decode the response and return the expected object
        do {
            let decoder = JSONDecoder()
            let decodedResponse = try decoder.decode(T.self, from: data)
            completion(decodedResponse, nil)
        } catch {
            // If we are unable to decode whatever was returned, log and return
            logger?.critical(
                "Failed to decode VGS response data.",
                error: CommonErrors.UNKNOWN_SERVER_ERROR,
                attributes: nil
            )
            return completion(nil, CommonErrors.UNKNOWN_SERVER_ERROR)
        }
    }

    func sendData<T: Decodable>(path: String, vaultAction: VaultAction, extraData: [String: Any], completion: @escaping (T?, ForageError?) -> Void) {
        var mutableExtraData = extraData
        if let paymentMethodToken = extraData[tokenKey] as? String {
            let token = getPaymentMethodToken(paymentMethodToken: paymentMethodToken)
            if token.isEmpty {
                logger?.critical(
                    "Failed to send data. VGS token not found on card",
                    error: nil,
                    attributes: nil
                )
                return completion(nil, CommonErrors.UNKNOWN_SERVER_ERROR)
            }
            mutableExtraData[tokenKey] = token
        }

        let measurement = VaultProxyResponseMonitor.newMeasurement(vault: VaultType.vgs, action: vaultAction)
            .setPath(path)
            .setMethod(.post)

        measurement.start()

        // VGS performs UI actions in this method, which should run on the main thread
        DispatchQueue.main.async { [self] in
            vgsCollect.sendData(path: path, extraData: mutableExtraData) { [self] response in
                switch response {
                case let .success(code, data, _):
                    handleResponse(code: code, data: data, error: nil, measurement: measurement, completion: completion)
                case let .failure(code, data, _, error):
                    handleResponse(code: code, data: data, error: error, measurement: measurement, completion: completion)
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

    func sendData<T: Decodable>(path: String, vaultAction: VaultAction, extraData: [String: Any], completion: @escaping (T?, ForageError?) -> Void) {
        var body: [String: Any] = ["pin": textElement]
        for (key, value) in extraData {
            if key == tokenKey, let paymentMethodToken = value as? String {
                do {
                    let token = try getPaymentMethodToken(paymentMethodToken: paymentMethodToken)
                    body[key] = token
                } catch {
                    logger?.critical(
                        "Failed to send data to Basis Theory proxy. BT token not found on card",
                        error: error,
                        attributes: nil
                    )
                    return completion(nil, CommonErrors.UNKNOWN_SERVER_ERROR)
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
            ) { [self] response, data, error in
                handleResponse(response: response, data: data, error: error, measurement: measurement, completion: completion)
            }
        }
    }

    func handleResponse<T: Decodable>(response: URLResponse?, data: JSON?, error: Error?, measurement: NetworkMonitor, completion: (T?, ForageError?) -> Void) {
        measurement.end()

        let httpStatusCode = (response as? HTTPURLResponse)?.statusCode
        measurement.setHttpStatusCode(httpStatusCode).logResult()

        // If the BT proxy responded with an error, log and return.
        // Danny (5/7/2024): I've never been able to trigger this
        if let btError = error {
            logger?.critical("Basis Theory proxy failed with an error", error: btError, attributes: [
                "http_status": httpStatusCode
            ])
            return completion(nil, CommonErrors.UNKNOWN_SERVER_ERROR)
        }

        guard let data = data else {
            logger?.critical("Basis Theory failed to respond with a data object", error: nil, attributes: [
                "http_status": httpStatusCode
            ])
            return completion(nil, CommonErrors.UNKNOWN_SERVER_ERROR)
        }

        // If the code is a 204, we got a successful response from the deferred capture flow.
        // In this scenario, we should just return
        if httpStatusCode == 204 {
            return completion(nil, nil)
        }

        // If we found `proxy_error` in the response, we know there was an issue with the BT proxy.
        // We can't currently access any of the information returned from BT in this state.
        if data["proxy_error"] != nil {
            logger?.critical("Basis Theory proxy script failed", error: nil, attributes: [
                "http_status": httpStatusCode
            ])
            return completion(nil, CommonErrors.UNKNOWN_SERVER_ERROR)
        }

        let dataObject: Data
        // Try to decode the response and return the expected object
        do {
            let dataDictionary = JSON.convertJsonToDictionary(data)
            dataObject = try JSONSerialization.data(withJSONObject: dataDictionary, options: [])
        } catch {
            // If we are unable to decode whatever was returned, log and return
            logger?.critical(
                "Basis Theory response data couldn't be decoded.",
                error: nil,
                attributes: nil
            )
            return completion(nil, CommonErrors.UNKNOWN_SERVER_ERROR)
        }

        // If the response was a Forage error (ex. 429 throttled), catch it here and return
        if let forageServiceError = try? JSONDecoder().decode(ForageServiceError.self, from: dataObject) {
            let forageCode = forageServiceError.errors[0].code
            let message = forageServiceError.errors[0].message
            return completion(nil, ForageError.create(
                code: forageCode,
                httpStatusCode: httpStatusCode ?? 500,
                message: message
            ))
        }

        // Try to decode the response and return the expected object
        do {
            let decoder = JSONDecoder()
            let decodedResponse = try decoder.decode(T.self, from: dataObject)
            completion(decodedResponse, nil)
        } catch {
            // If we are unable to decode whatever was returned, log and return
            logger?.critical(
                "Received an unknown response structure from Basis Theory",
                error: nil,
                attributes: nil
            )
            completion(nil, CommonErrors.UNKNOWN_SERVER_ERROR)
        }
    }

    func getVaultType() -> VaultType {
        VaultType.basisTheory
    }
}

// Wrapper class for Forage internal vault
class ForageVaultWrapper: VaultCollector {
    var customHeaders: [String: String] = [:]
    let textElement: UITextField
    
    private let forageVaultConfig: ForageVaultConfig
    private let logger: ForageLogger?
    
    init(textElement: UITextField, forageVaultConfig: ForageVaultConfig, logger: ForageLogger? = DatadogLogger(ForageLoggerConfig(prefix: "Rosetta"))) {
        self.textElement = textElement
        self.customHeaders = [:]
        self.forageVaultConfig = forageVaultConfig
        self.logger = logger
    }
    
    func setCustomHeaders(headers: [String : String], xKey: [String : String]) {
        customHeaders = headers
    }
    
    func sendData<T: Decodable>(path: String, vaultAction: VaultAction, extraData: [String : Any], completion: @escaping (T?, ForageError?) -> Void) {
        var body = [String: String]()

        // grab the payment method token and add it to the request body
        for (key, value) in extraData {
            if key == tokenKey, let paymentMethodToken = value as? String {
                do {
                    let token = try getPaymentMethodToken(paymentMethodToken: paymentMethodToken)
                    body[key] = token
                } catch {
                    logger?.critical(
                        "Failed to send data to Rosetta proxy. Rosetta token not found on card",
                        error: error,
                        attributes: nil
                    )
                    return completion(nil, CommonErrors.UNKNOWN_SERVER_ERROR)
                }
            }
        }
        
        // build the request to the vault proxy
        let url = URL(string: "https://\(forageVaultConfig.vaultBaseURL)/proxy\(path)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        for header in customHeaders {
            if header.key == "Session-Token" {
                request.setValue(header.value, forHTTPHeaderField: "Authorization")
            } else {
                request.setValue(header.value, forHTTPHeaderField: header.key)
            }
        }
        
        // measure the response time
        let measurement = VaultProxyResponseMonitor.newMeasurement(vault: VaultType.forage, action: vaultAction)
            .setPath(path)
            .setMethod(.post)
        
        measurement.start()
        
        // making sure this runs on the main queue since we're reading from a UI element
        DispatchQueue.main.async {
            
            // grab the pin value entered and add it to the request body
            guard let textElementValue = self.textElement.text else {
                return completion(nil, CommonErrors.INCOMPLETE_PIN_ERROR)
            }
            body["pin"] = textElementValue
            request.httpBody = try! JSONSerialization.data(withJSONObject: body)
            
            // make the request to the vault proxy
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                self.handleResponse(response: response, data: data, error: error, measurement: measurement, completion: completion)
            }
            task.resume()
            
        }
    }
    
    func handleResponse<T: Decodable>(response: URLResponse?, data: Data?, error: Error?, measurement: NetworkMonitor, completion: (T?, ForageError?) -> Void) {
        measurement.end()
        
        let code = (response as? HTTPURLResponse)?.statusCode ?? 500
        
        measurement.setHttpStatusCode(code).logResult()

        // If an error is explicitly returned from Rosetta, log the error and return
        if let error = error {
            logger?.error(
                "Rosetta proxy failed with an error",
                error: error,
                attributes: nil
            )
            return completion(nil, CommonErrors.UNKNOWN_SERVER_ERROR)
        }

        // If there was no error AND no data was returned, something went wrong and we should log and return
        guard let data = data else {
            logger?.critical(
                "Rosetta failed to respond with a data object",
                error: nil,
                attributes: nil
            )
            return completion(nil, CommonErrors.UNKNOWN_SERVER_ERROR)
        }

        // If the response was a Forage error (ex. 429 throttled), catch it here and return
        if let forageServiceError = try? JSONDecoder().decode(ForageServiceError.self, from: data) {
            let forageCode = forageServiceError.errors[0].code
            let message = forageServiceError.errors[0].message
            return completion(nil, ForageError.create(
                code: forageCode,
                httpStatusCode: code,
                message: message
            ))
        }

        // If the code is a 204, we got a successful response from the deferred capture flow.
        // In this scenario, we should just return
        if code == 204 {
            return completion(nil, nil)
        }

        // Try to decode the response and return the expected object
        do {
            let decoder = JSONDecoder()
            let decodedResponse = try decoder.decode(T.self, from: data)
            completion(decodedResponse, nil)
        } catch {
            // If we are unable to decode whatever was returned, log and return
            logger?.critical(
                "Failed to decode Rosetta response data.",
                error: CommonErrors.UNKNOWN_SERVER_ERROR,
                attributes: nil
            )
            return completion(nil, CommonErrors.UNKNOWN_SERVER_ERROR)
        }
    }
    
    func getPaymentMethodToken(paymentMethodToken: String) throws -> String {
        if paymentMethodToken.contains(tokenDelimiter) {
            return paymentMethodToken.components(separatedBy: tokenDelimiter)[2]
        }
        throw ServiceError.parseError
    }
    
    func getVaultType() -> VaultType {
        VaultType.forage
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
    
    static func createForage(environment: Environment, textElement: UITextField) -> ForageVaultWrapper {
        return ForageVaultWrapper(textElement: textElement, forageVaultConfig: ForageVaultConfig(environment: environment))
    }
}
