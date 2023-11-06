//
//  ForageElementDelegate.swift
//
//
//  Created by Danny Leiser on 7/27/23.
//  Copyright © 2023-Present Forage Technology Corporation. All rights reserved.
//

public protocol ForageElementDelegate: AnyObject {
    func focusDidChange(_ state: ObservableState)
    func textFieldDidChange(_ state: ObservableState)
}
