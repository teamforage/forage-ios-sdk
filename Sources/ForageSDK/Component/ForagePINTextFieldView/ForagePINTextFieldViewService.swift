//
//  ForagePINTextFieldViewService.swift
//  ForageSDK
//
//  Created by Symphony on 24/10/22.
//

import Foundation

internal class ForagePINTextFieldViewService {
    let provider = Provider()
    
    func getXKey(
        bearerToken: String,
        completion: @escaping (Result<ForageXKeyModel, Error>) -> Void) -> Void {
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
}
