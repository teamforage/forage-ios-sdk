//
//  ForageService.swift
//  ForageSDK
//
//  Created by Tiago Oliveira on 21/11/22.
//  Copyright © 2022-Present Forage Technology Corporation. All rights reserved.
//

import Foundation
import VGSCollectSDK

/**
 Interface for internal Forage SDK requests
 */
protocol ForageService: AnyObject {
    /// Provider provides the interface for performing HTTP requests.
    var provider: Provider { get }

    /// Retrieves the EncryptionKey from the Forage API, to be utilized as the X-Key header.
    ///
    /// - Parameters:
    ///  - sessionToken: Short-lived session token that authorizes requests to the Forage API.
    ///  - merchantID: The unique ID of the Merchant.
    ///  - completion: The closure returns a `Result` containing either a `ForageXKeyModel` or an `Error`.
    func getXKey(
        sessionToken: String,
        merchantID: String,
        completion: @escaping (Result<ForageXKeyModel, Error>) -> Void
    )

    /// Perform a GET request for the PaymentMethod
    ///
    /// - Parameters:
    ///  - sessionToken: Short-lived session token that authorizes requests to the Forage API.
    ///  - merchantID: The unique ID of the Merchant.
    ///  - paymentMethodRef: The reference hash of the PaymentMethod.
    ///  - completion: The closure returns a `Result` containing either a `PaymentMethodModel` or an `Error`. [Read more](https://docs.joinforage.app/reference/get-payment-method)
    func getPaymentMethod(
        sessionToken: String,
        merchantID: String,
        paymentMethodRef: String,
        completion: @escaping (Result<PaymentMethodModel, Error>) -> Void
    )

    /// Performs a GET request to retrieve the specified Payment.
    ///
    /// - Parameters:
    ///  - sessionToken: Short-lived session token that authorizes requests to the Forage API.
    ///  - merchantID: The unique ID of the Merchant.
    ///  - paymentRef: The reference hash of the Payment.
    ///  - completion: The closure returns a `Result` containing either a `PaymentModel` or an `Error`. [Read more](https://docs.joinforage.app/reference/get-payment-details)
    func getPayment(
        sessionToken: String,
        merchantID: String,
        paymentRef: String,
        completion: @escaping (Result<PaymentModel, Error>) -> Void
    )

    /// Tokenize an EBT card using the given *ForagePANRequestModel* object
    ///
    /// - Parameters:
    ///  - request: An instance of `ForagePANRequestModel` containing the EBT card details.
    ///  - completion: The closure returns a `Result` containing either a `PaymentMethodModel` or an `Error`. [Read more](https://docs.joinforage.app/reference/create-payment-method)
    func tokenizeEBTCard(
        request: ForagePANRequestModel,
        completion: @escaping (Result<PaymentMethodModel, Error>) -> Void
    )

    /// Asynchronously checks the balance of a PaymentMethod using the given `pinCollector` and `paymentMethodReference`
    ///
    /// - Parameters:
    ///   - pinCollector: The service responsible for securely collecting PINs.
    ///   - paymentMethodReference: The reference hash of the PaymentMethod.
    ///
    /// - Throws:
    ///   - `ForageError`: If there's an issue at any stage of the balance check process.
    ///
    /// - Returns:
    ///   - A `BalanceModel` object containing the balance of the PaymentMethod.
    func checkBalance(
        pinCollector: VaultCollector,
        paymentMethodReference: String
    ) async throws -> BalanceModel

    /// Immediately captures a payment using the given `pinCollector` and `paymentReference`
    ///
    /// - Parameters:
    ///   - pinCollector: The service responsible for securely collecting PINs.
    ///   - paymentReference: The reference hash of the Payment that is being captured.
    ///
    /// - Throws:
    ///   - `ForageError`: If there's an issue at any stage of the payment capture process.
    ///
    /// - Returns:
    ///   - A `PaymentModel` object containing the details of the captured payment.
    func capturePayment(
        pinCollector: VaultCollector,
        paymentReference: String
    ) async throws -> PaymentModel

    /// Collect the customer's PIN for a payment using the given `pinCollector` and `paymentReference`
    ///
    /// - Parameters:
    ///   - pinCollector: The service responsible for securely collecting PINs.
    ///   - paymentReference: The reference hash of the Payment that the client intends on capturing from their server.
    ///
    /// - Throws:
    ///   - `ForageError`: If there's an issue at any stage of the payment capture process.
    ///
    /// - Returns:
    ///   - A `VaultResponse` object containing the response from the Vault (VGS or Basis Theory) proxy.
    func collectPinForDeferredCapture(
        pinCollector: VaultCollector,
        paymentReference: String
    ) async throws -> VaultResponse
}
