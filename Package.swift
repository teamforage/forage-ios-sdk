// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ForageSDK",
    platforms: [
            .iOS(.v13),
        ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "ForageSDK",
            targets: ["ForageSDK"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(
            name: "VGSCollectSDK",
            url: "https://github.com/verygoodsecurity/vgs-collect-ios.git",
            from: "1.11.0"
        ),
        .package(
            name: "LaunchDarkly",
            url: "https://github.com/launchdarkly/ios-client-sdk.git",
            from: "8.0.1"
        ),
        .package(
            name: "BasisTheoryElements",
            url: "https://github.com/Basis-Theory/basistheory-ios",
            from: "2.6.0"
        ),
        .package(
            name: "Sentry", 
            url: "https://github.com/getsentry/sentry-cocoa", 
            from: "9.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "ForageSDK",
            dependencies: [
                "VGSCollectSDK",
                "LaunchDarkly",
                "BasisTheoryElements",
                "Sentry"
            ],
            path: "Sources", resources: [
                .process("Resources/Media.xcassets")
            ]),
        .testTarget(
            name: "ForageSDKTests",
            dependencies: ["ForageSDK"]),
    ]
)
