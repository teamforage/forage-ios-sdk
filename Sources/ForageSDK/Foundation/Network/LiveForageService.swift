//
//  LiveForageService.swift
//  ForageSDK
//
//  Created by Tiago Oliveira on 30/10/22.
//  Copyright © 2022-Present Forage Technology Corporation. All rights reserved.
//

import Foundation

class LiveForageService: ForageService {
    // MARK: Properties

    var provider: Provider

    private var logger: ForageLogger?
    private var ldManager: LDManagerProtocol

    init(
        provider: Provider = Provider(),
        logger: ForageLogger? = nil,
        ldManager: LDManagerProtocol
    ) {
        self.provider = provider
        self.logger = logger?.setPrefix("")
        self.ldManager = ldManager
    }

    // MARK: Tokenize EBT card

    func tokenizeEBTCard(request: ForagePANRequestModel, completion: @escaping (Result<PaymentMethodModel, Error>) -> Void) {
        do {
            try provider.execute(model: PaymentMethodModel.self, endpoint: ForageAPI.tokenizeNumber(request: request), completion: completion)
        } catch { completion(.failure(error)) }
    }

    // MARK: X-key

    func getXKey(sessionToken: String, merchantID: String, completion: @escaping (Result<ForageXKeyModel, Error>) -> Void) {
        do { try provider.execute(model: ForageXKeyModel.self, endpoint: ForageAPI.xKey(sessionToken: sessionToken, merchantID: merchantID), completion: completion) } catch { completion(.failure(error)) }
    }

    // MARK: Check balance

    func checkBalance(
        pinCollector: VaultCollector,
        paymentMethodReference: String
    ) async throws -> BalanceModel {
        let vaultResponse: VaultResponse?
        do {
            let balanceRequest = try await requestPreamble(using: onlyGetPaymentMethod, tokenRef: paymentMethodReference)

            vaultResponse = try await submitPinToVault(
                pinCollector: pinCollector,
                vaultAction: .balanceCheck,
                idempotencyKey: UUID().uuidString,
                path: "/api/payment_methods/\(paymentMethodReference)/balance/",
                request: balanceRequest
            )
        } catch {
            throw error
        }
        
        guard let vaultData = vaultResponse?.data else {
            logger?.error(
                "\(pinCollector.getVaultType()) proxy error. Balance check failed for Payment Method \(paymentMethodReference). No data or error from vault.",
                error: CommonErrors.UNKNOWN_SERVER_ERROR,
                attributes: nil
            )
            throw CommonErrors.UNKNOWN_SERVER_ERROR
        }
        
        let rawBalanceModel: RawBalanceResponseModel?
        do {
            let decoder = JSONDecoder()
            rawBalanceModel = try decoder.decode(
                RawBalanceResponseModel.self,
                from: vaultData
            )
        } catch {
            logger?.critical(
                "Failed to decode API response. Balance check failed for Payment Method \(paymentMethodReference).",
                error: CommonErrors.UNKNOWN_SERVER_ERROR,
                attributes: nil
            )
            throw CommonErrors.UNKNOWN_SERVER_ERROR
        }
        
        if let balance = rawBalanceModel?.balance {
            return balance
        } else if let vaultError = rawBalanceModel?.error {
            let forageError = ForageError.create(
                code: vaultError.forageCode,
                httpStatusCode: vaultError.statusCode,
                message: vaultError.message
            )
            logger?.error(
                "Balance check failed for Payment Method \(paymentMethodReference).",
                error: forageError,
                attributes: nil
            )
            throw forageError
        }

        do {
            let forageError = CommonErrors.UNKNOWN_SERVER_ERROR
            logger?.critical(
                "Received malformed API response",
                error: forageError,
                attributes: nil
            )
            throw forageError
        } catch {
            throw error
        }
    }

    func getPaymentMethod(
        sessionToken: String,
        merchantID: String,
        paymentMethodRef: String,
        completion: @escaping (Result<PaymentMethodModel, Error>) -> Void
    ) {
        do { try provider.execute(model: PaymentMethodModel.self, endpoint: ForageAPI.getPaymentMethod(sessionToken: sessionToken, merchantID: merchantID, paymentMethodRef: paymentMethodRef), completion: completion) } catch { completion(.failure(error)) }
    }

    // MARK: Capture payment

    func capturePayment(
        pinCollector: VaultCollector,
        paymentReference: String
    ) async throws -> PaymentModel {
        let vaultResponse: VaultResponse?
        do {
            vaultResponse = try await collectPinForPayment(
                pinCollector: pinCollector,
                paymentReference: paymentReference,
                idempotencyKey: paymentReference,
                action: .capturePayment
            )
        } catch {
            throw error
        }
        
        guard let vaultData = vaultResponse?.data else {
            let forageError = CommonErrors.UNKNOWN_SERVER_ERROR
            logger?.error(
                "\(pinCollector.getVaultType()) proxy error. Failed to capture Payment \(paymentReference). No data or error from vault.",
                error: forageError,
                attributes: nil
            )
            throw forageError
        }
        
        let rawPaymentResponse: RawPaymentResponseModel?
        
        do {
            let decoder = JSONDecoder()
            rawPaymentResponse = try decoder.decode(RawPaymentResponseModel.self, from: vaultData)
        } catch {
            logger?.critical(
                "Failed to decode API response. Failed to capture Payment \(paymentReference).",
                error: error,
                attributes: nil
            )
            throw CommonErrors.UNKNOWN_SERVER_ERROR
        }
        
        if let vaultError = rawPaymentResponse?.error {
            let forageError = ForageError.create(
                code: vaultError.forageCode,
                httpStatusCode: vaultError.statusCode,
                message: vaultError.message
            )
            logger?.error(
                "Failed to capture Payment \(paymentReference).",
                error: forageError,
                attributes: nil
            )
            throw forageError
        }
        
        return PaymentModel(from: rawPaymentResponse!)
    }

