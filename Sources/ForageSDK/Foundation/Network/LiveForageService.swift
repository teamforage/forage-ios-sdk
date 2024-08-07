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

    // MARK: Check balance

    func checkBalance(
        pinCollector: VaultCollector,
        paymentMethodReference: String
    ) async throws -> BalanceModel {
        let rawBalanceModel: RawBalanceResponseModel?
        do {
            // If any of the preamble requests fail, return back a generic response to the user
            let balanceRequest = try await createRequestModel(using: getTokenFromPaymentMethod, tokenRef: paymentMethodReference)

            // If the vault request fails for some unforeseen reason, return back a generic response to the user
            rawBalanceModel = try await submitPinToVault(
                pinCollector: pinCollector,
                vaultAction: .balanceCheck,
                idempotencyKey: UUID().uuidString,
                path: "/api/payment_methods/\(paymentMethodReference)/balance/",
                request: balanceRequest
            )
        } catch {
            throw error
        }

        guard let rawBalanceModel = rawBalanceModel else {
            logger?.critical(
                "Received malformed Vault response",
                error: CommonErrors.UNKNOWN_SERVER_ERROR,
                attributes: nil
            )
            throw CommonErrors.UNKNOWN_SERVER_ERROR
        }

        // Return the balance back to the user
        if let balance = rawBalanceModel.balance {
            return balance
        }

        // ELSE return back the expected EBT Network error to the user
        if let vaultError = rawBalanceModel.error {
            let forageError = ForageError.create(
                code: vaultError.forageCode,
                httpStatusCode: vaultError.statusCode,
                message: vaultError.message
            )
            throw forageError
        }

        // This should be an unreachable codepath, but the return object of the balance request
        // has all nullable fields
        logger?.critical(
            "Received malformed Vault response",
            error: CommonErrors.UNKNOWN_SERVER_ERROR,
            attributes: nil
        )
        throw CommonErrors.UNKNOWN_SERVER_ERROR
    }

    // MARK: Capture payment

    func capturePayment(
        pinCollector: VaultCollector,
        paymentReference: String
    ) async throws -> PaymentModel {
        // If the vault request fails for some unforeseen reason or the preamble requests fail,
        // return back a generic response to the user
        let paymentResponse: PaymentModel?
        do {
            paymentResponse = try await collectPinForPayment(
                pinCollector: pinCollector,
                paymentReference: paymentReference,
                idempotencyKey: paymentReference,
                action: .capturePayment
            )
        } catch {
            throw error
        }

        guard let paymentResponse = paymentResponse else {
            logger?.critical(
                "Received malformed Vault response",
                error: CommonErrors.UNKNOWN_SERVER_ERROR,
                attributes: nil
            )
            throw CommonErrors.UNKNOWN_SERVER_ERROR
        }

        // Return back the expected EBT Network error to the user
        if let vaultError = paymentResponse.error {
            let forageError = ForageError.create(
                code: vaultError.forageCode,
                httpStatusCode: vaultError.statusCode,
                message: vaultError.message
            )
            throw forageError
        }

        return paymentResponse
    }

    typealias CollectTokenFunc = (_ sessionToken: String, _ merchantID: String, _ reference: String) async throws -> String

    // MARK: Collect PIN

    func collectPinForDeferredCapture(
        pinCollector: VaultCollector,
        paymentReference: String
    ) async throws {
        do {
            let _: Empty? = try await collectPinForPayment(
                pinCollector: pinCollector,
                paymentReference: paymentReference,
                idempotencyKey: UUID().uuidString,
                action: .deferCapture
            )
        } catch {
            throw error
        }
    }

    // MARK: Private structs

    /// `Empty` used to signify a generic, decodable type that returns nothing
    private struct Empty: Decodable {
        // stopgap to catch malformed responses, because Decodable {} (empty) treats every response as decodable
        let dummyResponse: String
    }

    /// `ForageRequestModel` used for compose ForageSDK requests
    private struct ForageRequestModel: Codable {
        let authorization: String
        let cardNumberToken: String
        let merchantID: String
        let xKey: [String: String]
    }

    // MARK: Private helper methods

    /// Common logic required for all requests to the proxy.
    private func createRequestModel(
        using collectTokenFunc: CollectTokenFunc,
        tokenRef: String
    ) async throws -> ForageRequestModel {
        let sessionToken = ForageSDK.shared.sessionToken
        let merchantID = ForageSDK.shared.merchantID

        do {
            // TODO: Parallelize getting xKeyModel and token
            let xKeyModel = try await awaitResult { completion in
                self.getXKey(sessionToken: sessionToken, merchantID: merchantID, completion: completion)
            }

            let token = try await collectTokenFunc(sessionToken, merchantID, tokenRef)

            return ForageRequestModel(
                authorization: sessionToken,
                cardNumberToken: token,
                merchantID: merchantID,
                xKey: ["btXKey": xKeyModel.bt_alias]
            )
        } catch {
            logger?.error(
                "Failure for PaymentMethod/Payment ref \(tokenRef). GET for Payment, Payment Method, or Encryption Key failed.",
                error: nil,
                attributes: nil
            )
            throw error
        }
    }

    /// Common Payment-related prologue across capturePayment and collectPin.
    /// Both `deferPaymentCapture` and `capturePayment` involve the same
    /// preliminerary data retrieval and a trip to the Vault (Forage or Basis Theory) Proxy
    private func collectPinForPayment<T: Decodable>(
        pinCollector: VaultCollector,
        paymentReference: String,
        idempotencyKey: String,
        action: VaultAction
    ) async throws -> T? {
        do {
            let collectPinRequest = try await createRequestModel(using: getTokenFromPayment, tokenRef: paymentReference)

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

    /// Submit PIN to the Vault Proxy (Basis Theory or Forage)
    /// - Parameters:
    ///   - pinCollector: The PIN collection client
    ///   - vaultAction: The action performed against the vault.
    ///   - idempotencyKey: The value for the IDEMPOTENCY-KEY header
    ///   - path: The inbound HTTP path. Ends with /balance/, /capture/ or /collect_pin/
    ///   - request: Model  with data to perform request.
    private func submitPinToVault<T: Decodable>(
        pinCollector: VaultCollector,
        vaultAction: VaultAction,
        idempotencyKey: String,
        path: String,
        request: ForageRequestModel
    ) async throws -> T? {
        pinCollector.setCustomHeaders(headers: [
            "IDEMPOTENCY-KEY": idempotencyKey,
            "Merchant-Account": request.merchantID,
            "x-datadog-trace-id": ForageSDK.shared.traceId,
            "API-VERSION": "2024-01-08",
            "Session-Token": "Bearer \(request.authorization)",
        ], xKey: request.xKey)

        let extraData = [
            "card_number_token": request.cardNumberToken
        ]

        do {
            let (result, error) = try await withCheckedThrowingContinuation { continuation in
                pinCollector.sendData(
                    path: path,
                    vaultAction: vaultAction,
                    extraData: extraData
                ) { (result: T?, error: ForageError?) in
                    continuation.resume(returning: (result, error))
                }
            }

            if let error = error {
                throw error
            }

            return result
        }
    }

    private func getTokenFromPayment(sessionToken: String, merchantID: String, paymentRef: String) async throws -> String {
        do {
            /// We only decode what we need here using `ThinPaymentModel`
            /// (e.g. the associated `paymentMethodRef`)
            /// beacuse many of the `PaymentModel` properties (e.g. `amount`) may be `nil`
            /// until the Payment is updated and captured.
            let payment: ThinPaymentModel = try await awaitResult { completion in
                self.getPayment(
                    sessionToken: sessionToken,
                    merchantID: merchantID,
                    paymentRef: paymentRef,
                    completion: completion
                )
            }

            return try await getTokenFromPaymentMethod(sessionToken: sessionToken, merchantID: merchantID, paymentMethodRef: payment.paymentMethodRef)
        } catch {
            throw error
        }
    }

    private func getTokenFromPaymentMethod(sessionToken: String, merchantID: String, paymentMethodRef: String) async throws -> String {
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

    func getPayment<T: Decodable>(sessionToken: String, merchantID: String, paymentRef: String, completion: @escaping (Result<T, Error>) -> Void) {
        do { try provider.execute(model: T.self, endpoint: ForageAPI.getPayment(sessionToken: sessionToken, merchantID: merchantID, paymentRef: paymentRef), completion: completion) } catch { completion(.failure(error)) }
    }

    func getPaymentMethod(
        sessionToken: String,
        merchantID: String,
        paymentMethodRef: String,
        completion: @escaping (Result<PaymentMethodModel, Error>) -> Void
    ) {
        do { try provider.execute(model: PaymentMethodModel.self, endpoint: ForageAPI.getPaymentMethod(sessionToken: sessionToken, merchantID: merchantID, paymentMethodRef: paymentMethodRef), completion: completion) } catch { completion(.failure(error)) }
    }

    func getXKey(sessionToken: String, merchantID: String, completion: @escaping (Result<ForageXKeyModel, Error>) -> Void) {
        do { try provider.execute(model: ForageXKeyModel.self, endpoint: ForageAPI.xKey(sessionToken: sessionToken, merchantID: merchantID), completion: completion) } catch { completion(.failure(error)) }
    }
}
