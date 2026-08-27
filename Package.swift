// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-rfc-3986",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
    ],
    products: [
        .library(
            name: "RFC 3986",
            targets: ["RFC 3986"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/swift-molecules/swift-standard-library-extensions.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-parser.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-ascii.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-ascii-serializer.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-ascii-parser.git",
            branch: "main"
        ),
        .package(url: "https://github.com/swift-standards/swift-ipv4-standard.git", branch: "main"),
        .package(url: "https://github.com/swift-standards/swift-ipv6-standard.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "RFC 3986",
            dependencies: [
                .product(
                    name: "Standard Library Extensions",
                    package: "swift-standard-library-extensions"
                ),
                .product(name: "Parser", package: "swift-parser"),
                .product(name: "ASCII", package: "swift-ascii"),
                .product(
                    name: "ASCII Serializer",
                    package: "swift-ascii-serializer"
                ),
                .product(
                    name: "ASCII Decimal Parser",
                    package: "swift-ascii-parser"
                ),
                .product(
                    name: "Parseable ASCII",
                    package: "swift-ascii-parser"
                ),
                .product(name: "IPv4 Standard", package: "swift-ipv4-standard"),
                .product(name: "IPv6 Standard", package: "swift-ipv6-standard"),
            ]
        ),
        .testTarget(
            name: "RFC 3986 Tests",
            dependencies: [
                "RFC 3986"
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

extension String {
    var tests: Self { self + " Tests" }
    var foundation: Self { self + " Foundation" }
}

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
