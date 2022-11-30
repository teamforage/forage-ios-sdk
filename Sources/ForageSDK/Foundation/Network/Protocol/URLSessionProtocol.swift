//
//  URLSessionProtocol.swift
//  ForageSDK
//
//  Created by Symphony on 29/11/22.
//

import Foundation

protocol URLSessionProtocol {
    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask
}
