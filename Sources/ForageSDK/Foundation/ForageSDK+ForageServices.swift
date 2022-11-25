//
//  ForageSDK+ForageServices.swift
//  ForageSDK
//
//  Created by Symphony on 22/11/22.
//
import VGSCollectSDK
import Foundation

/**
 Card type
 */
private enum CardType: String {
    case ebt = "ebt"
}

/**
 Interface for Forage SDK Services
 */
protocol ForageSDKService: AnyObject {
    /// Tokenize a given EBT Card
    ///
    /// - Parameters:
    ///  - bearerToken: Authorization token.
    ///  - merchantAccount: Merchant account identifier, `merchant id`.
    ///  - completion: Which will return the result. (See more [here](https://docs.joinforage.app/reference/create-payment-method-1))
    func tokenizeEBTCard(
        bearerToken: String,
        merchantAccount: String,
        completion: @escaping (Result<Data?, Error>) -> Void)

    /// Check balance for a given EBT Card
    ///
    /// - Parameters:
    ///  - bearerToken: Authorization token.
    ///  - merchantAccount: Merchant account identifier, `merchant id`.
    ///  - paymentMethodReference: PaymentMethod's unique reference hash
    ///  - cardNumberToken: The token field of the ``TokenizedPaymentMethod.card`` object
    ///  - completion: Which will return the result. (See more [here](https://docs.joinforage.app/reference/check-balance))
    func checkBalance(
        bearerToken: String,
        merchantAccount: String,
        paymentMethodReference: String,
        cardNumberToken: String,
        completion: @escaping (Result<Data?, Error>) -> Void)

    /// Capture a payment for a given payment reference
    ///
    /// - Parameters:
    ///  - bearerToken: Authorization token.
    ///  - merchantAccount: Merchant account identifier, `merchant id`.
    ///  - paymentReference: The reference hash of the payment
    ///  - cardNumberToken: The token field of the ``TokenizedPaymentMethod.card`` object
    ///  - completion: Which will return the result. (See more [here](https://docs.joinforage.app/reference/capture-payment))
    func capturePayment(
        bearerToken: String,
        merchantAccount: String,
        paymentReference: String,
        cardNumberToken: String,
        completion: @escaping (Result<Data?, Error>) -> Void)

    /// Cancel any ongoing request
    func cancelRequest()
}

// MARK: - ForageSDKService
extension ForageSDK: ForageSDKService {

    // MARK: Private Methods
    
    private func getXKey(
        _ bearerToken: String,
        completion: @escaping (Result<ForageXKeyModel, Error>) -> Void)
    -> Void {
        service?.getXKey(bearerToken: bearerToken) { result in
            completion(result)
        }
    }

    // MARK: Public Methods
    
    public func tokenizeEBTCard(
        bearerToken: String,
        merchantAccount: String,
        completion: @escaping (Result<Data?, Error>) -> Void) {
        let request = ForagePANRequestModel(
            authorization: bearerToken,
            merchantAccount: merchantAccount,
            panNumber: panNumber,
            type: CardType.ebt.rawValue,
            reusable: true
        )
        service?.tokenizeEBTCard(request: request, completion: completion)
    }

    public func checkBalance(
        bearerToken: String,
        merchantAccount: String,
        paymentMethodReference: String,
        cardNumberToken: String,
        completion: @escaping (Result<Data?, Error>) -> Void) {
        service?.getXKey(bearerToken: bearerToken) { result in
            switch result {
            case .success(let model):
                let request = ForageRequestModel(
                    authorization: bearerToken,
                    paymentMethodReference: paymentMethodReference,
                    paymentReference: "",
                    cardNumberToken: cardNumberToken,
                    merchantID: merchantAccount,
                    xKey: model.alias
                )
                self.service?.getBalance(request: request, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    public func capturePayment(
        bearerToken: String,
        merchantAccount: String,
        paymentReference: String,
        cardNumberToken: String,
        completion: @escaping (Result<Data?, Error>) -> Void) {
        service?.getXKey(bearerToken: bearerToken) { result in
            switch result {
            case .success(let model):
                let request = ForageRequestModel(
                    authorization: bearerToken,
                    paymentMethodReference: "",
                    paymentReference: paymentReference,
                    cardNumberToken: cardNumberToken,
                    merchantID: merchantAccount,
                    xKey: model.alias
                )

                self.service?.requestCapturePayment(request: request, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    public func cancelRequest() {
        service?.provider.stopRequestOnGoing()
    }
}
