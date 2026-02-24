//
//  Validatable.swift
//  ForageSDK
//
//  Created by Jerimiah on 3/13/25.
//  © 2025 Forage Technology Corporation. All rights reserved.
//

import UIKit

// protocol to facilitate validating the text in a UITextField
protocol Validatable: UITextField {
    /// property to store the valid state
    var isValid: Bool { get set }
    
    /// property to store the reason the field is invalid
    var invalidError: (any Error)? { get set }
    
    /// collection of validators. Can throw an invalid message
    var validators: [(String) throws -> (Bool)] { get }
    
    func validateText(_ text: String) -> Bool
}

extension Validatable {
    func validateText(_ text: String) -> Bool {
        do {
            let _isValid = try validators.allSatisfy { try $0(text) }
            isValid = _isValid
            invalidError = nil
            return _isValid
        } catch let error {
            isValid = false
            invalidError = error
        }
        return false
    }
}
