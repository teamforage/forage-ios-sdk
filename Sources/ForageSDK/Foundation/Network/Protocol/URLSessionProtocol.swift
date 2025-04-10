//
//  URLSessionProtocol.swift
//  ForageSDK
//
//  Created by Tiago Oliveira on 29/11/22.
//  © 2022-Present Forage Technology Corporation. All rights reserved.
//

import Foundation

protocol URLSessionProtocol {
    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask
}
