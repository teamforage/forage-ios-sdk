//
//  PaymentModel.swift
//
//
//  Created by Danny Leiser on 4/27/23.
//  Copyright © 2023-Present Forage Technology Corporation. All rights reserved.
//

import Foundation

public struct ForageAddress: Codable {
    public let city: String
    public let country: String
    public let line1: String?
    public let line2: String?
    public let zipcode: String
    public let state: String
}

public struct ReceiptBalance: Codable {
    public let id: Int
    public let snap: String
    public let cash: String
    public let updated: String

    private enum CodingKeys: String, CodingKey {
        case id
        case cash = "non_snap"
        case snap
        case updated
    }
}

public struct Receipt: Codable {
    public let refNumber: String
    public let isVoided: Bool
    public let snapAmount: String
    public let ebtCashAmount: String
    public let otherAmount: String
    public let salesTaxApplied: String
    public let balance: ReceiptBalance?
    public let last4: String
    public let message: String
    public let transactionType: String
    public let created: String

    private enum CodingKeys: String, CodingKey {
        case refNumber = "ref_number"
        case isVoided = "is_voided"
        case snapAmount = "snap_amount"
        case ebtCashAmount = "ebt_cash_amount"
        case otherAmount = "other_amount"
        case salesTaxApplied = "sales_tax_applied"
        case balance
        case last4 = "last_4"
        case message
        case transactionType = "transaction_type"
        case created
    }
}

/// `PaymentModel` used to represent a [Forage Payment object](https://docs.joinforage.app/reference/create-a-payment)
public struct PaymentModel: Codable {
    public let paymentRef: String
    public let merchantID: String
    public let fundingType: String
    public let amount: String
    public let description: String
    public let metadata: [String: String]
    public let paymentMethodRef: String
    public let deliveryAddress: ForageAddress
    public let isDelivery: Bool
    public let createdDate: String
    public let updatedDate: String
    public let status: String
    public let successDate: String?
    public let lastProcessingError: String?
    public let receipt: Receipt?
    public let platformFee: String?
    public let merchantFixedSettlement: String?
    public let platformFixedSettlement: String?
    public let refunds: [String]
    
    init(from model: RawPaymentResponseModel) {
            self.paymentRef = model.paymentRef
            self.merchantID = model.merchantID
            self.fundingType = model.fundingType
            self.amount = model.amount
            self.description = model.description
            self.metadata = model.metadata
            self.paymentMethodRef = model.paymentMethodRef
            self.deliveryAddress = model.deliveryAddress
            self.isDelivery = model.isDelivery
            self.createdDate = model.createdDate
            self.updatedDate = model.updatedDate
            self.status = model.status
            self.successDate = model.successDate
            self.lastProcessingError = model.lastProcessingError
            self.receipt = model.receipt
            self.platformFee = model.platformFee
            self.merchantFixedSettlement = model.merchantFixedSettlement
            self.platformFixedSettlement = model.platformFixedSettlement
            self.refunds = model.refunds
        }

    private enum CodingKeys: String, CodingKey {
        case paymentRef = "ref"
        case merchantID = "merchant"
        case fundingType = "funding_type"
        case amount
        case description
        case metadata
        case paymentMethodRef = "payment_method"
        case deliveryAddress = "delivery_address"
        case isDelivery = "is_delivery"
        case createdDate = "created"
        case updatedDate = "updated"
        case status
        case lastProcessingError = "last_processing_error"
        case successDate = "success_date"
        case receipt
        case platformFee = "platform_fee"
        case merchantFixedSettlement = "merchant_fixed_settlement"
        case platformFixedSettlement = "platform_fixed_settlement"
        case refunds
    }
}

struct RawPaymentResponseModel: Codable {
    let paymentRef: String
    let merchantID: String
    let fundingType: String
    let amount: String
    let description: String
    let metadata: [String: String]
    let paymentMethodRef: String
    let deliveryAddress: ForageAddress
    let isDelivery: Bool
    let createdDate: String
    let updatedDate: String
    let status: String
    let successDate: String?
    let lastProcessingError: String?
    let receipt: Receipt?
    let platformFee: String?
    let merchantFixedSettlement: String?
    let platformFixedSettlement: String?
    let refunds: [String]
    let error: VaultError?

    private enum CodingKeys: String, CodingKey {
        case paymentRef = "ref"
        case merchantID = "merchant"
        case fundingType = "funding_type"
        case amount
        case description
        case metadata
        case paymentMethodRef = "payment_method"
        case deliveryAddress = "delivery_address"
        case isDelivery = "is_delivery"
        case createdDate = "created"
        case updatedDate = "updated"
        case status
        case lastProcessingError = "last_processing_error"
        case successDate = "success_date"
        case receipt
        case platformFee = "platform_fee"
        case merchantFixedSettlement = "merchant_fixed_settlement"
        case platformFixedSettlement = "platform_fixed_settlement"
        case refunds
        case error
    }
}
