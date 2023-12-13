//
//  ForageElement.swift
//
//
//  Created by Danny Leiser on 7/27/23.
//  Copyright © 2023-Present Forage Technology Corporation. All rights reserved.
//

import UIKit

// MARK: Common

/// The interface that all of Forage’s input elements adhere to be it for PAN or PIN.
public protocol ForageElement: UIView, Identifiable, ObservableState {}

/// The `ObservableState` protocol defines properties reflecting the state of a `ForageElement`.
public protocol ObservableState {
    /// Indicates whether all validation checks pass and the `ForageElement` is ready for submission.
    var isComplete: Bool { get }
}

// MARK: ForageTextField

/// The `TextFieldObservableState` protocol defines properties reflecting the state of a `ForageTextField`.
public protocol TextFieldObservableState: ObservableState {
    /// Indicates whether the input is focused.
    var isFirstResponder: Bool { get }

    /// Indicates whether the input is empty.
    var isEmpty: Bool { get }

    /// Indicates whether all validation checks pass, excluding the the minimum length validator.
    var isValid: Bool { get }
}

public protocol ForageTextField: ForageElement, TextFieldObservableState, Appearance, Style {
    /// Clears the current text in the input field.
    func clearText()

    /// Requests the input field to become the first responder, bringing the keyboard into view.
    /// - Returns: A Boolean value indicating whether the input field successfully became the first responder.
    func becomeFirstResponder() -> Bool

    /// Requests the input field to resign its first responder status, which will dismiss the keyboard.
    /// - Returns: A Boolean value indicating whether the input field successfully resigned its first responder status.
    func resignFirstResponder() -> Bool
}

public protocol ForageTextFieldDelegate: AnyObject {
    func focusDidChange(_ state: TextFieldObservableState)
    func textFieldDidChange(_ state: TextFieldObservableState)
}

// MARK: ForageTable

public protocol ForageTableDelegate: AnyObject {}

public protocol ForageTableView: ForageElement {
    var delegate: ForageTableDelegate? { get set }
}
