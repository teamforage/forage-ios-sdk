//
//  ForageSDK+ForageServices.swift
//  ForageSDK
//
//  Created by Tiago Oliveira on 22/11/22.
//  Copyright © 2022-Present Forage Technology Corporation. All rights reserved.
//

import Foundation

/**
 Interface for Forage SDK Services
 */
protocol ForageSDKService: AnyObject {
    /// Create a Forage [PaymentMethod](https://docs.joinforage.app/reference/payment-methods#paymentmethod-object) object that represents the EBT Card number.
    ///
    /// - Parameters:
    ///  - foragePanTextField: Text field for collecting the PAN (Primary Account Number) of the EBT card.
    ///  - customerID: A unique ID for the end customer making the payment. We recommend that you hash this value.
    ///  - reusable: Optional value indicating if the `PaymentMethod` is reusable.
    ///  - completion: The closure returns a `Result` containing either a `PaymentMethodModel` or an `Error`. [Read more](https://docs.joinforage.app/reference/create-payment-method)
    func tokenizeEBTCard(
        foragePanTextField: ForagePANTextField,
        customerID: String,
        reusable: Bool?,
        completion: @escaping (Result<PaymentMethodModel, Error>) -> Void
    )

    /// Check the balance of an EBT Card.
    ///
    /// Returns the `snap`and `cash` (EBT Cash) balance available on the EBT Card, in addition to a timestamp for when the balance was last updated.
    ///
    /// - Parameters:
    ///  - foragePinTextField: A text field for secure PIN collection.
    ///  - paymentMethodReference: A string identifier that refers to an instance in Forage's database of a [PaymentMethod](https://docs.joinforage.app/reference/create-payment-method)
    ///  - completion: The closure returns a `Result` containing either a `BalanceModel` or an `Error`.
    func checkBalance(
        foragePinTextField: ForagePINTextField,
        paymentMethodReference: String,
        completion: @escaping (Result<BalanceModel, Error>) -> Void
    )

    /// Immediately capture a payment using the customer's EBT card PIN.
    ///
    /// - Parameters:
    ///  - foragePinTextField: A text field for secure PIN collection.
    ///  - paymentReference: The reference hash of the `Payment` that you're capturing. Refers to an instance in Forage's database of a [Payment](https://docs.joinforage.app/reference/create-a-payment)
    ///  - completion: The closure returns a `Result` containing either a `PaymentModel` or an `Error`.
    func capturePayment(
        foragePinTextField: ForagePINTextField,
        paymentReference: String,
        completion: @escaping (Result<PaymentModel, Error>) -> Void
    )

    /// Collect the customer's PIN for an EBT payment and defer the capture of the payment to the server.
    ///
    /// - Parameters:
    ///  - foragePinTextField: A text field for secure PIN collection.
    ///  - paymentReference: Reference hash for the `Payment` that you plan on capturing on the server. Refers to an instance in Forage's database of a [Payment](https://docs.joinforage.app/reference/create-a-payment)
    ///  - completion: Completion handler returning a `Result` with either success (`Void`) or `Error`.
    func deferPaymentCapture(
        foragePinTextField: ForagePINTextField,
        paymentReference: String,
        completion: @escaping (Result<Void, Error>) -> Void
    )
}

extension ForageSDK: ForageSDKService {
    public func tokenizeEBTCard(
        foragePanTextField: ForagePANTextField,
        customerID: String,
        reusable: Bool? = true,
        completion: @escaping (Result<PaymentMethodModel, Error>) -> Void
    ) {
        _ = ForageSDK.logger?
            .setPrefix("tokenizeEBTCard")
            .addContext(ForageLogContext(
                customerID: customerID,
                merchantRef: merchantID
            ))
            .notice("Called tokenizeEBTCard for Customer \(customerID)", attributes: nil)

        let request = ForagePANRequestModel(
            authorization: ForageSDK.shared.sessionToken,
            merchantID: ForageSDK.shared.merchantID,
            panNumber: foragePanTextField.getActualPAN(),
            type: CardType.EBT.rawValue,
            customerID: customerID,
            reusable: reusable ?? true
        )
        service?.tokenizeEBTCard(request: request, completion: completion)
    }

    public func checkBalance(
        foragePinTextField: ForagePINTextField,
        paymentMethodReference: String,
        completion: @escaping (Result<BalanceModel, Error>) -> Void
    ) {
        _ = ForageSDK.logger?
            .setPrefix("checkBalance")
            .addContext(ForageLogContext(
                merchantRef: merchantID,
                paymentMethodRef: paymentMethodReference
            ))
            .notice("Called ForageSDK.shared.checkBalance for Payment Method \(paymentMethodReference)", attributes: nil)

        guard let forageService = service else {
            reportIllegalState(for: "checkBalance", dueTo: "ForageService was not initialized")
            completion(.failure(CommonErrors.UNKNOWN_SERVER_ERROR))
            return
        }

        guard validatePin(foragePinTextField: foragePinTextField) else {
            completion(.failure(CommonErrors.INCOMPLETE_PIN_ERROR))
            return
        }

        let pinCollector = foragePinTextField.getPinCollector()

        // This block is used for tracking important Metrics!
        // -----------------------------------------------------
        let responseMonitor = CustomerPerceivedResponseMonitor.newMeasurement(
            vaultAction: .balanceCheck,
            metricsLogger: ForageSDK.logger
        )
        responseMonitor.start()
        // ------------------------------------------------------

        Task.init {
            do {
                let balanceResult = try await forageService.checkBalance(
                    pinCollector: pinCollector,
                    paymentMethodReference: paymentMethodReference
                )
                ForageSDK.logger?.notice("Balance check succeeded for PaymentMethod \(paymentMethodReference)", attributes: nil)

                responseMonitor.setEventOutcome(.success).setHttpStatusCode(200).end()
                responseMonitor.logResult()

                completion(.success(balanceResult))
            } catch {
                logErrorResponse("Balance check failed for PaymentMethod \(paymentMethodReference)", error: error, attributes: nil, responseMonitor: responseMonitor)
                completion(.failure(error))
            }
        }
    }

