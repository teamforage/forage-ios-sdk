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
    private var pollingService: Polling

    init(
        provider: Provider = Provider(),
        logger: ForageLogger? = nil,
        ldManager: LDManagerProtocol,
        pollingService: Polling
    ) {
        self.provider = provider
        self.logger = logger?.setPrefix("")
        self.ldManager = ldManager
        self.pollingService = pollingService
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

            let vaultResult = try await submitPinToVault(
                pinCollector: pinCollector,
                vaultAction: .balanceCheck,
                idempotencyKey: UUID().uuidString,
                path: "/api/payment_methods/\(paymentMethodReference)/balance/",
                request: balanceRequest
            )

            _ = try await awaitResult { completion in
                self.pollingService.execute(
                    vaultResponse: vaultResult,
                    request: balanceRequest,
                    completion: completion
                )
            }

            let paymentMethodResult = try await awaitResult { completion in
                self.getPaymentMethod(
                    sessionToken: balanceRequest.authorization,
                    merchantID: balanceRequest.merchantID,
                    paymentMethodRef: paymentMethodReference,
                    completion: completion
                )
            }

            guard let balance = paymentMethodResult.balance else {
                let forageError = CommonErrors.UNKNOWN_SERVER_ERROR
                logger?.error(
                    "Balance check failed for Payment Method \(paymentMethodReference). Balance not attached",
                    error: forageError,
                    attributes: nil
                )
                throw forageError
            }

            return balance
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
        let sessionToken = ForageSDK.shared.sessionToken
        let merchantID = ForageSDK.shared.merchantID

        do {
            let (vaultResponse, forageRequest) = try await collectPinForPayment(
                pinCollector: pinCollector,
                paymentReference: paymentReference,
                action: .capturePayment
            )

            _ = try await awaitResult { completion in
                self.pollingService.execute(
                    vaultResponse: vaultResponse,
                    request: forageRequest,
                    completion: completion
                )
            }

            return try await awaitResult { completion in
                self.getPayment(
                    sessionToken: sessionToken,
                    merchantID: merchantID,
                    paymentRef: paymentReference,
                    completion: completion
                )
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
            let collectPinResult = try await collectPinForPayment(
                pinCollector: pinCollector,
                paymentReference: paymentReference,
                action: .deferCapture
            )
            return collectPinResult.vaultResponse
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
        action: VaultAction
    ) async throws -> (vaultResponse: VaultResponse, forageRequest: ForageRequestModel) {
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

            let vaultResponse = try await submitPinToVault(
                pinCollector: pinCollector,
                vaultAction: action,
                idempotencyKey: paymentReference,
                path: "\(basePath)\(action.endpointSuffix)",
                request: collectPinRequest
            )
            return (vaultResponse, collectPinRequest)
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
