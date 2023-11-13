//
//  LivePollingService.swift
//
//
//  Created by Danilo Joksimovic on 2023-11-10.
//

import Foundation

// MARK: - Polling

class LivePollingService: Polling {
    private var provider: Provider
    private var logger: ForageLogger?
    private var ldManager: LDManagerProtocol

    private var defaultPollingIntervalInMS: Int = 1000
    private var retryCount = 0

    init(provider: Provider = Provider(), logger: ForageLogger? = nil, ldManager: LDManagerProtocol) {
        self.provider = provider
        self.logger = logger?.setPrefix("")
        self.ldManager = ldManager
    }

    /// - Parameters:
    ///   - vaultResponse: A `VaultResponse` object containing data, status code, and other response details.
    ///   - request: An instance of `ForageRequestModel` containing request-specific information.
    ///   - completion: The closure returns a `Result` containing either `nil` (success) response or an `Error`.
    func execute(
        vaultResponse: VaultResponse,
        request: ForageRequestModel,
        completion: @escaping (Result<Data?, Error>) -> Void
    ) {
        retryCount = 0

        if let data = vaultResponse.data, let urlResponse = vaultResponse.urlResponse {
            provider.processVaultData(
                model: MessageResponseModel.self,
                code: vaultResponse.statusCode,
                data: data,
                response: urlResponse
            ) { [weak self] messageResponse in
                switch messageResponse {
                case let .success(message):
                    self?.getMessage(
                        contentId: message.contentId,
                        request: request
                    ) { pollingResult in
                        switch pollingResult {
                        case .success:
                            completion(.success(nil))
                        case let .failure(error):
                            completion(.failure(error))
                        }
                    }
                case let .failure(error):
                    self?.logger?.error("Failed to process vault proxy response for \(self?.getLogSuffix(request) ?? "N/A")", error: error, attributes: nil)
                    completion(.failure(error))
                }
            }
        } else {
            logger?.error("Response from vault proxy was malformed: \(vaultResponse)", error: ServiceError.emptyError, attributes: nil)
            completion(.failure(CommonErrors.UNKNOWN_SERVER_ERROR))
        }
    }

    /// Fetches an SQS message based on its content ID.
    /// This method is part of a polling mechanism, repeatedly checking the status of a message
    /// until it is marked as completed, failed or a maximum retry limit is reached.
    ///
    /// - Parameters:
    ///  - contentId: ID of the SQS message to be fetched
    ///  - request: An instance of `ForageRequestModel` containing request-specific information.
    ///  - completion: The closure returns a `Result` containing either a `MessageResponseModel` or a `Error`.
    func getMessage(
        contentId: String,
        request: ForageRequestModel,
        completion: @escaping (Result<MessageResponseModel, Error>) -> Void
    ) {
        do {
            try provider.execute(model: MessageResponseModel.self, endpoint: ForageAPI.message(contentId: contentId, sessionToken: request.authorization, merchantID: request.merchantID), completion: { [weak self] result in
                guard let self = self else { return }

                switch result {
                case let .success(message):
                    let didReceiveFailedMessage = message.failed
                    let didNotExceedMaxAttempts = self.retryCount < self.getMaxAttempts()

                    if self.didReceiveCompletedMessage(message) {
                        completion(.success(message))
                    } else if didReceiveFailedMessage {
                        let error = message.errors[0]
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
                            attributes: nil
                        )
                        completion(.failure(forageError))
                    } else if didNotExceedMaxAttempts {
                        self.waitNextAttempt {
                            self.getMessage(
                                contentId: message.contentId,
                                request: request,
                                completion: completion
                            )
                        }
                    } else {
                        self.logger?.error(
                            "Max polling attempts reached for \(self.getLogSuffix(request))",
                            error: nil,
                            attributes: nil
                        )
                        completion(.failure(CommonErrors.UNKNOWN_SERVER_ERROR))
                    }

                case let .failure(error):
                    // malformed response, API is unavailable, etc.
                    completion(.failure(error))
                }
            })
        } catch {
            logger?.error(
                "getMessage failed",
                error: error,
                attributes: nil
            )
            // Invalid request URL
            completion(.failure(error))
        }
    }

    /// We generate a random jitter amount to add to our retry delay when polling for the status of
    /// Payments and Payment Methods so that we can avoid a thundering herd scenario in which there are
    /// several requests retrying at the same exact time.
    ///
    /// Returns a random double between -.025 and .025
    @objc
    func jitterAmountInSeconds() -> Double {
        Double(Int.random(in: -25...25)) / 1000.0
    }

    /// Support function to update retry count and interval between attempts.
    ///
    /// - Parameters:
    ///  - completion: Which will return after a wait.
    func waitNextAttempt(completion: @escaping () -> Void) {
        var interval = defaultPollingIntervalInMS
        let pollingIntervals = ldManager.getPollingIntervals(ldClient: LDManager.getDefaultLDClient())
        if retryCount < pollingIntervals.count {
            interval = pollingIntervals[retryCount]
        }
        let intervalAsDouble = Double(interval) / 1000.0
        let nextPollTime = intervalAsDouble + jitterAmountInSeconds()

        incrementRetryCount()

        DispatchQueue.main.asyncAfter(deadline: .now() + nextPollTime) {
            completion()
        }
    }

    func didReceiveCompletedMessage(_ message: MessageResponseModel) -> Bool {
        message.failed == false && message.status == "completed"
    }

    func incrementRetryCount() {
        retryCount += 1
    }

    func getMaxAttempts() -> Int {
        90
    }

    // Get the log suffix (action + resource name + resource ref)
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