    public func capturePayment(
        foragePinTextField: ForagePINTextField,
        paymentReference: String,
        completion: @escaping (Result<PaymentModel, Error>) -> Void
    ) {
        _ = ForageSDK.logger?
            .setPrefix("capturePayment")
            .addContext(ForageLogContext(
                merchantRef: merchantID,
                paymentRef: paymentReference
            ))
            .notice("Called capturePayment for Payment \(paymentReference)", attributes: nil)

        guard let forageService = service else {
            reportIllegalState(for: "capturePayment", dueTo: "ForageService was not initialized")
            completion(.failure(CommonErrors.UNKNOWN_SERVER_ERROR))
            return
        }

        guard validatePin(foragePinTextField: foragePinTextField) else {
            completion(.failure(CommonErrors.INCOMPLETE_PIN_ERROR))
            return
        }

        let pinCollector = foragePinTextField.getPinCollector()

        // This block is used for tracking important Metrics!
        // -----------------------------------------------------
        let responseMonitor = CustomerPerceivedResponseMonitor.newMeasurement(
            vaultAction: VaultAction.capturePayment,
            metricsLogger: ForageSDK.logger
        )
        responseMonitor.start()
        // ------------------------------------------------------

        Task.init {
            do {
                let paymentResult = try await forageService.capturePayment(
                    pinCollector: pinCollector,
                    paymentReference: paymentReference
                )
                ForageSDK.logger?.notice("Capture succeeded for Payment \(paymentReference)", attributes: nil)

                responseMonitor.setEventOutcome(.success).setHttpStatusCode(200).end()
                responseMonitor.logResult()

                completion(.success(paymentResult))
            } catch {
                logErrorResponse("Capture failed for Payment \(paymentReference)", error: error, attributes: nil, responseMonitor: responseMonitor)
                completion(.failure(error))
            }
        }
    }

    public func deferPaymentCapture(
        foragePinTextField: ForagePINTextField,
        paymentReference: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        _ = ForageSDK.logger?
            .setPrefix("deferPaymentCapture")
            .addContext(ForageLogContext(
                merchantRef: merchantID,
                paymentRef: paymentReference
            ))
            .notice("Called deferPaymentCapture for Payment \(paymentReference)", attributes: nil)

        guard let forageService = service else {
            reportIllegalState(for: "deferPaymentCapture", dueTo: "ForageService was not initialized")
            completion(.failure(CommonErrors.UNKNOWN_SERVER_ERROR))
            return
        }

        guard validatePin(foragePinTextField: foragePinTextField) else {
            completion(.failure(CommonErrors.INCOMPLETE_PIN_ERROR))
            return
        }

        let pinCollector = foragePinTextField.getPinCollector()

        Task.init {
            do {
                _ = try await forageService.collectPinForDeferredCapture(
                    pinCollector: pinCollector,
                    paymentReference: paymentReference
                )
                ForageSDK.logger?.notice("deferPaymentCapture succeeded for Payment \(paymentReference)", attributes: nil)

                completion(.success(()))
            } catch {
                logErrorResponse("deferPaymentCapture failed for Payment \(paymentReference)", error: error, attributes: nil, responseMonitor: nil)
                completion(.failure(error))
            }
        }
    }

    /// Reports an illegal state by logging a critical error .
    ///
    /// This method is utilized to indicate that a precondition has not been met or an object is in an
    /// illegal state when invoking a particular method, aiding in identifying and rectifying improper
    /// usage or unexpected conditions during development.
    ///
    /// - Parameters:
    ///   - methodName: The name of the method where the illegal state occurred.
    ///   - reason: A description of the illegal state or the unmet precondition.
    private func reportIllegalState(for methodName: String, dueTo reason: String) {
        let assertionMessage = "Attempted to call \(methodName), but \(reason)"
        ForageSDK.logger?.critical(assertionMessage, error: nil, attributes: nil)
    }

    /// Validates the completeness of the PIN entered in the specified text field.
    /// - Returns: `true` if the PIN comprises 4 digits and is ready for submission; otherwise, logs a warning and returns `false`.
    private func validatePin(foragePinTextField: ForagePINTextField) -> Bool {
        if foragePinTextField.isComplete {
            return true
        }
        ForageSDK.logger?.warn(
            "User attempted to submit an incomplete PIN",
            error: CommonErrors.INCOMPLETE_PIN_ERROR,
            attributes: nil
        )
        return false
    }

    /// Determine if we should log an error or a warning
    func logErrorResponse(_ message: String, error: Error, attributes: [String: Encodable]?, responseMonitor: ResponseMonitor?) {
        responseMonitor?.setForageErrorCode(error)
        if let statusCode = (error as? ForageError)?.httpStatusCode, let forageLogger = ForageSDK.logger {
            responseMonitor?.setHttpStatusCode(statusCode)
            let isWarningLevelStatusCode = [400, 429]
            let logLevel = isWarningLevelStatusCode.contains(statusCode) ? forageLogger.warn : forageLogger.error
            logLevel(message, error, nil)
        } else {
            ForageSDK.logger?.error(message, error: error, attributes: nil)
        }

        responseMonitor?.end()
        responseMonitor?.logResult()
    }
}
