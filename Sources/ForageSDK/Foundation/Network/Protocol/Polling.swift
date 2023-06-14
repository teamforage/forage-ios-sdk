//
//  Polling.swift
//  ForageSDK
//
//  Created by Symphony on 21/11/22.
//

import Foundation
import VGSCollectSDK

/**
 Interface for Polling
 */
internal protocol Polling: AnyObject {
    /// Handle VGS Response to start polling
    ///
    /// - Parameters:
    ///  - response: Response from VGS request. (See more [here](https://verygoodsecurity.github.io/vgs-collect-ios/Enums/VGSResponse.html))
    ///  - request: Model composed with info to identify the polling.
    ///  - completion: Which will return a `Result` to be handle.
    func polling(
        response: VaultResponse,
        request: ForageRequestModel,
        completion: @escaping (Result<Data?, Error>) -> Void)
    
    /// Polling method
    ///
    /// - Parameters:
    ///  - message: Message object to be used to polling.
    ///  - request: Model composed with info to identify the polling.
    ///  - completion: Return a `MessageResponseModel` to check its validation. It will trigger another request using its object or it will return a completion `.success` or `.failure`.
    func pollingMessage(
        message: MessageResponseModel,
        request: ForageRequestModel,
        completion: @escaping (Result<MessageResponseModel, Error>) -> Void) -> Void
}
