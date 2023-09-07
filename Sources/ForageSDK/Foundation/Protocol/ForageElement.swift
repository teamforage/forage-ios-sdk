//
//  ForageElement.swift
//  
//
//  Created by Danny Leiser on 7/27/23.
//

import UIKit

/// The state of an input that Forage exposes during events or statically as input instance attributes.
public protocol ObservableState {
    /// isFirstResponder is true if the input is focused, false otherwise.
    var isFirstResponder: Bool { get }
    
    /// isEmpty is true if the input is empty, false otherwise.
    var isEmpty: Bool { get }
    
    /// isValid is true when the input text does not fail any validation checks with the exception of target length;
    /// false if any of the validation checks other than target length fail.
    var isValid: Bool { get }
    
    /// isComplete is true when all validation checks pass and the input is ready to be submitted.
    var isComplete: Bool { get }
}

/// The higher visual characteristics that apply to every Forage input and are not specific to a single input.
public protocol Appearance {
    var textColor: UIColor? { get set }
    var tfTintColor: UIColor? { get set }
    var borderWidth: CGFloat { get set }
    var borderColor: UIColor? { get set }
    var cornerRadius: CGFloat { get set }
}

/// The visual characteristics that require input-specific customization.
public protocol Style {
    var padding: UIEdgeInsets { get set }
    var textAlignment: NSTextAlignment { get set }
}

/// The interface that all of Forage’s input elements adhere to be it for PAN or PIN.
public protocol ForageElement: UIView, Appearance, ObservableState, Style {
    var delegate: ForageElementDelegate? { get set }
    
    /// Set the placeholder text of the input field.
    func setPlaceholderText(_ text: String)
    
    /// Clear the value in the input field.
    func clearText() -> Void
    
    /// Request that the input field gain focus.
    func becomeFirstResponder() -> Bool
    
    /// Request that the input field resign focus.
    func resignFirstResponder() -> Bool
}
