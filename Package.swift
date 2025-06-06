// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ForageSDK",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "ForageSDK",
            targets: ["ForageSDK"]
        )
    ],
    dependencies: [],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "ForageSDK",
            dependencies: ["DatadogPrivateFork"],
            path: "Sources",
            resources: [
                .process("Resources/Media.xcassets"),
                .copy("Resources/PrivacyInfo.xcprivacy")
            ],
            swiftSettings: [.define("SPM_BUILD")]
        ),
        .testTarget(
            name: "ForageSDKTests",
            dependencies: ["ForageSDK"]
        ),

        // Bridge Datadog's "Private" Objective C code with our Swift code.
        .target(
            name: "DatadogPrivateFork",
            path: "DatadogPrivate-Objc"
        )
    ]
)
