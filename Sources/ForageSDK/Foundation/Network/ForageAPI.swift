//
//  ForageAPI.swift
//  ForageSDK
//
//  Created by Symphony on 24/10/22.
//

import Foundation

enum ForageAPI {
    case panNumber(request: ForagePANRequest)
    case xKey(bearerToken: String)
}

extension ForageAPI: ServiceProtocol {
    var scheme: String { return "https" }
    
    var host: String { return ForageSDK.shared.environment.rawValue }
    
    var path: String {
        switch self {
        case .panNumber: return "/api/payment_methods/"
        case .xKey: return "/iso_server/encryption_alias/"
        }
    }
    
    var method: HttpMethod {
        switch self {
        case .panNumber: return .post
        case .xKey: return .get
        }
    }
    
    var task: HttpTask {
        switch self {
        case .panNumber(
            request: let model
        ):
            var card = [String: String]()
            card["number"] = model.panNumber
            
            let bodyParameters: Parameters = [
                "type": model.type,
                "reusable": model.reusable,
                "card": card
            ]

            let httpHeaders: HTTPHeaders = [
                "Merchant-Account": model.merchantAccount,
                "authorization": "Bearer \(model.authorization)",
                "content-type": "application/json",
                "accept": "application/json"
            ]
            
            return .requestParametersAndHeaders(
                bodyParameters: bodyParameters,
                urlParameters: nil,
                additionalHeaders: httpHeaders
            )
        case .xKey(bearerToken: let bearerToken):
            let httpHeaders: HTTPHeaders = [
                "authorization": "Bearer \(bearerToken)",
                "accept": "application/json"
            ]
            
            return .requestParametersAndHeaders(
                bodyParameters: nil,
                urlParameters: nil,
                additionalHeaders: httpHeaders
            )
        }
    }
}
