//
//  File.swift
//  
//
//  Created by Danny Leiser on 7/27/23.
//

public protocol ForageElementDelegate: AnyObject {
    func focusDidChange(_ inputField: ForageElement)
    func textFieldDidChange(_ inputField: ForageElement)
    func blurDidChange(_ inputField: ForageElement)
}
