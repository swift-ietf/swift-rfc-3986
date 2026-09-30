// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-rfc-3986",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
        .visionOS(.v27),
    ],
    products: [
        .library(
            name: "RFC 3986",
            targets: ["RFC 3986"]
        ),
        .library(
            name: "RFC 3986 Foundation Integration",
            targets: ["RFC 3986 Foundation Integration"]
        ),
    ],
    traits: [
        .trait(name: "Coder", description: "Host text serialization"),
    ],
    dependencies: [
        .package(
            url: "https://github.com/swift-atoms/swift-ascii.git",
            branch: "main"
        ),
        .package(url: "https://github.com/swift-atoms/swift-byte.git", branch: "main"),
        .package(url: "https://github.com/swift-standards/swift-ipv4-standard.git", branch: "main"),
        .package(url: "https://github.com/swift-standards/swift-ipv6-standard.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-serializer.git", branch: "main"),
        .package(url: "https://github.com/swift-ietf/swift-rfc-4291.git", branch: "main"),
        .package(url: "https://github.com/swift-ietf/swift-rfc-5952-coder.git", branch: "main"),
        .package(url: "https://github.com/swift-ietf/swift-rfc-791.git", branch: "main"),
        .package(url: "https://github.com/swift-ietf/swift-rfc-4007.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-span.git", branch: "main", traits: ["Iterator"]),
        .package(url: "https://github.com/swift-atoms/swift-ratio.git", branch: "main", traits: ["Bit", "Ordinal", "Difference"]),
    ],
    targets: [
        .target(
            name: "RFC 3986",
            dependencies: [
                .product(name: "ASCII", package: "swift-ascii"),
                .product(name: "Byte", package: "swift-byte"),
                .product(name: "IPv4 Standard", package: "swift-ipv4-standard"),
                .product(name: "IPv6 Standard", package: "swift-ipv6-standard"),
                .product(name: "Serializer", package: "swift-serializer", condition: .when(traits: ["Coder"])),
                .product(name: "RFC 4291", package: "swift-rfc-4291", condition: .when(traits: ["Coder"])),
                .product(name: "RFC 5952 Coder", package: "swift-rfc-5952-coder", condition: .when(traits: ["Coder"])),
                .product(name: "RFC 791", package: "swift-rfc-791", condition: .when(traits: ["Coder"])),
                .product(name: "RFC 4007", package: "swift-rfc-4007", condition: .when(traits: ["Coder"])),
            ]
        ),
        .target(
            name: "RFC 3986 Foundation Integration",
            dependencies: [
                .target(name: "RFC 3986")
            ]
        ),
        .testTarget(
            name: "RFC 3986 Foundation Integration Tests",
            dependencies: [
                .target(name: "RFC 3986"),
                .target(name: "RFC 3986 Foundation Integration"),
            ]
        ),
        .testTarget(
            name: "RFC 3986 Tests",
            dependencies: [
                .product(name: "ASCII", package: "swift-ascii"),
                .target(name: "RFC 3986"),
                .product(name: "Byte", package: "swift-byte"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

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
