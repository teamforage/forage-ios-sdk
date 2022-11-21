//
//  Polling.swift
//  ForageSDK
//
//  Created by Symphony on 21/11/22.
//

import Foundation
import VGSCollectSDK

internal protocol Polling: AnyObject {
    func polling(
        response: VGSResponse,
        request: ForageRequestModel,
        completion: @escaping (Result<Data?, Error>) -> Void)
    
    func pollingMessage(
        message: MessageResponseModel,
        request: ForageRequestModel,
        completion: @escaping (Result<MessageResponseModel, Error>) -> Void) -> Void
}
