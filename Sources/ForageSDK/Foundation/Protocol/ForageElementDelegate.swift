//
//  ForageElementDelegate.swift
//
//
//  Created by Danny Leiser on 7/27/23.
//  © 2023-2025 Forage Technology Corporation. All rights reserved.
//

public protocol ForageElementDelegate: AnyObject {
    func focusDidChange(_ state: ObservableState)
    func textFieldDidChange(_ state: ObservableState)
}
