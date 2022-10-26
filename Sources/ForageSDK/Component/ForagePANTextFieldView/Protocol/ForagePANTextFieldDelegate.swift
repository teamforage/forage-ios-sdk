//
//  ForagePANTextFieldDelegate.swift
//  ForageSDK
//
//  Created by Symphony on 23/10/22.
//

import UIKit

// MARK: - ForagePANTextFieldDelegate

/// Protocol to comunicate `ForagePANTextFieldView` to the client application
public protocol ForagePANTextFieldDelegate: AnyObject {
    func panNumberStatus(_ view: UIView, isValid: Bool)
    func panNumberFailure(_ view: UIView, error: Error)
}
