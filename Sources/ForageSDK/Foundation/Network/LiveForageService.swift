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
        let sessionToken = ForageSDK.shared.sessionToken
        let merchantID = ForageSDK.shared.merchantID

        do {
            // TODO: parallelize the first 2 requests!

            let xKeyModel = try await awaitResult { completion in
                self.getXKey(sessionToken: sessionToken, merchantID: merchantID, completion: completion)
            }
            let paymentMethod = try await awaitResult { completion in
                self.getPaymentMethod(
                    sessionToken: sessionToken,
                    merchantID: merchantID,
                    paymentMethodRef: paymentMethodReference,
                    completion: completion
                )
            }

            let balanceRequest = ForageRequestModel(
                authorization: sessionToken,
                paymentMethodReference: paymentMethodReference,
                paymentReference: "",
                cardNumberToken: paymentMethod.card.token,
                merchantID: merchantID,
                xKey: ["vgsXKey": xKeyModel.alias, "btXKey": xKeyModel.bt_alias]
            )

            let vaultResponse = try await submitPinToVault(
                pinCollector: pinCollector,
                vaultAction: .balanceCheck,
                idempotencyKey: UUID().uuidString,
                path: "/api/payment_methods/\(paymentMethodReference)/balance/",
                request: balanceRequest
            )
            
            // If there was a vaultResponse.error, it was already thrown in the function call above!
            guard let data = vaultResponse.data else {
                let forageError = CommonErrors.UNKNOWN_SERVER_ERROR
                logger?.error(
                    "Balance check failed for Payment Method \(paymentMethodReference). No data or error from vault.",
                    error: forageError,
                    attributes: nil
                )
                throw forageError
            }
            
            // Data is either a forage error or the balance model
            var error: ForageError? = nil
            do {
                let decoder = JSONDecoder()
                let rawBalanceModel = try decoder.decode(RawBalanceModel.self, from: data)
                if let balance = rawBalanceModel.balance {
                    return balance
                } else if let errors = rawBalanceModel.errors {
                    error = ForageError.create(code: errors.forageCode, httpStatusCode: errors.statusCode, message: errors.message)
                    logger?.error(
                        "Balance check failed for Payment Method \(paymentMethodReference).",
                        error: error,
                        attributes: nil
                    )
                }
            } catch {}
            
            if (error != nil) {
                throw error!
            }
            
            do {
                let decoder = JSONDecoder()
                throw try decoder.decode(ForageError.self, from: data)
            } catch {}
            
            let forageError = CommonErrors.UNKNOWN_SERVER_ERROR
            logger?.error(
                "Balance check failed for Payment Method \(paymentMethodReference). No data or error from vault.",
                error: forageError,
                attributes: nil
            )
            throw forageError
            // If data is null, the error was that we couldn't send the request to the proxy. There will be an error field,
            // but we will already have thrown that error in the function above.
            // Therefore, data is always non-null and can be a balance object or a forage error.
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
        do {
            let vaultResponse = try await collectPinForPayment(
                pinCollector: pinCollector,
                paymentReference: paymentReference,
                idempotencyKey: paymentReference,
                action: .capturePayment
            )
            
            if let data = vaultResponse.data {
                do {
                    let decoder = JSONDecoder()
                    return try decoder.decode(PaymentModel.self, from: data)
                } catch {
                    let forageError = CommonErrors.UNKNOWN_SERVER_ERROR
                    logger?.error(
                        "Capture payment failed for Payment \(paymentReference). Unknown reponse from vault.",
                        error: forageError,
                        attributes: nil
                    )
                    throw forageError
                }
            } else if let error = vaultResponse.error {
                logger?.error(
                    "Capture payment failed for Payment Method \(paymentReference).",
                    error: error,
                    attributes: nil
                )
                throw error
            } else {
                let forageError = CommonErrors.UNKNOWN_SERVER_ERROR
                logger?.error(
                    "Capture payment failed for Payment \(paymentReference). No data or error from vault.",
                    error: forageError,
                    attributes: nil
                )
                throw forageError
            }
        } catch {
            throw error
        }
    }

    func getPayment(sessionToken: String, merchantID: String, paymentRef: String, completion: @escaping (Result<PaymentModel, Error>) -> Void) {
        do { try provider.execute(model: PaymentModel.self, endpoint: ForageAPI.getPayment(sessionToken: sessionToken, merchantID: merchantID, paymentRef: paymentRef), completion: completion) } catch { completion(.failure(error)) }
    }

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

    /// Common Payment-related prologue across capturePayment and collectPin.
    /// Both `deferPaymentCapture` and `capturePayment` involve the same
    /// preliminerary data retrieval and a trip to the Vault (VGS or Basis Theory) Proxy
    private func collectPinForPayment(
        pinCollector: VaultCollector,
        paymentReference: String,
        idempotencyKey: String,
        action: VaultAction
    ) async throws -> VaultResponse {
        let sessionToken = ForageSDK.shared.sessionToken
        let merchantID = ForageSDK.shared.merchantID

        do {
            // TODO: parallelize the first 2 requests!
            let xKeyModel = try await awaitResult { completion in
                self.getXKey(sessionToken: sessionToken, merchantID: merchantID, completion: completion)
            }
            let payment = try await awaitResult { completion in
                self.getPayment(
                    sessionToken: sessionToken,
                    merchantID: merchantID,
                    paymentRef: paymentReference,
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

            let collectPinRequest = ForageRequestModel(
                authorization: sessionToken,
                paymentMethodReference: "",
                paymentReference: paymentReference,
                cardNumberToken: paymentMethod.card.token,
                merchantID: merchantID,
                xKey: ["vgsXKey": xKeyModel.alias, "btXKey": xKeyModel.bt_alias]
            )

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
            "API-VERSION": "2024-01-08"
        ], xKey: request.xKey)

        let extraData = [
            "card_number_token": request.cardNumberToken
        ]

        do {
            let vaultResponse = try await withCheckedThrowingContinuation { continuation in
                pinCollector.sendData(
                    path: path,
                    vaultAction: vaultAction,
                    extraData: extraData
                ) { result in
                    continuation.resume(returning: result)
                }
            }

            if let error = vaultResponse.error {
                throw error
            }

            return vaultResponse
        } catch {
            throw error
        }
    }
}
