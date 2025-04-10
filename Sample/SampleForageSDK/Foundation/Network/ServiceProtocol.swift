//
//  ServiceProtocol.swift
//  SampleForageSDK
//
//  Created by Tiago Oliveira on 26/10/22.
//  © 2022-Present Forage Technology Corporation. All rights reserved.
//

import Foundation

public typealias Parameters = [String: Any]
public typealias HTTPHeaders = [String: String]

enum HttpMethod: String {
    case get = "GET"
    case post = "POST"
}

enum HttpTask {
    case request
    case requestUrlParameters(urlParameters: Parameters)
    case requestBodyParameters(bodyParameters: Parameters)
    case requestParameters(bodyParameters: Parameters,
                           urlParameters: Parameters)
    case requestParametersAndHeaders(bodyParameters: Parameters?,
                                     urlParameters: Parameters?,
                                     additionalHeaders: HTTPHeaders)
}

protocol ServiceProtocol {
    var scheme: String { get }
    var host: String { get }
    var path: String { get }
    var method: HttpMethod { get }
    var task: HttpTask { get }
}

extension ServiceProtocol {
    func urlRequest() throws -> URLRequest {
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.path = path

        guard let url = components.url else { fatalError("Could not create URL") }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue

        do {
            switch task {
            case .request:
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            case let .requestUrlParameters(urlParameters):
                try configureParameters(bodyParameters: nil,
                                        urlParameters: urlParameters,
                                        request: &request)
            case let .requestBodyParameters(bodyParameters):
                try configureParameters(bodyParameters: bodyParameters,
                                        urlParameters: nil,
                                        request: &request)
            case let .requestParameters(bodyParameters, urlParameters):
                try configureParameters(bodyParameters: bodyParameters,
                                        urlParameters: urlParameters,
                                        request: &request)
            case let .requestParametersAndHeaders(bodyParameters,
                                                  urlParameters,
                                                  additionalHeaders):
                addAdditionalHeaders(additionalHeaders, request: &request)
                try configureParameters(bodyParameters: bodyParameters,
                                        urlParameters: urlParameters,
                                        request: &request)
            }
        } catch {
            throw error
        }
        return request
    }

    private func configureParameters(bodyParameters: Parameters?,
                                     urlParameters: Parameters?,
                                     request: inout URLRequest) throws {
        do {
            if let bodyParameters = bodyParameters {
                try JSONParameterEncoder.encode(urlRequest: &request, with: bodyParameters)
            }
            if let urlParameters = urlParameters {
                try URLParameterEncoder.encode(urlRequest: &request, with: urlParameters)
            }
        } catch {
            throw error
        }
    }

    private func addAdditionalHeaders(_ additionalHeaders: HTTPHeaders?, request: inout URLRequest) {
        guard let headers = additionalHeaders else { return }
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
    }
}
