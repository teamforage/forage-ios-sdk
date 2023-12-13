//
//  ForagePANTextField+Extension.swift
//
//
//  Created by Danilo Joksimovic on 2023-11-03.
//

import Foundation
import UIKit

// MARK: - UITextFieldDelegate

extension ForagePANTextField: UITextFieldDelegate {
    public func focusDidChange(_ state: TextFieldObservableState) {
        delegate?.focusDidChange(self)
    }

    public func textFieldDidChange(_ state: TextFieldObservableState) {
        delegate?.textFieldDidChange(self)
    }

    public func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate?.focusDidChange(self)
    }

    public func textFieldDidEndEditing(_ textField: UITextField) {
        delegate?.focusDidChange(self)
    }

    /// Determines whether the text field should allow a change of characters within the specified range.
    /// This method is called when the user attempts to change the content of the text field.
    /// - Parameters:
    ///   - textField: The text field containing the text.
    ///   - range: The range of characters to be replaced.
    ///   - replacementString: The replacement string.
    /// - Returns: `true` if the changes should be allowed; otherwise, `false`.
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString: String) -> Bool {
        let isBackspace = replacementString.isEmpty
        if isBackspace {
            return true
        }

        // Only allow the user to enter numeric strings
        if !replacementString.allSatisfy(\.isNumber) {
            return false
        }

        return true
    }
}
