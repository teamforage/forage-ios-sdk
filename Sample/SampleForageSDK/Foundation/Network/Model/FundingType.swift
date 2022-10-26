//
//  FundingType.swift
//  SampleForageSDK
//
//  Created by Symphony on 26/10/22.
//

import Foundation

enum FundingType: String, Codable {
    case ebtSnap
    case ebtCash
    
    private enum CodingKeys : String, CodingKey {
        case ebtSnap = "ebt_snap"
        case ebtCash = "ebt_cash"
    }
}
