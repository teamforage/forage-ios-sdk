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
    case xKey(sessionToken: String, merchantID: String)
    case message(contentId: String, sessionToken: String, merchantID: String)
    case getPaymentMethod(sessionToken: String, merchantID: String, paymentMethodRef: String)
    case getPayment(sessionToken: String, merchantID: String, paymentRef: String)
}

extension ForageAPI: ServiceProtocol {
    var scheme: String { return "https" }

    var host: String { return ForageSDK.shared.environment.hostname }

    var path: String {
        switch self {
        case .tokenizeNumber: return "/api/payment_methods/"
        case .xKey: return "/iso_server/encryption_alias/"
        case .message(contentId: let contentId, _, _): return "/api/message/\(contentId)/"
        case .getPaymentMethod(request: let request): return "/api/payment_methods/\(request.paymentMethodRef)/"
        case .getPayment(request: let request): return "/api/payments/\(request.paymentRef)/"
        }
    }

    var method: HttpMethod {
        switch self {
        case .tokenizeNumber: return .post
        case .xKey, .message, .getPaymentMethod, .getPayment: return .get
        }
    }

    var task: HttpTask {
        let headers = HTTPHeaders([
            "content-type": "application/json",
            "accept": "application/json",
            "x-datadog-trace-id": ForageSDK.shared.traceId
        ])
        switch self {
        case .tokenizeNumber(
            request: let model
        ):
            var card = [String: String]()
            card["number"] = model.panNumber

            let bodyParameters: Parameters = [
                "type": model.type,
                "reusable": model.reusable ?? true,
                "card": card,
                "customer_id": model.customerID
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

        case .xKey(sessionToken: let sessionToken, merchantID: let merchantID):
            headers.addHeaders([
                "authorization": "Bearer \(sessionToken)",
                "accept": "application/json",
                "Merchant-Account": merchantID,
            ])

            return .requestParametersAndHeaders(
                bodyParameters: nil,
                urlParameters: nil,
                additionalHeaders: headers
            )

        case .message(_, sessionToken: let sessionToken, merchantID: let merchantID):
            headers.addHeaders([
                "Merchant-Account": merchantID,
                "authorization": "Bearer \(sessionToken)",
                "API-VERSION": "2023-02-01",
            ])

            return .requestParametersAndHeaders(
                bodyParameters: nil,
                urlParameters: nil,
                additionalHeaders: headers
            )

        case .getPaymentMethod(request: let request):
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

        case .getPayment(request: let request):
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
