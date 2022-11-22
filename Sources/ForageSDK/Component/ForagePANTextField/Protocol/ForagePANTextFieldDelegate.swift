//
//  ForagePANTextFieldDelegate.swift
//  ForageSDK
//
//  Created by Symphony on 23/10/22.
//

import UIKit

public enum CardStatus: String {
    case valid
    case invalid
    case identifying
}

// MARK: - ForagePANTextFieldDelegate

/// Protocol to comunicate `ForagePANTextField` to the client application
public protocol ForagePANTextFieldDelegate: AnyObject {
    /// Ebt card number status
    ///
    /// - Parameters:
    ///  - view: ForagePANTextField view reference.
    ///  - cardStatus: Ebt card number validations status. Check ``CardStatus`` for details.
    func panNumberStatus(_ view: UIView, cardStatus: CardStatus)
}
