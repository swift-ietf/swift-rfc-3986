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
        .trait(name: "Coder", description: "Host text serialization")
    ],
    dependencies: [
        .package(
            url: "https://github.com/swift-atoms/swift-ascii.git",
            branch: "main",
            traits: [
                .trait(name: "Parser", condition: .when(traits: ["Coder"])),
                .trait(name: "Serializer", condition: .when(traits: ["Coder"])),
            ]
        ),
        .package(url: "https://github.com/swift-atoms/swift-byte.git", branch: "main"),
        .package(url: "https://github.com/swift-standards/swift-ipv4-standard.git", branch: "main"),
        .package(url: "https://github.com/swift-standards/swift-ipv6-standard.git", branch: "main"),
        .package(
            url: "https://github.com/swift-atoms/swift-serializer.git",
            branch: "main",
            traits: [
                .trait(name: "Either", condition: .when(traits: ["Coder"])),
                .trait(name: "Map", condition: .when(traits: ["Coder"])),
                .trait(name: "Pair", condition: .when(traits: ["Coder"])),
                .trait(name: "Repetition", condition: .when(traits: ["Coder"])),
            ]
        ),
        .package(
            url: "https://github.com/swift-ietf/swift-rfc-4291.git",
            branch: "main",
            traits: ["Coder"]
        ),
        .package(
            url: "https://github.com/swift-ietf/swift-rfc-791.git",
            branch: "main",
            traits: ["Coder"]
        ),
        .package(url: "https://github.com/swift-ietf/swift-rfc-4007.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-span.git", branch: "main", traits: ["Iterator"]),
        .package(url: "https://github.com/swift-atoms/swift-ratio.git", branch: "main", traits: ["Bit", "Ordinal", "Difference"]),
        .package(
            url: "https://github.com/swift-atoms/swift-binary.git",
            branch: "main",
            traits: [
                .trait(name: "LEB128", condition: .when(traits: ["Coder"])),
                .trait(name: "Serializer", condition: .when(traits: ["Coder"])),
            ]
        ),
        .package(
            url: "https://github.com/swift-atoms/swift-coder.git",
            branch: "main",
            traits: [
                .trait(name: "Checkpoint", condition: .when(traits: ["Coder"])),
                .trait(name: "Choice", condition: .when(traits: ["Coder"])),
                .trait(name: "Either", condition: .when(traits: ["Coder"])),
                .trait(name: "IteratorLeaves", condition: .when(traits: ["Coder"])),
                .trait(name: "Map", condition: .when(traits: ["Coder"])),
                .trait(name: "Pair", condition: .when(traits: ["Coder"])),
                .trait(name: "Predicate", condition: .when(traits: ["Coder"])),
                .trait(name: "Repetition", condition: .when(traits: ["Coder"])),
                .trait(name: "Skip", condition: .when(traits: ["Coder"])),
            ]
        ),
        .package(url: "https://github.com/swift-atoms/swift-cursor.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-either.git", branch: "main"),
        .package(
            url: "https://github.com/swift-atoms/swift-parser.git",
            branch: "main",
            traits: [
                .trait(name: "Always", condition: .when(traits: ["Coder"])),
                .trait(name: "Append", condition: .when(traits: ["Coder"])),
                .trait(name: "Choice", condition: .when(traits: ["Coder"])),
                .trait(name: "Either", condition: .when(traits: ["Coder"])),
                .trait(name: "FlatMap", condition: .when(traits: ["Coder"])),
                .trait(name: "Iterator", condition: .when(traits: ["Coder"])),
                .trait(name: "IteratorLeaves", condition: .when(traits: ["Coder"])),
                .trait(name: "Map", condition: .when(traits: ["Coder"])),
                .trait(name: "Pair", condition: .when(traits: ["Coder"])),
                .trait(name: "Predicate", condition: .when(traits: ["Coder"])),
                .trait(name: "Product", condition: .when(traits: ["Coder"])),
                .trait(name: "Repetition", condition: .when(traits: ["Coder"])),
                .trait(name: "Skip", condition: .when(traits: ["Coder"])),
            ]
        ),
        .package(
            url: "https://github.com/swift-ietf/swift-rfc-5952.git",
            branch: "main",
            traits: [.trait(name: "Coder", condition: .when(traits: ["Coder"]))]
        ),
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
                .product(name: "RFC 791", package: "swift-rfc-791", condition: .when(traits: ["Coder"])),
                .product(name: "RFC 4007", package: "swift-rfc-4007", condition: .when(traits: ["Coder"])),
                .product(name: "Coder", package: "swift-coder", condition: .when(traits: ["Coder"])),
                .product(name: "Cursor", package: "swift-cursor", condition: .when(traits: ["Coder"])),
                .product(name: "Either", package: "swift-either", condition: .when(traits: ["Coder"])),
                .product(name: "Parser", package: "swift-parser", condition: .when(traits: ["Coder"])),
                .product(name: "RFC 5952", package: "swift-rfc-5952", condition: .when(traits: ["Coder"])),
                .product(name: "Binary", package: "swift-binary", condition: .when(traits: ["Coder"])),
            ]
        ),
        .target(
            name: "RFC 3986 Foundation Integration",
            dependencies: [
                .target(name: "RFC 3986"),
                .product(name: "ASCII", package: "swift-ascii", condition: .when(traits: ["Coder"])),
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
                .product(name: "Coder", package: "swift-coder", condition: .when(traits: ["Coder"])),
                .product(name: "Cursor", package: "swift-cursor", condition: .when(traits: ["Coder"])),
                .product(name: "IPv6 Standard", package: "swift-ipv6-standard", condition: .when(traits: ["Coder"])),
                .product(name: "Parser", package: "swift-parser", condition: .when(traits: ["Coder"])),
                .product(name: "Serializer", package: "swift-serializer", condition: .when(traits: ["Coder"])),
                .product(name: "Binary", package: "swift-binary", condition: .when(traits: ["Coder"])),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    target.swiftSettings =
        (target.swiftSettings ?? []) + [
            .strictMemorySafety(),
            .enableUpcomingFeature("ExistentialAny"),
            .enableUpcomingFeature("InternalImportsByDefault"),
            .enableUpcomingFeature("MemberImportVisibility"),
            .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
            .enableUpcomingFeature("InferIsolatedConformances"),
            .enableExperimentalFeature("Lifetimes"),
            .treatAllWarnings(as: .error),
        ]
}
