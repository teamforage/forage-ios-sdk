//
//  ForageElementDelegate.swift
//  
//
//  Created by Danny Leiser on 7/27/23.
//

public protocol ForageElementDelegate: AnyObject {
    func focusDidChange(_ state: ObservableState)
    func textFieldDidChange(_ state: ObservableState)
    func blurDidChange(_ state: ObservableState)
}
