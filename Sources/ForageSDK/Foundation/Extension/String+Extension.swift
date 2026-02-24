//
//  String+Extension.swift
//
//
//  Created by Milos Bogdanovic on 08/16/23.
//  © 2023-2025 Forage Technology Corporation. All rights reserved.
//

import UIKit

// MARK: - String extension

extension String {
    var isEmptyString: Bool {
        trimmingCharacters(in: NSCharacterSet.whitespaces).isEmpty
    }

    subscript(safe index: Int) -> Character? {
        index < count && index >= 0 ? self[self.index(startIndex, offsetBy: index)] : nil
    }
}
