//
//  ForagePANElement.swift
//
//
//  Created by Danny Leiser on 11/23/23.
//  Copyright © 2023-Present Forage Technology Corporation. All rights reserved.
//

/// Added information that can be inferred from the card value.
public protocol CardInformation {
    var binValue: String? { get }
}
