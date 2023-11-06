//
//  VaultResponse.swift
//
//
//  Created by Shardendu Gautam on 6/13/23.
//  Copyright © 2023-Present Forage Technology Corporation. All rights reserved.
//

import Foundation

public struct VaultResponse {
    var statusCode: Int?
    var urlResponse: URLResponse?
    var data: Data?
    var error: Error?
}
