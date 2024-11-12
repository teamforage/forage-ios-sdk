//
//  Collector.swift
//
//
//  Created by Danny Leiser on 3/8/23.
//  Copyright © 2023-Present Forage Technology Corporation. All rights reserved.
//

import Foundation
import UIKit

let tokenDelimiter = ","
let tokenKey = "card_number_token"

/// Defines actions performed against the Vault Proxy.
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
    func setCustomHeaders(headers: [String: String])
    func sendData<T: Decodable>(
        path: String,
        vaultAction: VaultAction,
        extraData: [String: Any],
        completion: @escaping (T?, ForageError?) -> Void
    )
    func getPaymentMethodToken(paymentMethodToken: String) throws -> String
}

// MARK: Vault Config

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

// MARK: Rosetta

// Wrapper class for Forage internal vault
class RosettaPINSubmitter: VaultCollector {
    var customHeaders: [String: String] = [:]
    let textElement: UITextField

    private let forageVaultConfig: ForageVaultConfig
    private let logger: ForageLogger?
    private let session: URLSessionProtocol

    init(
        textElement: UITextField,
        forageVaultConfig: ForageVaultConfig,
        logger: ForageLogger? = DatadogLogger(ForageLoggerConfig(prefix: "Rosetta")),
        // Taking session as an injected dependency to make this easier to test
        session: URLSessionProtocol = URLSession.shared
    ) {
        self.textElement = textElement
        customHeaders = [:]
        self.forageVaultConfig = forageVaultConfig
        self.logger = logger
        self.session = session
    }

    func setCustomHeaders(headers: [String: String]) {
        customHeaders = headers
    }

    func sendData<T: Decodable>(path: String, vaultAction: VaultAction, extraData: [String: Any], completion: @escaping (T?, ForageError?) -> Void) {
        guard var requestBody = try? buildRequestBody(with: extraData) else {
            return completion(nil, CommonErrors.UNKNOWN_SERVER_ERROR)
        }

        var request = buildRequest(for: path)

        // measure the response time
        let measurement = VaultProxyResponseMonitor.newMeasurement(action: vaultAction)
            .setPath(path)
            .setMethod(.post)

        measurement.start()

        // making sure this runs on the main queue since we're reading from a UI element
        DispatchQueue.main.async {
            guard let validatedPIN = self.getValidatedPIN() else {
                return completion(nil, CommonErrors.INCOMPLETE_PIN_ERROR)
            }

            requestBody["pin"] = validatedPIN
            request.httpBody = try! JSONSerialization.data(withJSONObject: requestBody)

            // make the request to the vault proxy
            self.session.dataTask(with: request) { data, response, error in
                self.handleResponse(response: response, data: data, error: error, measurement: measurement, completion: completion)
            }.resume()
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
            let tokens = paymentMethodToken.components(separatedBy: tokenDelimiter)
            if tokens.count > 2 {
                let rosettaToken = tokens[2]
                if rosettaToken.isEmpty {
                    throw ServiceError.parseError
                } else {
                    return rosettaToken
                }
            } else {
                throw ServiceError.parseError
            }
        }
        throw ServiceError.parseError
    }

    func getValidatedPIN() -> String? {
        guard let pin = textElement.text else {
            return nil
        }

        let isFourCharacters = pin.count == 4
        let isOnlyNumeric = pin.allSatisfy(\.isNumber)
        let isValidPIN = isFourCharacters && isOnlyNumeric

        if isValidPIN {
            return pin
        } else {
            return nil
        }
    }

    func buildRequestBody(with extraData: [String: Any]) throws -> [String: String] {
        var body = [String: String]()

        // grab the payment method token and add it to the request body, throw if there isn't a rosetta token
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
                    throw CommonErrors.UNKNOWN_SERVER_ERROR
                }
            }
        }

        return body
    }

    func buildRequest(for path: String) -> URLRequest {
        let url = URL(string: "https://\(forageVaultConfig.vaultBaseURL)/proxy\(path)")!
        var request = URLRequest(url: url)

        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        for header in customHeaders {
            if header.key == "Session-Token" {
                // intentionally omitting `Session-Token` header since we only need `Authorization` for Rosetta
                request.setValue(header.value, forHTTPHeaderField: "Authorization")
            } else {
                request.setValue(header.value, forHTTPHeaderField: header.key)
            }
        }

        return request
    }
}

// MARK: CollectorFactory

enum CollectorFactory {
    static func createRosettaPINSubmitter(environment: Environment, textElement: UITextField) -> RosettaPINSubmitter {
        RosettaPINSubmitter(
            textElement: textElement,
            forageVaultConfig: ForageVaultConfig(environment: environment)
        )
    }
}
