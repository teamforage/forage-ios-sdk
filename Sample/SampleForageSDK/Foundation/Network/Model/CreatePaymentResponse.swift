//
//  CreatePaymentResponse.swift
//  SampleForageSDK
//
//  Created by Tiago Oliveira on 26/10/22.
//  © 2022-2025 Forage Technology Corporation. All rights reserved.
//

import Foundation

struct CreatePaymentResponse: Codable {
    let fundingType: FundingType
    let paymentMethodIdentifier: String
    let paymentIdentifier: String
    let merchantID: String
    let amount: String
    let description: String

    private enum CodingKeys: String, CodingKey {
        case fundingType = "funding_type"
        case paymentMethodIdentifier = "payment_method"
        case paymentIdentifier = "ref"
        case merchantID = "merchant"
        case amount
        case description
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // `ref` is the only field we strictly need (to defer/capture the payment later).
        // Everything else is decoded leniently so an unexpected shape on one field
        // doesn't fail the whole response (e.g. `amount` as a number, or a null `description`).
        paymentIdentifier = try container.decode(String.self, forKey: .paymentIdentifier)
        fundingType = (try? container.decode(FundingType.self, forKey: .fundingType)) ?? .ebtSnap
        paymentMethodIdentifier = (try? container.decode(String.self, forKey: .paymentMethodIdentifier)) ?? ""
        merchantID = (try? container.decode(String.self, forKey: .merchantID)) ?? ""
        description = (try? container.decode(String.self, forKey: .description)) ?? ""

        // `amount` may come back as a String ("1.00") or a JSON number depending on API version.
        if let amountString = try? container.decode(String.self, forKey: .amount) {
            amount = amountString
        } else if let amountNumber = try? container.decode(Double.self, forKey: .amount) {
            amount = String(amountNumber)
        } else {
            amount = ""
        }
    }
}
