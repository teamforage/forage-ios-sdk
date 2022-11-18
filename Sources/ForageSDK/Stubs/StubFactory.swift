//
//  BalanceStub.swift
//  ForageSDK
//
//  Created by Symphony on 10/11/22.
//

import Foundation

internal class BalanceStub {
    static var shared: BalanceStub = {
        let instance = BalanceStub()
        return instance
    }()

    private init() {}
    
    internal func makeMessageResponse(_ status: BalanceStatus, failed: Bool) -> MessageResponseModel {
        let messageStub = MessageResponseModel(
            contentId: "ee1889a2-7366-41a4-b918-bddae792d5f5",
            messageType: "0200",
            status: status,
            failed: failed,
            errors: []
        )
        return messageStub
    }
}
