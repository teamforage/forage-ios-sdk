//
//  SampleAPI.swift
//  SampleForageSDK
//
//  Created by Tiago Oliveira on 26/10/22.
//  Copyright © 2022-Present Forage Technology Corporation. All rights reserved.
//

import ForageSDK
import Foundation

enum SampleAPI {
    case createPayment(request: CreatePaymentRequest)
}

extension SampleAPI: ServiceProtocol {
    var scheme: String { return "https" }

    var host: String { return ForageSDK.shared.environment.hostname }

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
                "is_delivery": model.isDelivery,
                "customer_id": model.customerID,
            ]

            let httpHeaders: HTTPHeaders = [
                "Merchant-Account": model.merchantID,
                "IDEMPOTENCY-KEY": UUID.init().uuidString,
                "authorization": "Bearer \(ClientSharedData.shared.sessionToken)",
                "API-VERSION": "2023-05-15",
            ]

            return .requestParametersAndHeaders(
                bodyParameters: bodyParameters,
                urlParameters: nil,
                additionalHeaders: httpHeaders
            )
        }
    }
}
