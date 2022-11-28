//
//  AssetsBundle.swift
//  ForageSDK
//
//  Created by Symphony on 28/11/22.
//

import Foundation

internal class AssetsBundle {
    static var main = AssetsBundle()
    var iconBundle: Bundle?

    init() {
        // Identify bundle for SPM.
        #if SWIFT_PACKAGE
            iconBundle = Bundle.module
        #endif

        // Return if bundle is found.
        guard iconBundle == nil else {
            return
        }

        let containingBundle = Bundle(for: AssetsBundle.self)

        // Look for ForageIcon bundle (handle CocoaPods integration).
        if let bundleURL = containingBundle.url(forResource: "ForageIcon", withExtension: "bundle") {
            iconBundle = Bundle(url: bundleURL)
        } else {
            iconBundle = containingBundle
        }
    }
}
