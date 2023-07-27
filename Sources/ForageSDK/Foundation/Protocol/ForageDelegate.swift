//
//  File.swift
//  
//
//  Created by Danny Leiser on 7/27/23.
//

public protocol ForageDelegate: AnyObject {
    func focusDidChange(_ inputField: ForageUI)
    func textFieldDidChange(_ inputField: ForageUI)
    func blurDidChange(_ inputField: ForageUI)
}
