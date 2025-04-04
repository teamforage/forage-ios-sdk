//
//  ForagePaymentSheetElement.swift
//  ForageSDK
//
//  Created by Jerimiah on 3/4/25.
//  Copyright © 2025-Present Forage Technology Corporation. All rights reserved.
//

import UIKit

public protocol PaymentSheetObservableState {
    /// isComplete is true when all of the inputs on the sheet are valid and the sheet ready to be submitted.
    var isComplete: Bool { get }
    var completionErrors: [String: any Error] { get }
    var currentFirstResponder: (any ForagePaymentSheetField)? { get }
}

public protocol ForagePaymentSheetElementDelegate {
    func sheetTextFieldDidChange(_ state: PaymentSheetObservableState)
    func sheetFocusDidChange(_ state: PaymentSheetObservableState)
}

public protocol ForagePaymentSheetElement: UIView, Identifiable, Appearance, Style, PaymentSheetObservableState {
    var delegate: ForagePaymentSheetElementDelegate? { get set }
    
    /// clear the entire sheet. Calls clearText on all sheet inputs
    func clearSheet()
}

public protocol ForagePaymentSheetField: ForageElement {
    var invalidError: (any Error)? { get }
    var isDirty: Bool { get }
    var isTouched: Bool { get }
    var name: String { get set }
}
