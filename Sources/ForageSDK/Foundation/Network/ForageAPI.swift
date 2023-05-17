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
    case xKey(bearerToken: String, merchantAccount: String)
    case message(request: MessageResponseModel, bearerToken: String, merchantID: String)
    case getPaymentMethod(bearerToken: String, merchantAccount: String, paymentMethodRef: String)
    case getPayment(bearerToken: String, merchantAccount: String, paymentRef: String)
}

extension ForageAPI: ServiceProtocol {
    var scheme: String { return "https" }
    
    var host: String { return ForageSDK.shared.environment.rawValue }
    
    var path: String {
        switch self {
        case .tokenizeNumber: return "/api/payment_methods/"
        case .xKey: return "/iso_server/encryption_alias/"
        case .message(request: let response, _, _): return "/api/message/\(response.contentId)/"
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
                "reusable": model.reusable,
                "card": card,
                "customer_id": model.customerID
            ]

            let httpHeaders: HTTPHeaders = [
                "Merchant-Account": model.merchantAccount,
                "authorization": "Bearer \(model.authorization)",
                "content-type": "application/json",
                "accept": "application/json",
                "API-VERSION": "2023-03-31"
            ]
            
            return .requestParametersAndHeaders(
                bodyParameters: bodyParameters,
                urlParameters: nil,
                additionalHeaders: httpHeaders
            )
            
        case .xKey(bearerToken: let bearerToken, merchantAccount: let merchantAccount):
            let httpHeaders: HTTPHeaders = [
                "authorization": "Bearer \(bearerToken)",
                "accept": "application/json",
                "Merchant-Account": merchantAccount,
            ]
            
            return .requestParametersAndHeaders(
                bodyParameters: nil,
                urlParameters: nil,
                additionalHeaders: httpHeaders
            )
            
        case .message(_, bearerToken: let bearerToken, merchantID: let merchantID):
            let httpHeaders: HTTPHeaders = [
                "Merchant-Account": merchantID,
                "authorization": "Bearer \(bearerToken)",
                "accept": "application/json",
                "API-VERSION": "2023-02-01"
            ]
            
            return .requestParametersAndHeaders(
                bodyParameters: nil,
                urlParameters: nil,
                additionalHeaders: httpHeaders
            )
            
        case .getPaymentMethod(request: let request):
            let httpHeaders: HTTPHeaders = [
                "Merchant-Account": request.merchantAccount,
                "authorization": "Bearer \(request.bearerToken)",
                "API-VERSION": "2023-03-31"
            ]
            
            return .requestParametersAndHeaders(
                bodyParameters: nil,
                urlParameters: nil,
                additionalHeaders: httpHeaders
            )
            
        case .getPayment(request: let request):
            let httpHeaders: HTTPHeaders = [
                "Merchant-Account": request.merchantAccount,
                "authorization": "Bearer \(request.bearerToken)",
                "API-VERSION": "2023-03-31"
            ]
            
            return .requestParametersAndHeaders(
                bodyParameters: nil,
                urlParameters: nil,
                additionalHeaders: httpHeaders
            )
        }
    }
}
