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
        // If any of the preamble requests fail, return back a generic response to the user
        guard let balanceRequest = await createRequestModel(using: getTokenFromPaymentMethod, tokenRef: paymentMethodReference) else {
            throw CommonErrors.UNKNOWN_SERVER_ERROR
        }
        
        // If the vault request fails for some unforeseen reason, return back a generic response to the user
        guard let rawBalanceModel: RawBalanceResponseModel = await submitPinToVault(
            pinCollector: pinCollector,
            vaultAction: .balanceCheck,
            idempotencyKey: UUID().uuidString,
            path: "/api/payment_methods/\(paymentMethodReference)/balance/",
            request: balanceRequest
        ) else {
            logger?.error(
                "\(pinCollector.getVaultType()) proxy error. Balance check failed for Payment Method \(paymentMethodReference). No data or error from vault.",
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
        guard let rawPaymentResponse: RawPaymentResponseModel = await collectPinForPayment(
            pinCollector: pinCollector,
            paymentReference: paymentReference,
            idempotencyKey: paymentReference,
            action: .capturePayment
        ) else {
            logger?.error(
                "\(pinCollector.getVaultType()) proxy error. Payment capture failed for Payment \(paymentReference). No data or error from vault.",
                error: CommonErrors.UNKNOWN_SERVER_ERROR,
                attributes: nil
            )
            throw CommonErrors.UNKNOWN_SERVER_ERROR
        }
        
        // Return back the expected EBT Network error to the user
        if let vaultError = rawPaymentResponse.error {
            let forageError = ForageError.create(
                code: vaultError.forageCode,
                httpStatusCode: vaultError.statusCode,
                message: vaultError.message
            )
            throw forageError
        }
        
        return PaymentModel(from: rawPaymentResponse)
    }
    
    typealias CollectTokenFunc = (_ sessionToken: String, _ merchantID: String, _ reference: String) async throws -> String

    // MARK: Collect PIN

    func collectPinForDeferredCapture(
        pinCollector: VaultCollector,
        paymentReference: String
    ) async throws -> Void {
        guard let _: Empty? = await collectPinForPayment(
            pinCollector: pinCollector,
            paymentReference: paymentReference,
            idempotencyKey: UUID().uuidString,
            action: .deferCapture
        ) else {
            logger?.error(
                "\(pinCollector.getVaultType()) proxy error. Deferred capture failed for Payment \(paymentReference). No data or error from vault.",
                error: CommonErrors.UNKNOWN_SERVER_ERROR,
                attributes: nil
            )
            return
        }
    }

    // MARK: Private structs
    
    /// `Empty` used to signify a generic, decodable type that returns nothing
    struct Empty: Decodable {}
    
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
    ) async -> ForageRequestModel? {
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
                xKey: ["vgsXKey": xKeyModel.alias, "btXKey": xKeyModel.bt_alias]
            )
        } catch {
            logger?.error(
                "Failure for PaymentMethod/Payment ref \(tokenRef). GET for Payment, Payment Method, or Encryption Key failed.",
                error: nil,
                attributes: nil
            )
            return nil
        }
    }
    
    /// Common Payment-related prologue across capturePayment and collectPin.
    /// Both `deferPaymentCapture` and `capturePayment` involve the same
    /// preliminerary data retrieval and a trip to the Vault (VGS or Basis Theory) Proxy
    private func collectPinForPayment<T: Decodable>(
        pinCollector: VaultCollector,
        paymentReference: String,
        idempotencyKey: String,
        action: VaultAction
    ) async -> T? {
        guard let collectPinRequest = await createRequestModel(using: getTokenFromPayment, tokenRef: paymentReference) else {
            return nil
        }
        
        let basePath = "/api/payments/\(paymentReference)"

        return await submitPinToVault(
            pinCollector: pinCollector,
            vaultAction: action,
            idempotencyKey: idempotencyKey,
            path: "\(basePath)\(action.endpointSuffix)",
            request: collectPinRequest
        )
    }

    /// Submit PIN to the Vault Proxy (Basis Theory or VGS)
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
    ) async -> T? {
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
                ) { (result: T?) in
                    continuation.resume(returning: result)
                }
            }
        } catch {
            return nil
        }
    }
    
    private func getTokenFromPayment(sessionToken: String, merchantID: String, paymentRef: String) async throws -> String {
        do {
            let payment = try await awaitResult { completion in
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
    
    internal func getPayment(sessionToken: String, merchantID: String, paymentRef: String, completion: @escaping (Result<PaymentModel, Error>) -> Void) {
        do { try provider.execute(model: PaymentModel.self, endpoint: ForageAPI.getPayment(sessionToken: sessionToken, merchantID: merchantID, paymentRef: paymentRef), completion: completion) } catch { completion(.failure(error)) }
    }
    
    internal func getPaymentMethod(
        sessionToken: String,
        merchantID: String,
        paymentMethodRef: String,
        completion: @escaping (Result<PaymentMethodModel, Error>) -> Void
    ) {
        do { try provider.execute(model: PaymentMethodModel.self, endpoint: ForageAPI.getPaymentMethod(sessionToken: sessionToken, merchantID: merchantID, paymentMethodRef: paymentMethodRef), completion: completion) } catch { completion(.failure(error)) }
    }
    
    internal func getXKey(sessionToken: String, merchantID: String, completion: @escaping (Result<ForageXKeyModel, Error>) -> Void) {
        do { try provider.execute(model: ForageXKeyModel.self, endpoint: ForageAPI.xKey(sessionToken: sessionToken, merchantID: merchantID), completion: completion) } catch { completion(.failure(error)) }
    }
}
