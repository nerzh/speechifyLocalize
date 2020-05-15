// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "speechifyLocalize",
    dependencies: [
        .package(name: "SwiftRegularExpression", url: "https://github.com/nerzh/swift-regular-expression.git", .upToNextMajor(from: "0.2.0")),
        .package(name: "swift-argument-parser", url: "https://github.com/apple/swift-argument-parser", .upToNextMajor(from: "0.0.5")),
        .package(name: "PathKit", url: "https://github.com/kylef/PathKit", .upToNextMajor(from: "1.0.0")),
        .package(name: "Path.swift", url: "https://github.com/mxcl/Path.swift.git", .upToNextMajor(from: "1.0.1")),
    ],
    targets: [
        .target(
            name: "speechifyLocalize",
            dependencies: [
                .product(name: "SwiftRegularExpression", package: "SwiftRegularExpression"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "PathKit", package: "PathKit"),
                .product(name: "Path", package: "Path.swift")
            ]),
//        .testTarget(
//            name: "find-localizable-stringsTests",
//            dependencies: ["find-localizable-strings"]),
    ]
)
