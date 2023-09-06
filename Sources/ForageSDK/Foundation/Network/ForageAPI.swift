//
//  ForageAPI.swift
//  ForageSDK
//
//  Created by Symphony on 24/10/22.
//

import Foundation

/**
 Map the endpoints used on ForageSDK
 */
enum ForageAPI {
    case tokenizeNumber(request: ForagePANRequestModel)
    case xKey(sessionToken: String, merchantID: String, traceId: String)
    case message(request: MessageResponseModel, sessionToken: String, merchantID: String, traceId: String)
    case getPaymentMethod(sessionToken: String, merchantID: String, paymentMethodRef: String, traceId: String)
    case getPayment(sessionToken: String, merchantID: String, paymentRef: String, traceId: String)
}

extension ForageAPI: ServiceProtocol {
    var scheme: String { return "https" }

    var host: String { return ForageSDK.shared.environment.hostname }

    var path: String {
        switch self {
        case .tokenizeNumber: return "/api/payment_methods/"
        case .xKey: return "/iso_server/encryption_alias/"
        case .message(request: let response, _, _, _): return "/api/message/\(response.contentId)/"
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

            let httpHeaders: HTTPHeaders = [
                "Merchant-Account": model.merchantID,
                "authorization": "Bearer \(model.authorization)",
                "content-type": "application/json",
                "accept": "application/json",
                "API-VERSION": "2023-05-15",
                "x-datadog-trace-id": model.traceId ?? ""
            ]

            return .requestParametersAndHeaders(
                bodyParameters: bodyParameters,
                urlParameters: nil,
                additionalHeaders: httpHeaders
            )

        case .xKey(sessionToken: let sessionToken, merchantID: let merchantID, traceId: let traceId):
            let httpHeaders: HTTPHeaders = [
                "authorization": "Bearer \(sessionToken)",
                "accept": "application/json",
                "Merchant-Account": merchantID,
                "x-datadog-trace-id": traceId
            ]

            return .requestParametersAndHeaders(
                bodyParameters: nil,
                urlParameters: nil,
                additionalHeaders: httpHeaders
            )

        case .message(_, sessionToken: let sessionToken, merchantID: let merchantID, traceId: let traceId):
            let httpHeaders: HTTPHeaders = [
                "Merchant-Account": merchantID,
                "authorization": "Bearer \(sessionToken)",
                "accept": "application/json",
                "API-VERSION": "2023-02-01",
                "x-datadog-trace-id": traceId
            ]

            return .requestParametersAndHeaders(
                bodyParameters: nil,
                urlParameters: nil,
                additionalHeaders: httpHeaders
            )

        case .getPaymentMethod(request: let request):
            let httpHeaders: HTTPHeaders = [
                "Merchant-Account": request.merchantID,
                "authorization": "Bearer \(request.sessionToken)",
                "API-VERSION": "2023-05-15",
                "x-datadog-trace-id": request.traceId
            ]

            return .requestParametersAndHeaders(
                bodyParameters: nil,
                urlParameters: nil,
                additionalHeaders: httpHeaders
            )

        case .getPayment(request: let request):
            let httpHeaders: HTTPHeaders = [
                "Merchant-Account": request.merchantID,
                "authorization": "Bearer \(request.sessionToken)",
                "API-VERSION": "2023-05-15",
                "x-datadog-trace-id": request.traceId
            ]

            return .requestParametersAndHeaders(
                bodyParameters: nil,
                urlParameters: nil,
                additionalHeaders: httpHeaders
            )
        }
    }
}
