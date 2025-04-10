//
//  Address.swift
//  SampleForageSDK
//
//  Created by Tiago Oliveira on 26/10/22.
//  © 2022-2025 Forage Technology Corporation. All rights reserved.
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
