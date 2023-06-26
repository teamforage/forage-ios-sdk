//
//  File.swift
//  
//
//  Created by Shardendu Gautam on 6/13/23.
//

import Foundation

public struct VaultResponse {
    var statusCode: Int?
    var urlResponse: URLResponse?
    var data: Data?
    var error: Error?
}
