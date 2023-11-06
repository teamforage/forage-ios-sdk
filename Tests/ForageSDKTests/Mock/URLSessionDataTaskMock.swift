//
//  URLSessionDataTaskMock.swift
//  ForageSDK
//
//  Created by Tiago Oliveira on 29/11/22.
//  Copyright © 2023-Present Forage Technology Corporation. All rights reserved.
//

@testable import ForageSDK
import Foundation
import XCTest

// Mock URLSession, Mock DataTask
class DataTaskMock: URLSessionDataTask {
    override func resume() {}
}

class URLSessionMock: URLSessionProtocol {
    typealias CompletionHandler = (Data?, URLResponse?, Error?) -> Void
    // data and error can be set to provide data or an error
    var data: Data?
    var error: Error?
    var response: HTTPURLResponse? = nil

    func dataTask(with request: URLRequest, completionHandler: @escaping CompletionHandler) -> URLSessionDataTask {
        defer { completionHandler(data, response, error) }
        return DataTaskMock()
    }
}
