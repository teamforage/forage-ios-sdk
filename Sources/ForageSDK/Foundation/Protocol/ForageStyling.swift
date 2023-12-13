//
//  ForageStyling.swift
//
//
//  Created by Danilo Joksimovic on 2023-12-09.
//

import UIKit

/// The higher visual characteristics that apply to every Forage input and are not specific to a single input.
public protocol Appearance {
    var textColor: UIColor? { get set }
    var tfTintColor: UIColor? { get set }
    var borderWidth: CGFloat { get set }
    var borderColor: UIColor? { get set }
    var cornerRadius: CGFloat { get set }
    var masksToBounds: Bool { get set }
}

/// The visual characteristics that require input-specific customization.
public protocol Style {
    var padding: UIEdgeInsets { get set }
    var textAlignment: NSTextAlignment { get set }
}
