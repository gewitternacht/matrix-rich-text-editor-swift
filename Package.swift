// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription
let checksum = "710ffd1f305d05945e4d6ee64a1061b8dd0687d871638b36e8c1878ff810cd0b"
let version = "2.42.0"
let url = "https://github.com/element-hq/matrix-rich-text-editor-swift/releases/download/\(version)/WysiwygComposerFFI.xcframework.zip"
let package = Package(
    name: "WysiwygComposer",
    platforms: [
        .iOS(.v18),
    ],
    products: [
        .library(
            name: "WysiwygComposer",
            targets: ["WysiwygComposer"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/Cocoanetics/DTCoreText",
            exact: "1.6.26"
        )
    ],
    targets: [
        .target(
            name: "DTCoreTextExtended",
            dependencies: [
                .product(name: "DTCoreText", package: "DTCoreText"),
            ]
        ),
        .target(
            name: "HTMLParser",
            dependencies: [
                .product(name: "DTCoreText", package: "DTCoreText"),
                .target(name: "DTCoreTextExtended"),
            ]
        ),
        .binaryTarget(
            name: "WysiwygComposerFFI",
            url: url,
            checksum: checksum
        ),
        // UniFFI-generated Swift bindings. Kept in a dedicated target so they can opt out of
        // default MainActor isolation: the FFI layer is thread-agnostic (e.g. pointers are freed
        // from nonisolated deinits) and must not be forced onto the main actor.
        .target(
            name: "WysiwygComposerBindings",
            dependencies: [
                .target(name: "WysiwygComposerFFI"),
            ]
        ),
        .target(
            name: "WysiwygComposer",
            dependencies: [
                .target(name: "WysiwygComposerBindings"),
                .target(name: "HTMLParser"),
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)

/// The generated bindings target is left with the plain Swift 6 language mode (no default
/// isolation, no concurrency opt-ins) so the UniFFI output compiles as upstream intends.
let nonIsolatedTargets: Set = ["WysiwygComposerBindings"]

for target in package.targets where target.type != .binary && !nonIsolatedTargets.contains(target.name) {
    var settings = target.swiftSettings ?? []
    if target.type != .test {
        settings.append(.defaultIsolation(MainActor.self))
    }
    settings.append(contentsOf: [
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableUpcomingFeature("InferIsolatedConformances"),
    ])
    target.swiftSettings = settings
}
