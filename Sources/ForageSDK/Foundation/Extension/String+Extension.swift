//
//  String+Extension.swift
//
//
//  Created by Milos Bogdanovic on 08/16/23.
//  Copyright © 2023-Present Forage Technology Corporation. All rights reserved.
//

import UIKit

// MARK: - String extension

extension String {
    public var isEmptyString: Bool {
        trimmingCharacters(in: NSCharacterSet.whitespaces).isEmpty
    }
}
