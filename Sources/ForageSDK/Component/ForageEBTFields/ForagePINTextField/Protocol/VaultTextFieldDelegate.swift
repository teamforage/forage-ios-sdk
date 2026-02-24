//
//  VaultWrapperDelegate.swift
//
//
//  Created by Shardendu Gautam on 6/12/23.
//  © 2023-2025 Forage Technology Corporation. All rights reserved.
//
protocol VaultWrapperDelegate: AnyObject {
    func textFieldDidChange(_ textField: VaultWrapper)
    func firstResponderDidChange(_ textField: VaultWrapper)
}
