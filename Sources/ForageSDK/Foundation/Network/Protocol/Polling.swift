//
//  Polling.swift
//  ForageSDK
//
//  Created by Tiago Oliveira on 21/11/22.
//  Copyright © 2022-Present Forage Technology Corporation. All rights reserved.
//

import Foundation
import VGSCollectSDK

/**
 Interface for Polling service.
 */
internal protocol Polling: AnyObject {
    /// Handle Vault Response to start polling
    ///
    /// - Parameters:
    ///  - vaultResponse: Response from Vault request.
    ///  - request: Model composed with info to identify the polling.
    ///  - completion: Which will return a `Result` to be handle.
    func polling(
        vaultResponse: VaultResponse,
        request: ForageRequestModel,
        completion: @escaping (Result<Data?, Error>) -> Void)
    
    /// Polling method
    ///
    /// - Parameters:
    ///  - contentId: Message object to be used to polling.
    ///  - request: Model composed with info to identify the polling.
    ///  - completion: Return a `MessageResponseModel` to check its validation. It will trigger another request using its object or it will return a completion `.success` or `.failure`.
    func pollingMessage(
        contentId: String,
        request: ForageRequestModel,
        completion: @escaping (Result<MessageResponseModel, Error>) -> Void) -> Void
}
