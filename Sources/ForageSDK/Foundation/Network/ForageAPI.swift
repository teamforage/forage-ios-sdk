//
//  ForageAPI.swift
//  ForageSDK
//
//  Created by Tiago Oliveira on 24/10/22.
//  Copyright © 2022-Present Forage Technology Corporation. All rights reserved.
//

import Foundation

/**
 Map the endpoints used on ForageSDK
 */
enum ForageAPI {
    case tokenizeNumber(request: ForagePANRequestModel)
    case getPaymentMethod(sessionToken: String, merchantID: String, paymentMethodRef: String)
    case getPayment(sessionToken: String, merchantID: String, paymentRef: String)
}

extension ForageAPI: ServiceProtocol {
    var scheme: String { "https" }

    var host: String { ForageSDK.shared.environment.hostname }

    var path: String {
        switch self {
        case .tokenizeNumber: return "/api/payment_methods/"
        case let .getPaymentMethod(request: request): return "/api/payment_methods/\(request.paymentMethodRef)/"
        case let .getPayment(request: request): return "/api/payments/\(request.paymentRef)/"
        }
    }

    var method: HttpMethod {
        switch self {
        case .tokenizeNumber: return .post
        case .getPaymentMethod, .getPayment: return .get
        }
    }

    var task: HttpTask {
        let headers = HTTPHeaders([
            "content-type": "application/json",
            "accept": "application/json",
            "x-datadog-trace-id": ForageSDK.shared.traceId,
            "API-VERSION": "default",
        ])
        switch self {
        case let .tokenizeNumber(
            request: model
        ):
            var card = [String: String]()
            card["number"] = model.panNumber

            let bodyParameters: Parameters = [
                "type": model.type,
                "reusable": model.reusable ?? true,
                "card": card,
                "customer_id": model.customerID,
            ]

            headers.addHeaders([
                "Merchant-Account": model.merchantID,
                "authorization": "Bearer \(model.authorization)",
                "API-VERSION": "2023-05-15",
            ])

            return .requestParametersAndHeaders(
                bodyParameters: bodyParameters,
                urlParameters: nil,
                additionalHeaders: headers
            )

        case let .getPaymentMethod(request: request):
            headers.addHeaders([
                "Merchant-Account": request.merchantID,
                "authorization": "Bearer \(request.sessionToken)",
                "API-VERSION": "2023-05-15",
            ])

            return .requestParametersAndHeaders(
                bodyParameters: nil,
                urlParameters: nil,
                additionalHeaders: headers
            )

        case let .getPayment(request: request):
            headers.addHeaders([
                "Merchant-Account": request.merchantID,
                "authorization": "Bearer \(request.sessionToken)",
                "API-VERSION": "2023-05-15",
            ])

            return .requestParametersAndHeaders(
                bodyParameters: nil,
                urlParameters: nil,
                additionalHeaders: headers
            )
        }
    }
}
