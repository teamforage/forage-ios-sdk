//
//  MockURLSession.swift
//
//
//  Created by Evan Freeze on 6/12/24.
//  Copyright © 2024-Present Forage Technology Corporation. All rights reserved.
//

import Foundation

class MockURLSession: URLSession {
    var lastURL: URL?
    var lastRequest: URLRequest?
    var dataTaskResponse: (data: Data?, response: URLResponse?, error: Error?)
    
    override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        self.lastURL = url
        return MockURLSessionDataTask {
            completionHandler(self.dataTaskResponse.data, self.dataTaskResponse.response, self.dataTaskResponse.error)
        }
    }
    
    override func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        self.lastRequest = request
        return MockURLSessionDataTask {
            completionHandler(self.dataTaskResponse.data, self.dataTaskResponse.response, self.dataTaskResponse.error)
        }
    }
}

class MockURLSessionDataTask: URLSessionDataTask {
    private let completionHandler: () -> Void
    
    init(completionHandler: @escaping () -> Void) {
        self.completionHandler = completionHandler
    }
    
    override func resume() {
        completionHandler()
    }
}

