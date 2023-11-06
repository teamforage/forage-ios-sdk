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
    /// Tokenize a given EBT Card
    ///
    /// - Parameters:
    ///  - foragePanTextField: A text field capturing the PAN (Primary Account Number) of the EBT card.
    ///  - customerID: A unique ID for the end customer making the payment. We recommend that you hash this value.
    ///  - completion: The closure returns a `Result` containing either a `PaymentMethodModel` or an `Error`. [Read more](https://docs.joinforage.app/reference/create-payment-method)
    func tokenizeEBTCard(
        foragePanTextField: ForagePANTextField,
        customerID: String,
        reusable: Bool?,
        completion: @escaping (Result<PaymentMethodModel, Error>) -> Void
    )

    /// Check balance for a given EBT Card
    ///
    /// - Parameters:
    ///  - foragePinTextField: A specialized text field for securely capturing the PIN to check the balance of the EBT card.
    ///  - paymentMethodReference: PaymentMethod's unique reference hash
    ///  - completion: The closure returns a `Result` containing either a `BalanceModel` or an `Error`.
    func checkBalance(
        foragePinTextField: ForagePINTextField,
        paymentMethodReference: String,
        completion: @escaping (Result<BalanceModel, Error>) -> Void
    )

    /// Capture a payment for a given payment reference
    ///
    /// - Parameters:
    ///  - foragePinTextField: A specialized text field  for securely capturing the PIN to capture the EBT payment.
    ///  - paymentReference: The reference hash of the Payment
    ///  - completion: The closure returns a `Result` containing either a `PaymentModel` or an `Error`. [Read more](https://docs.joinforage.app/reference/capture-payment)
    func capturePayment(
        foragePinTextField: ForagePINTextField,
        paymentReference: String,
        completion: @escaping (Result<PaymentModel, Error>) -> Void
    )
}

extension ForageSDK: ForageSDKService {
    public func tokenizeEBTCard(
        foragePanTextField: ForagePANTextField,
        customerID: String,
        reusable: Bool? = true,
        completion: @escaping (Result<PaymentMethodModel, Error>) -> Void
    ) {
        _ = logger?
            .setPrefix("tokenizeEBTCard")
            .addContext(ForageLogContext(
                customerID: customerID,
                merchantRef: merchantID
            ))
            .notice("Called ForageSDK.shared.tokenizeEBTCard", attributes: nil)

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
        _ = logger?
            .setPrefix("checkBalance")
            .addContext(ForageLogContext(
                merchantRef: merchantID,
                paymentMethodRef: paymentMethodReference
            ))
            .notice("Called ForageSDK.shared.checkBalance for Payment Method \(paymentMethodReference)", attributes: nil)

        guard let forageService = service else {
            reportIllegalState(for: "checkBalance", dueTo: "ForageService was not initialized")
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
            vaultType: pinCollector.getVaultType(),
            vaultAction: VaultAction.balanceCheck
        )
        responseMonitor.start()
        // ------------------------------------------------------

        Task.init {
            do {
                let balanceResult = try await forageService.checkBalance(
                    pinCollector: pinCollector,
                    paymentMethodReference: paymentMethodReference
                )
                self.logger?.notice("Balance check succeeded for PaymentMethod \(paymentMethodReference)", attributes: nil)

                responseMonitor.setEventOutcome(.success).end()
                responseMonitor.logResult()

                completion(.success(balanceResult))
            } catch {
                self.logger?.error("Balance check failed for PaymentMethod \(paymentMethodReference)", error: error, attributes: nil)

                responseMonitor.setForageErrorCode(error).end()
                responseMonitor.logResult()

                completion(.failure(error))
            }
        }
    }

    public func capturePayment(
        foragePinTextField: ForagePINTextField,
        paymentReference: String,
        completion: @escaping (Result<PaymentModel, Error>) -> Void
    ) {
        _ = logger?
            .setPrefix("capturePayment")
            .addContext(ForageLogContext(
                merchantRef: merchantID,
                paymentRef: paymentReference
            ))
            .notice("Called ForageSDK.shared.capturePayment for Payment \(paymentReference)", attributes: nil)

        guard let forageService = service else {
            reportIllegalState(for: "capturePayment", dueTo: "ForageService was not initialized")
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
            vaultType: pinCollector.getVaultType(),
            vaultAction: VaultAction.capturePayment
        )
        responseMonitor.start()
        // ------------------------------------------------------

        Task.init {
            do {
                let paymentResult = try await forageService.capturePayment(
                    pinCollector: pinCollector,
                    paymentReference: paymentReference
                )
                self.logger?.notice("Capture succeeded for Payment \(paymentReference)", attributes: nil)

                responseMonitor.setEventOutcome(.success).end()
                responseMonitor.logResult()

                completion(.success(paymentResult))
            } catch {
                self.logger?.error("Capture failed for Payment \(paymentReference)", error: error, attributes: nil)

                responseMonitor.setForageErrorCode(error).end()
                responseMonitor.logResult()

                completion(.failure(error))
            }
        }
    }

    /// Reports an illegal state by logging a critical error and triggering an assertion failure.
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
        logger?.critical(assertionMessage, error: nil, attributes: nil)
        assertionFailure(assertionMessage)
    }

    /// Validates the completeness of the PIN entered in the specified text field.
    /// - Returns: `true` if the PIN comprises 4 digits and is ready for submission; otherwise, logs a warning and returns `false`.
    private func validatePin(foragePinTextField: ForagePINTextField) -> Bool {
        if foragePinTextField.isComplete {
            return true
        }
        logger?.warn(
            "User attempted to submit an incomplete PIN",
            error: CommonErrors.INCOMPLETE_PIN_ERROR,
            attributes: nil
        )
        return false
    }
}
