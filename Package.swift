// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "speechifyLocalize",
    products: [
        .library(name: "SLLib", targets: ["SLLib"])
    ],
    dependencies: [
        .package(name: "SwiftRegularExpression", url: "https://github.com/nerzh/swift-regular-expression.git", .upToNextMajor(from: "0.2.4")),
        .package(name: "swift-argument-parser", url: "https://github.com/apple/swift-argument-parser", .exact("0.0.5")),
        .package(name: "SwiftExtensionsPack", url: "https://github.com/nerzh/swift-extensions-pack.git", .exact("0.5.8")),
    ],
    targets: [
        .target(
        name: "SLLib",
        dependencies: [
            .product(name: "SwiftRegularExpression", package: "SwiftRegularExpression"),
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
            .product(name: "SwiftExtensionsPack", package: "SwiftExtensionsPack"),
        ]),
        .target(
            name: "speechifyLocalize",
            dependencies: [
                .target(name: "SLLib")
            ]),
        .testTarget(
            name: "speechifyLocalizeTests",
            dependencies: ["speechifyLocalize"]),
    ]
)
