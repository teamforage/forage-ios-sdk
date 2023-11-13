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
protocol Polling: AnyObject {
    /// Handle Vault Response to start polling
    ///
    /// - Parameters:
    ///  - vaultResponse: Response from Vault request.
    ///  - request: Model composed with info to identify the polling.
    ///  - completion: Which will return a `Result` to be handle.
    func execute(
        vaultResponse: VaultResponse,
        request: ForageRequestModel,
        completion: @escaping (Result<Data?, Error>) -> Void
    )
}
