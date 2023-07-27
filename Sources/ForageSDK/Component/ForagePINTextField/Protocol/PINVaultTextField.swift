//
//  File.swift
//  
//
//  Created by Shardendu Gautam on 6/6/23.
//

import UIKit

public protocol PINVaultTextField: UIView {
    var placeholder: String? { get set }
    var collector: VaultCollector { get set }
    var textColor: UIColor? { get set }
    var tfTintColor: UIColor? { get set }
    var isSecureTextEntry: Bool { get set }
    var textAlignment: NSTextAlignment { get set }
    var font: UIFont? { get set }
    var borderWidth: CGFloat { get set }
    var borderColor: UIColor? { get set }
    var padding: UIEdgeInsets { get set }
    var autocorrectionType: UITextAutocorrectionType { get set }
    var delegate: PINVaultTextFieldDelegate? { get set }
    func isValid() -> Bool
    func setTranslatesAutoresizingMaskIntoConstraints(_ flag: Bool)
    func setAccessibilityIdentifier(_ identifier: String)
    func setIsAccessibilityElement(_ flag: Bool)
    func setPlaceholderText(_ text: String)
    func cleanText() -> Void
}
