//
//  CreatePaymentService.swift
//  SampleForageSDK
//
//  Created by Tiago Oliveira on 26/10/22.
//  Copyright © 2022-Present Forage Technology Corporation. All rights reserved.
//

import Foundation

internal class CreatePaymentService {
    let provider = Provider()

    func createPayment(request: CreatePaymentRequest,
                       completion: @escaping (Result<CreatePaymentResponse, Error>) -> Void) {
        do {
            try provider.execute(model: CreatePaymentResponse.self, endpoint: SampleAPI.createPayment(request: request), completion: { result in
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
