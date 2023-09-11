//
//  VaultWrapperDelegate.swift
//  
//
//  Created by Shardendu Gautam on 6/12/23.
//  Copyright © 2023-Present Forage Technology Corporation. All rights reserved.
//
internal protocol VaultWrapperDelegate: AnyObject {
    func textFieldDidChange(_ textField: VaultWrapper)
    func firstResponderDidChange(_ textField: VaultWrapper)
}
