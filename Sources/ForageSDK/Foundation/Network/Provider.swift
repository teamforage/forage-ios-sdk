//
//  Provider.swift
//  ForageSDK
//
//  Created by Symphony on 23/10/22.
//

import Foundation

internal class Provider {
    var urlSession: URLSessionProtocol!
    var task: URLSessionDataTask?
    
    init(_ urlSession: URLSessionProtocol = URLSession.shared) {
        self.urlSession = urlSession
    }
    
    internal func execute<T: Decodable>(model: T.Type, endpoint: ServiceProtocol, completion: @escaping (Result<T, Error>) -> Void) throws {
        do {
            let request = try endpoint.urlRequest()
            task = urlSession.dataTask(with: request) { (data, response, error) in
                DispatchQueue.main.async {
                    self.middleware(model: model, data: data, response: response, error: error) { (result) in
                        switch result {
                        case .success(let data):
                            completion(.success(data))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                }
            }
            task?.resume()
        } catch {
            throw error
        }
    }
    
    internal func execute(endpoint: ServiceProtocol, completion: @escaping (Result<Data?, Error>) -> Void) throws {
        do {
            let request = try endpoint.urlRequest()
            task = urlSession.dataTask(with: request) { (data, response, error) in
                self.processResponse(response: response) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success:
                            completion(.success(data))
                        case .failure:
                            if let data = data {
                                self.processVGSData(
                                    model: ForageServiceError.self,
                                    code: nil,
                                    data: data,
                                    response: response) { errorResult in
                                    switch errorResult {
                                    case .success(let errorParsed):
                                        return completion(.failure(errorParsed))
                                    case .failure(let error):
                                        return completion(.failure(error))
                                    }
                                }
                            } else if let error = error {
                                return completion(.failure(error))
                            } else {
                                return completion(.failure(ServiceError.emptyError))
                            }
                        }
                    }
                }
            }
            task?.resume()
        } catch {
            throw error
        }
    }
    
    internal func stopRequestOnGoing() {
        if let task = task {
            task.cancel()
        }
    }
    
    private func middleware<T: Decodable>(model: T.Type, data: Data?, response: URLResponse?, error: Error?, completion: @escaping (Result<T, Error>) -> Void) {
        
        var httpResponse: HTTPURLResponse?
        
        processResponse(response: response) { (result) in
            switch result {
            case .success(let response):
                httpResponse = response
            case .failure(let error):
                return completion(.failure(error))
            }
        }
        
        processError(error: error, response: httpResponse) { (result) in
            switch result {
            case .success():
                break
            case .failure(let error):
                completion(.failure(error))
            }
        }
        
        processData(model: model, data: data, response: httpResponse, error: error) { (result) in
            switch result {
            case .success(let data):
                return completion(.success(data))
            case .failure(let error):
                return completion(.failure(error))
            }
        }
    }
    
    private func processResponse(response: URLResponse?, completion: @escaping (Result<HTTPURLResponse, Error>) -> Void) {
        guard let httpResponse = response as? HTTPURLResponse else {
            return completion(.failure(NSError(domain: "Invalid response", code: -999, userInfo: nil)))
        }
        
        guard 200 ... 299 ~= httpResponse.statusCode else {
            return completion(.failure(NSError(domain: "Error", code: httpResponse.statusCode, userInfo: nil)))
        }
        
        completion(.success(httpResponse))
    }
    
    private func processError(error: Error?, response: HTTPURLResponse?, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let error = error else {
            return completion(.success(()))
        }
        
        completion(.failure(NSError(domain: "Error: \(error)", code: response?.statusCode ?? -992, userInfo: nil)))
    }
    
    private func processData<T: Decodable>(model: T.Type, data: Data?, response: HTTPURLResponse?, error: Error?, completion: @escaping (Result<T, Error>) -> Void) {
        
        guard let data = data else {
            return completion(.failure(NSError(domain: "Invalid data", code: response?.statusCode ?? -991, userInfo: nil)))
        }
        
        guard let result = try? JSONDecoder().decode(T.self, from: data) else {
            return completion(.failure(NSError(domain: "Could not decode payload - \(String(decoding: data, as: UTF8.self))", code: response?.statusCode ?? 201, userInfo: nil)))
        }
        
        return completion(.success(result))
    }
    
    internal func processVGSData<T: Decodable>(model: T.Type, code: Int?, data: Data?, response: URLResponse?, completion: @escaping (Result<T, Error>) -> Void) {
        
        guard let data = data else {
            return completion(.failure(NSError(domain: "Invalid data", code: code ?? -991, userInfo: nil)))
        }
        
        guard let result = try? JSONDecoder().decode(T.self, from: data) else {
            return completion(.failure(NSError(domain: "Could not decode payload - \(String(decoding: data, as: UTF8.self))", code: code ?? 201, userInfo: nil)))
        }
        
        return completion(.success(result))
    }
}
