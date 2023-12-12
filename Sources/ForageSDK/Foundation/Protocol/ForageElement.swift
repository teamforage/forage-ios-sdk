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

// TODO: update comments
public protocol ForageTextField: ForageElement, TextFieldObservableState, Appearance, Style {
    /// Clear the value in the input field.
    func clearText()

    /// Request that the input field gains focus. Returns ... if
    func becomeFirstResponder() -> Bool

    /// Request that the input field resign focus. Returns ...
    func resignFirstResponder() -> Bool
}

public protocol ForageTextFieldDelegate: AnyObject {
    func focusDidChange(_ state: TextFieldObservableState)
    func textFieldDidChange(_ state: TextFieldObservableState)
}

// MARK: ForageTable

public protocol ForageTableDelegate: AnyObject {
    // TODO: consider rename
    func textFieldDidChange(_ state: ObservableState)
}

public protocol ForageTableView: ForageElement {
    var delegate: ForageTableDelegate? { get set }
}
