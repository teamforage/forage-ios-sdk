//
//  SampleAPI.swift
//  SampleForageSDK
//
//  Created by Symphony on 26/10/22.
//

import Foundation

enum SampleAPI {
    case createPayment(request: CreatePaymentRequest)
}

extension SampleAPI: ServiceProtocol {
    var scheme: String { return "https" }
    
    var host: String { return "api.sandbox.joinforage.app" }
    
    var path: String { return "/api/payments/" }
    
    var method: HttpMethod { return .post }
    
    var task: HttpTask {
        switch self {
        case .createPayment(request: let model):
            let bodyParameters: Parameters = [
                "amount": model.amount,
                "funding_type": model.fundingType,
                "payment_method": model.paymentMethodIdentifier,
                "description": model.description,
                "metadata": model.metadata,
                "delivery_address": [
                    "city": model.deliveryAddress.city,
                    "country": model.deliveryAddress.country,
                    "line1": model.deliveryAddress.line1,
                    "line2": model.deliveryAddress.line2,
                    "zipcode": model.deliveryAddress.zipcode,
                    "state": model.deliveryAddress.state,
                ],
                "is_delivery": model.isDelivery
            ]
            
            let httpHeaders: HTTPHeaders = [
                "Merchant-Account": model.merchantAccount,
                "IDEMPOTENCY-KEY": model.paymentMethodIdentifier
            ]
            
            return .requestParametersAndHeaders(
                bodyParameters: bodyParameters,
                urlParameters: nil,
                additionalHeaders: httpHeaders
            )
        }
    }
}
