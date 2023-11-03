//
//  String+Extension.swift
//
//
//  Created by Milos Bogdanovic on 08/16/23.
//  Copyright © 2023-Present Forage Technology Corporation. All rights reserved.
//

import UIKit

// MARK: - String extension

internal extension String {
    var isEmptyString: Bool {
        return self.trimmingCharacters(in: NSCharacterSet.whitespaces).isEmpty
    }
    
    subscript(safe index: Int) -> Character? {
        return index < count && index >= 0 ? self[self.index(startIndex, offsetBy: index)] : nil
    }
}
