//
//  Provider.swift
//  ForageSDK
//
//  Created by Tiago Oliveira on 23/10/22.
//  Copyright © 2022-Present Forage Technology Corporation. All rights reserved.
//

import Foundation

class Provider {
    var urlSession: URLSessionProtocol!
    var task: URLSessionDataTask?
    private var logger: ForageLogger?

    init(_ urlSession: URLSessionProtocol = URLSession.shared, logger: ForageLogger? = nil) {
        self.urlSession = urlSession
        self.logger = logger
    }

    func execute<T: Decodable>(model: T.Type, endpoint: ServiceProtocol, completion: @escaping (Result<T, Error>) -> Void) throws {
        do {
            logger?
                .setPrefix("HTTP")
                .info("Sending \(endpoint.method.rawValue.uppercased()) request to \(endpoint.host)\(endpoint.path)",
                      attributes: [
                          "endpoint": endpoint.path
                      ])
            let request = try endpoint.urlRequest()
            task = urlSession.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    self.middleware(model: model, data: data, response: response, error: error) { result in
                        switch result {
                        case let .success(data):
                            completion(.success(data))
                        case let .failure(error):
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

    func execute(endpoint: ServiceProtocol, completion: @escaping (Result<Data?, Error>) -> Void) throws {
        do {
            let request = try endpoint.urlRequest()
            task = urlSession.dataTask(with: request) { data, response, error in
                self.processResponse(response: response) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success:
                            completion(.success(data))
                        case .failure:
                            if let data = data {
                                self.processVaultData(
                                    model: ForageServiceError.self,
                                    code: nil,
                                    data: data,
                                    response: response
                                ) { errorResult in
                                    switch errorResult {
                                    case let .success(errorParsed):
                                        return completion(.failure(errorParsed))
                                    case let .failure(error):
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

    func stopRequestOnGoing() {
        if let task = task {
            task.cancel()
        }
    }

    private func middleware<T: Decodable>(model: T.Type, data: Data?, response: URLResponse?, error: Error?, completion: @escaping (Result<T, Error>) -> Void) {
        var httpResponse: HTTPURLResponse?

        processResponse(response: response) { result in
            switch result {
            case let .success(response):
                self.logger?.info(
                    "Received \(response.statusCode) response from \(self.getResponseUrlPath(response))",
                    attributes: ["endpoint": httpResponse?.url?.path]
                )
                httpResponse = response
            case let .failure(error):
                self.logger?.error("Failed to process response", error: error, attributes: nil)
                return completion(.failure(error))
            }
        }

        processError(error: error, response: httpResponse) { result in
            switch result {
            case .success:
                break
            case let .failure(error):
                self.logger?.error("Failed to process error for \(self.getResponseUrlPath(httpResponse))", error: error, attributes: nil)
                completion(.failure(error))
            }
        }

        processData(model: model, data: data, response: httpResponse, error: error) { result in
            switch result {
            case let .success(data):
                return completion(.success(data))
            case let .failure(error):
                self.logger?.error("Failed to process data", error: error, attributes: nil)
                return completion(.failure(error))
            }
        }
    }

    private func processResponse(response: URLResponse?, completion: @escaping (Result<HTTPURLResponse, Error>) -> Void) {
        guard let httpResponse = response as? HTTPURLResponse else {
            return completion(.failure(CommonErrors.UNKNOWN_SERVER_ERROR))
        }

        return completion(.success(httpResponse))
    }

    private func processError(error: Error?, response: HTTPURLResponse?, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let error = error else {
            return completion(.success(()))
        }

        completion(.failure(NSError(domain: "Error: \(error)", code: response?.statusCode ?? 500, userInfo: nil)))
    }

    private func processData<T: Decodable>(model: T.Type, data: Data?, response: HTTPURLResponse?, error: Error?, completion: @escaping (Result<T, Error>) -> Void) {
        guard let data = data else {
            return completion(.failure(ForageError.create(
                code: "invalid_input_data",
                httpStatusCode: response?.statusCode ?? 500,
                message: "Double check the reference documentation to validate the request body, and scan your implementation for any other errors."
            )))
        }

        guard let result = try? JSONDecoder().decode(T.self, from: data) else {
            // NOW TRY TO DECODE IT AS AN ERROR!
            guard let forageServiceError = try? JSONDecoder().decode(ForageServiceError.self, from: data) else {
                return completion(.failure(ForageError.create(
                    code: "unknown_server_error",
                    httpStatusCode: response?.statusCode ?? 500,
                    message: "Could not decode payload - \(String(decoding: data, as: UTF8.self))"
                )
                ))
            }
            let code = forageServiceError.errors[0].code
            let message = forageServiceError.errors[0].message
            return completion(.failure(ForageError.create(
                code: code,
                httpStatusCode: response?.statusCode ?? 500,
                message: message
            )))
        }

        return completion(.success(result))
    }

    private func getResponseUrlPath(_ httpResponse: HTTPURLResponse?) -> String {
        let host = httpResponse?.url?.host ?? ""
        let path = httpResponse?.url?.path ?? "N/A"
        return "\(host)\(path)"
    }

    func processVaultData<T: Decodable>(model: T.Type, code: Int?, data: Data?, response: URLResponse?, completion: @escaping (Result<T, Error>) -> Void) {
        var httpResponse: HTTPURLResponse?

        processResponse(response: response) { result in
            switch result {
            case let .success(response):
                httpResponse = response
            case let .failure(error):
                return completion(.failure(error))
            }
        }

        guard let data = data else {
            return completion(.failure(ForageError.create(
                code: "invalid_input_data",
                httpStatusCode: httpResponse?.statusCode ?? 500,
                message: "Double check the reference documentation to validate the request body, and scan your implementation for any other errors."
            )))
        }

        guard let result = try? JSONDecoder().decode(T.self, from: data) else {
            // NOW TRY TO DECODE IT AS AN ERROR!
            guard let forageServiceError = try? JSONDecoder().decode(ForageServiceError.self, from: data) else {
                return completion(.failure(ForageError.create(
                    code: "unknown_server_error",
                    httpStatusCode: httpResponse?.statusCode ?? 500,
                    message: "Could not decode payload - \(String(decoding: data, as: UTF8.self))"
                )))
            }

            let code = forageServiceError.errors[0].code
            let message = forageServiceError.errors[0].message
            return completion(.failure(ForageError.create(
                code: code,
                httpStatusCode: httpResponse?.statusCode ?? 500,
                message: message
            )))
        }

        return completion(.success(result))
    }
}
