//
//  ForagePINTextFieldDelegate.swift
//  ForageSDK
//
//  Created by Symphony on 24/10/22.
//

import UIKit

public enum PinType: String {
    case snap
    case nonSnap
    case balance
}

// MARK: - ForagePINTextFieldDelegate

/// Protocol to comunicate `ForagePINTextField` to the client application
public protocol ForagePINTextFieldDelegate: AnyObject {
    /// Passcode pin status
    ///
    /// - Parameters:
    ///  - view: ForagePINTextField view reference.
    ///  - isValid: Entered pin current status.
    ///  - pinType: Pin text field type. Check ``PinType`` for details.
    func pinStatus(_ view: UIView, isValid: Bool, pinType: PinType)
}
