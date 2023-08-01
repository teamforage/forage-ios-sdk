//
//  VaultWrapper.swift
//  
//
//  Created by Shardendu Gautam on 6/6/23.
//

import UIKit

/// The state that the underlying vault exposes during events or statically as input instance attributes.
internal protocol InternalObservableState {
    /// isFirstResponder is true if the input is focused, false otherwise.
    var isFirstResponder: Bool { get }
    
    /// isBlured is true if the input is blured, false otherwise.
    var isBlured: Bool { get }
    
    /// isEmpty is true if the input is empty, false otherwise.
    var isEmpty: Bool { get }
    
    /// isValid is true when the input text does not fail any validation checks with the exception of target length;
    /// false if any of the validation checks other than target length fail.
    var isValid: Bool { get }
    
    /// isComplete is true when all validation checks pass and the input is ready to be submitted.
    var isComplete: Bool { get }
}

/// The higher visual characteristics that apply to every vault instance and are not specific to a single input.
internal protocol InternalAppearance {
    var textColor: UIColor? { get set }
    var tfTintColor: UIColor? { get set }
    var borderWidth: CGFloat { get set }
    var borderColor: UIColor? { get set }
    var font: UIFont? { get set }
}

/// The visual characteristics that require input-specific customization.
internal protocol InternalStyle {
    var padding: UIEdgeInsets { get set }
    var textAlignment: NSTextAlignment { get set }
    var placeholder: String? { get set }
}

internal protocol VaultWrapper: UIView, InternalObservableState, InternalAppearance, InternalStyle {
    var collector: VaultCollector { get set }
    var delegate: VaultWrapperDelegate? { get set }
    func setPlaceholderText(_ text: String)
    func clearText() -> Void
}
