//
//  CustomViewProtocol.swift
//  SampleForageSDK
//
//  Created by Tiago Oliveira on 18/10/22.
//  © 2022-Present Forage Technology Corporation. All rights reserved.
//

import Foundation
import UIKit

public protocol CustomViewProtocol {
    associatedtype CustomView: UIView
}

extension CustomViewProtocol where Self: UIViewController {
    /// The UIViewController's custom view.
    public var customView: CustomView {
        guard let customView = view as? CustomView else {
            fatalError("Expected view to be of type \(CustomView.self) but got \(type(of: view)) instead")
        }
        return customView
    }
}
