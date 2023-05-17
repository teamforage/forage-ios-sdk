//
//  Address.swift
//  SampleForageSDK
//
//  Created by Symphony on 26/10/22.
//

import Foundation

public struct Address: Codable {
    let city: String
    let country: String
    let line1: String?
    let line2: String?
    let zipcode: String
    let state: String
}
