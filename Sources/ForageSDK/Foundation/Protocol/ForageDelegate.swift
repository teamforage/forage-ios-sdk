//
//  File.swift
//  
//
//  Created by Danny Leiser on 7/27/23.
//

public protocol ForageDelegate: AnyObject {
    func focusDidChange(_ textField: PINVaultTextField)
    func textFieldDidChange(_ textField: PINVaultTextField)
    func blurDidChange(_ textField: PINVaultTextField)
}
