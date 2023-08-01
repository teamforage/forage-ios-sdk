//
//  File.swift
//  
//
//  Created by Danny Leiser on 7/27/23.
//

import UIKit

/// The state of an input that Forage exposes during events or statically as input instance attributes.
public protocol ObservableState {
    var isFirstResponder: Bool { get set }
    var isBlured: Bool { get set }
    var isEmpty: Bool { get set }
    var isValid: Bool { get set }
    var isComplete: Bool { get set }
}

/// The higher visual characteristics that apply to every Forage input and are not specific to a single input.
public protocol Appearance {
    var textColor: UIColor? { get set }
    var tfTintColor: UIColor? { get set }
    var textAlignment: NSTextAlignment { get set }
    var borderWidth: CGFloat { get set }
    var borderColor: UIColor? { get set }
    var padding: UIEdgeInsets { get set }
}

/// The visual characteristics that require input-specific customization.
public protocol Style {
    
}

/// The interface that all of Forage’s input elements adhere to be it for PAN or PIN.
public protocol ForageElement: UIView, Appearance, ObservableState, Style {
    var delegate: ForageElementDelegate? { get set }
    func setPlaceholderText(_ text: String)
    func clearText() -> Void
    func becomeFirstResponder() -> Bool
}
