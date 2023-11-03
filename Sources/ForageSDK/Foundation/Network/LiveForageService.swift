//
//  LiveForageService.swift
//  ForageSDK
//
//  Created by Tiago Oliveira on 30/10/22.
//  Copyright © 2022-Present Forage Technology Corporation. All rights reserved.
//

import Foundation

internal class LiveForageService: ForageService {
    // MARK: Properties

    internal var provider: Provider

    private var logger: ForageLogger?
    private var ldManager: LDManagerProtocol
    private var maxAttempts: Int = 90
    private var defaultPollingIntervalInMS: Int = 1000
    private var retryCount = 0

    init(provider: Provider = Provider(), logger: ForageLogger? = nil, ldManager: LDManagerProtocol) {
        self.provider = provider
        self.logger = logger?.setPrefix("")
        self.ldManager = ldManager
    }

    // MARK: Tokenize EBT card

    internal func tokenizeEBTCard(request: ForagePANRequestModel, completion: @escaping (Result<PaymentMethodModel, Error>) -> Void) {
        do {
            try provider.execute(model: PaymentMethodModel.self, endpoint: ForageAPI.tokenizeNumber(request: request), completion: completion) } catch { completion(.failure(error)) }
    }

    // MARK: X-key

    internal func getXKey(sessionToken: String, merchantID: String, completion: @escaping (Result<ForageXKeyModel, Error>) -> Void) {
        do { try provider.execute(model: ForageXKeyModel.self, endpoint: ForageAPI.xKey(sessionToken: sessionToken, merchantID: merchantID), completion: completion) } catch { completion(.failure(error)) }
    }

    // MARK: Check balance

    internal func checkBalance(
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
                path: "/api/payment_methods/\(paymentMethodReference)/balance/",
                request: balanceRequest
            )

            _ = try await awaitResult { completion in
                self.polling(
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
        } catch let error {
            throw error
        }
    }

    internal func getPaymentMethod(
        sessionToken: String,
        merchantID: String,
        paymentMethodRef: String,
        completion: @escaping (Result<PaymentMethodModel, Error>) -> Void
    ) {
        do { try provider.execute(model: PaymentMethodModel.self, endpoint: ForageAPI.getPaymentMethod(sessionToken: sessionToken, merchantID: merchantID, paymentMethodRef: paymentMethodRef), completion: completion) } catch { completion(.failure(error)) }
    }

    // MARK: Capture payment

    internal func capturePayment(
        pinCollector: VaultCollector,
        paymentReference: String
    ) async throws -> PaymentModel {
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

            let captureRequest = ForageRequestModel(
                authorization: sessionToken,
                paymentMethodReference: "",
                paymentReference: paymentReference,
                cardNumberToken: paymentMethod.card.token,
                merchantID: merchantID,
                xKey: ["vgsXKey": xKeyModel.alias, "btXKey": xKeyModel.bt_alias]
            )

            let vaultResult = try await submitPinToVault(
                pinCollector: pinCollector,
                path: "/api/payments/\(paymentReference)/capture/",
                request: captureRequest
            )

            _ = try await awaitResult { completion in
                self.polling(
                    vaultResponse: vaultResult,
                    request: captureRequest,
                    completion: completion
                )
            }

            return try await awaitResult { completion in
                self.getPayment(
                    sessionToken: captureRequest.authorization,
                    merchantID: captureRequest.merchantID,
                    paymentRef: captureRequest.paymentReference,
                    completion: completion
                )
            }
        } catch let error {
            throw error
        }
    }

    internal func getPayment(sessionToken: String, merchantID: String, paymentRef: String, completion: @escaping (Result<PaymentModel, Error>) -> Void) {
        do { try provider.execute(model: PaymentModel.self, endpoint: ForageAPI.getPayment(sessionToken: sessionToken, merchantID: merchantID, paymentRef: paymentRef), completion: completion) } catch { completion(.failure(error)) }
    }

    // MARK: Private helper methods

    private func awaitResult<T>(_ operation: @escaping (@escaping (Result<T, Error>) -> Void) -> Void) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            operation { result in
                continuation.resume(with: result)
            }
        }
    }

    /// Submit PIN to the Vault Proxy (Basis Theory or VGS)
    /// - Parameters:
    ///   - pinCollector: The PIN collection client
    ///   - path: The inbound HTTP path. Ends with /capture/ or /balance/
    ///   - request: Model  with data to perform request.
    private func submitPinToVault(
        pinCollector: VaultCollector,
        path: String,
        request: ForageRequestModel
    ) async throws -> VaultResponse {
        pinCollector.setCustomHeaders(headers: [
            "IDEMPOTENCY-KEY": UUID.init().uuidString,
            "Merchant-Account": request.merchantID,
            "x-datadog-trace-id": ForageSDK.shared.traceId,
        ], xKey: request.xKey)

        let extraData = [
            "card_number_token": request.cardNumberToken
        ]

        do {
            return try await withCheckedThrowingContinuation { continuation in
                pinCollector.sendData(
                    path: path,
                    vaultAction: VaultAction.capturePayment,
                    extraData: extraData
                ) { result in
                    continuation.resume(returning: result)
                }
            }
        } catch let error {
            throw error
        }
    }
}

