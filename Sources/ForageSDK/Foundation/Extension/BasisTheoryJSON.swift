//
//  BasisTheoryJSON.swift
//
//
//  Created by Danilo Joksimovic on 2024-02-28.
//

import BasisTheoryElements
import Foundation

extension JSON {
    // converts Basis Theory JSON enum to Swift dictionary
    static func convertJsonToDictionary(_ json: JSON?) -> [String: Any] {
        var result: [String: Any] = [:]

        if case let .dictionaryValue(dictionary) = json {
            for (key, value) in dictionary {
                switch value {
                case let .rawValue(rawValue):
                    result[key] = rawValue
                case let .arrayValue(array):
                    result[key] = array.compactMap { element in
                        if case let .rawValue(rawValue) = element {
                            return rawValue
                        } else {
                            return convertJsonToDictionary(element)
                        }
                    }
                default:
                    result[key] = convertJsonToDictionary(value)
                }
            }
        }
        return result
    }
}
