//
//  ForagePANTextFieldViewService.swift
//  ForageSDK
//
//  Created by Symphony on 20/10/22.
//

import Foundation

internal class ForagePANTextFieldViewService {
    let provider = Provider()
    
    func sendPanCardNumber(
        request: ForagePANRequest,
        completion: @escaping (Result<ForagePANModel, Error>) -> Void) -> Void {
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
}
