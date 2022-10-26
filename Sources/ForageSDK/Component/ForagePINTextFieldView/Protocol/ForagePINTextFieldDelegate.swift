//
//  ForagePINTextFieldDelegate.swift
//  ForageSDK
//
//  Created by Symphony on 24/10/22.
//

import UIKit

// MARK: - ForagePINTextFieldDelegate

/// Protocol to comunicate `ForagePINTextFieldView` to the client application
public protocol ForagePINTextFieldDelegate: AnyObject {
    func pinStatus(_ view: UIView, isValid: Bool)
    func pinFailure(_ view: UIView, error: Error)
}
