//
//  ForageService.swift
//  ForageSDK
//
//  Created by Symphony on 30/10/22.
//

import Foundation

internal protocol ForageService: AnyObject {
    var provider: Provider { get }
    
    func sendPanCardNumber(
        request: ForagePANRequest,
        completion: @escaping (Result<ForagePANModel, Error>) -> Void) -> Void
    
    func getXKey(
        bearerToken: String,
        completion: @escaping (Result<ForageXKeyModel, Error>) -> Void) -> Void
    
    func cancelRequest()
}

internal class LiveForageService: ForageService {
    let provider = Provider()
    
    func sendPanCardNumber(request: ForagePANRequest, completion: @escaping (Result<ForagePANModel, Error>) -> Void) {
        do {
            try provider.execute(model: ForagePANModel.self, endpoint: ForageAPI.panNumber(request: request), completion: { result in
                switch result {
                case .success(let data):
                    completion(.success(data))
                case .failure(let error):
                    completion(.failure(error))
                }
            })
        } catch {
            completion(.failure(error))
        }
    }
    
    func getXKey(bearerToken: String, completion: @escaping (Result<ForageXKeyModel, Error>) -> Void) {
        do {
            try provider.execute(model: ForageXKeyModel.self, endpoint: ForageAPI.xKey(bearerToken: bearerToken), completion: { result in
                switch result {
                case .success(let data):
                    completion(.success(data))
                case .failure(let error):
                    completion(.failure(error))
                }
            })
        } catch {
            completion(.failure(error))
        }
    }
    
    func cancelRequest() {
        provider.stopRequestOnGoing()
    }
}
