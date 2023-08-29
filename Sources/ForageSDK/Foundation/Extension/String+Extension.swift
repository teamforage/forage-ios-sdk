//
//  String+Extension.swift
//  
//
//  Created by Milos Bogdanovic on 08/16/23.
//

import UIKit

// MARK: - String extension

public extension String {
    var isEmptyString: Bool {
        return self.trimmingCharacters(in: NSCharacterSet.whitespaces).isEmpty
    }
}