    func getPayment(sessionToken: String, merchantID: String, paymentRef: String, completion: @escaping (Result<PaymentModel, Error>) -> Void) {
        do { try provider.execute(model: PaymentModel.self, endpoint: ForageAPI.getPayment(sessionToken: sessionToken, merchantID: merchantID, paymentRef: paymentRef), completion: completion) } catch { completion(.failure(error)) }
    }
    
    func getBothPaymentAndPaymentMethod(paymentRef: String) async throws -> String {
        let sessionToken = ForageSDK.shared.sessionToken
        let merchantID = ForageSDK.shared.merchantID
        
        do {
            let payment = try await awaitResult { completion in
                self.getPayment(
                    sessionToken: sessionToken,
                    merchantID: merchantID,
                    paymentRef: paymentRef,
                    completion: completion
                )
            }
            
            let paymentMethod = try await awaitResult { completion in
                self.getPaymentMethod(
                    sessionToken: sessionToken,
                    merchantID: merchantID,
                    paymentMethodRef: payment.paymentMethodRef,
                    completion: completion
                )
            }
            
            return paymentMethod.card.token
        } catch {
            throw error
        }
    }
    
    func onlyGetPaymentMethod(paymentMethodRef: String) async throws -> String {
        let sessionToken = ForageSDK.shared.sessionToken
        let merchantID = ForageSDK.shared.merchantID
        
        do {
            let paymentMethod = try await awaitResult { completion in
                self.getPaymentMethod(
                    sessionToken: sessionToken,
                    merchantID: merchantID,
                    paymentMethodRef: paymentMethodRef,
                    completion: completion
                )
            }
            
            return paymentMethod.card.token
        } catch {
            throw error
        }
    }
    
    typealias CollectTokenFunc = (_ reference: String) async throws -> String

    // MARK: Collect PIN

    func collectPinForDeferredCapture(
        pinCollector: VaultCollector,
        paymentReference: String
    ) async throws -> VaultResponse {
        do {
            return try await collectPinForPayment(
                pinCollector: pinCollector,
                paymentReference: paymentReference,
                idempotencyKey: UUID().uuidString,
                action: .deferCapture
            )
        } catch {
            throw error
        }
    }
    
    /// `ForageRequestModel` used for compose ForageSDK requests
    struct ForageRequestModel: Codable {
        let authorization: String
        let cardNumberToken: String
        let merchantID: String
        let xKey: [String: String]
    }
    
    private func requestPreamble(
        using collectTokenFunc: CollectTokenFunc,
        tokenRef: String
    ) async throws -> ForageRequestModel {
        let sessionToken = ForageSDK.shared.sessionToken
        let merchantID = ForageSDK.shared.merchantID

        do {
            let xKeyModel = try await awaitResult { completion in
                self.getXKey(sessionToken: sessionToken, merchantID: merchantID, completion: completion)
            }
            
            let token = try await collectTokenFunc(tokenRef)
            
            return ForageRequestModel(
                authorization: sessionToken,
                cardNumberToken: token,
                merchantID: merchantID,
                xKey: ["vgsXKey": xKeyModel.alias, "btXKey": xKeyModel.bt_alias]
            )
        }
    }

    /// Common Payment-related prologue across capturePayment and collectPin.
    /// Both `deferPaymentCapture` and `capturePayment` involve the same
    /// preliminerary data retrieval and a trip to the Vault (VGS or Basis Theory) Proxy
    private func collectPinForPayment(
        pinCollector: VaultCollector,
        paymentReference: String,
        idempotencyKey: String,
        action: VaultAction
    ) async throws -> VaultResponse {
        do {
            let collectPinRequest = try await requestPreamble(using: getBothPaymentAndPaymentMethod, tokenRef: paymentReference)

            let basePath = "/api/payments/\(paymentReference)"

            return try await submitPinToVault(
                pinCollector: pinCollector,
                vaultAction: action,
                idempotencyKey: idempotencyKey,
                path: "\(basePath)\(action.endpointSuffix)",
                request: collectPinRequest
            )
        } catch {
            throw error
        }
    }

    // MARK: Private helper methods

    /// Submit PIN to the Vault Proxy (Basis Theory or VGS)
    /// - Parameters:
    ///   - pinCollector: The PIN collection client
    ///   - vaultAction: The action performed against the vault.
    ///   - idempotencyKey: The value for the IDEMPOTENCY-KEY header
    ///   - path: The inbound HTTP path. Ends with /balance/, /capture/ or /collect_pin/
    ///   - request: Model  with data to perform request.
    private func submitPinToVault(
        pinCollector: VaultCollector,
        vaultAction: VaultAction,
        idempotencyKey: String,
        path: String,
        request: ForageRequestModel
    ) async throws -> VaultResponse {
        pinCollector.setCustomHeaders(headers: [
            "IDEMPOTENCY-KEY": idempotencyKey,
            "Merchant-Account": request.merchantID,
            "x-datadog-trace-id": ForageSDK.shared.traceId,
            "API-VERSION": "2024-01-08",
        ], xKey: request.xKey)

        let extraData = [
            "card_number_token": request.cardNumberToken
        ]

        do {
            return try await withCheckedThrowingContinuation { continuation in
                pinCollector.sendData(
                    path: path,
                    vaultAction: vaultAction,
                    extraData: extraData
                ) { result in
                    continuation.resume(returning: result)
                }
            }
        } catch {
            // TODO: What would this error be???
            throw error
        }
    }
}
