//
//  CreatePaymentService.swift
//  SampleForageSDK
//
//  Created by Tiago Oliveira on 26/10/22.
//  © 2022-Present Forage Technology Corporation. All rights reserved.
//

import Foundation

class CreatePaymentService {
    let provider = Provider()

    func createPayment(request: CreatePaymentRequest,
                       completion: @escaping (Result<CreatePaymentResponse, Error>) -> Void) {
        do {
            try provider.execute(model: CreatePaymentResponse.self, endpoint: SampleAPI.createPayment(request: request), completion: { result in
                switch result {
                case let .success(data):
                    completion(.success(data))
                case let .failure(error):
                    completion(.failure(error))
                }
            })
        } catch {
            completion(.failure(error))
        }
    }
}