// MARK: - Polling

extension LiveForageService: Polling {
    internal func polling(vaultResponse: VaultResponse, request: ForageRequestModel, completion: @escaping (Result<Data?, Error>) -> Void) {
        retryCount = 0

        if let error = vaultResponse.error {
            completion(.failure(error))
        } else if let data = vaultResponse.data, let urlResponse = vaultResponse.urlResponse {
            provider.processVaultData(model: MessageResponseModel.self, code: vaultResponse.statusCode, data: data, response: urlResponse) { [weak self] messageResponse in
                switch messageResponse {
                case .success(let message):
                    self?.pollingMessage(
                        contentId: message.contentId,
                        request: request) { pollingResult in
                            switch pollingResult {
                            case .success:
                                completion(.success(nil))
                            case .failure(let error):
                                completion(.failure(error))
                            }
                        }
                case .failure(let error):
                    self?.logger?.error("Failed to process vault proxy response for \(self?.getLogSuffix(request) ?? "N/A")", error: error, attributes: nil)
                    completion(.failure(error))
                }
            }
        } else {
            let emptyError = ServiceError.emptyError
            logger?.error(emptyError.rawValue, error: emptyError, attributes: nil)
            completion(.failure(emptyError))
        }
    }

    internal func pollingMessage(
        contentId: String,
        request: ForageRequestModel,
        completion: @escaping (Result<MessageResponseModel, Error>) -> Void)
    {
        do {
            try provider.execute(model: MessageResponseModel.self, endpoint: ForageAPI.message(contentId: contentId, sessionToken: request.authorization, merchantID: request.merchantID), completion: { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let data):
                    /// check message is not failed and is completed
                    if data.failed == false && data.status == "completed" {
                        completion(.success(data))
                        /// check message is failed to return error immediately
                    } else if data.failed == true {
                        /// Parse the error returned from SQS message and return it back
                        let error = data.errors[0]
                        let statusCode = error.statusCode
                        let forageErrorCode = error.forageCode
                        let message = error.message
                        let details = error.details
                        let forageError = ForageError(errors: [
                            ForageErrorObj(
                                httpStatusCode: statusCode,
                                code: forageErrorCode,
                                message: message,
                                details: details
                            ),
                        ])

                        self.logger?.error(
                            "Received SQS Error message for \(self.getLogSuffix(request))",
                            error: forageError,
                            attributes: nil)
                        completion(.failure(forageError))
                        /// check maxAttempts to retry
                    } else if self.retryCount < self.maxAttempts {
                        self.waitNextAttempt {
                            self.pollingMessage(
                                contentId: data.contentId,
                                request: request,
                                completion: completion
                            )
                        }
                        /// in case run out of attempts
                    } else {
                        self.logger?.error(
                            "Max polling attempts reached for \(self.getLogSuffix(request))",
                            error: nil,
                            attributes: nil
                        )
                        completion(.failure(ForageError(errors: [ForageErrorObj(httpStatusCode: 500, code: "unknown_server_error", message: "Unknown Server Error")])))
                    }

                case .failure(let error):
                    completion(.failure(error))
                }
            })
        } catch {
            completion(.failure(error))
        }
    }

    /// We generate a random jitter amount to add to our retry delay when polling for the status of
    /// Payments and Payment Methods so that we can avoid a thundering herd scenario in which there are
    /// several requests retrying at the same exact time.
    ///
    /// Returns a random double between -.025 and .025
    @objc
    internal func jitterAmountInSeconds() -> Double {
        return Double(Int.random(in: -25...25)) / 1000.0
    }

    /// Support function to update retry count and interval between attempts.
    ///
    /// - Parameters:
    ///  - completion: Which will return after a wait.
    internal func waitNextAttempt(completion: @escaping () -> Void) {
        var interval = self.defaultPollingIntervalInMS
        let pollingIntervals = ldManager.getPollingIntervals(ldClient: LDManager.getDefaultLDClient())
        if retryCount < pollingIntervals.count {
            interval = pollingIntervals[retryCount]
        }
        let intervalAsDouble = Double(interval) / 1000.0
        let nextPollTime = intervalAsDouble + self.jitterAmountInSeconds()

        retryCount = retryCount + 1

        DispatchQueue.main.asyncAfter(deadline: .now() + nextPollTime) {
            completion()
        }
    }

    // get the log suffix (action + resource name + resource ref)
    // using the given ForageRequestModel
    private func getLogSuffix(_ request: ForageRequestModel) -> String {
        let paymentReference = request.paymentMethodReference
        let paymentMethodReference = request.paymentMethodReference

        if !paymentReference.isEmpty {
            return "capture of Payment \(paymentReference)"
        }
        return "balance check of Payment Method \(paymentMethodReference)"
    }
}
