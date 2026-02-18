// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ThemeKit",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "ThemeKit",
            targets: ["ThemeKit"]
        ),
        .plugin(
            name: "ThemeKitPlugin",
            targets: ["ThemeKitPlugin"]
        ),
    ],
    targets: [
        .target(
            name: "ThemeKit"
        ),
        .target(
            name: "ThemeKitGenerator"
        ),
        .executableTarget(
            name: "ThemeKitGeneratorCLI",
            dependencies: ["ThemeKitGenerator"]
        ),
        .plugin(
            name: "ThemeKitPlugin",
            capability: .command(
                intent: .custom(verb: "generate-theme", description: "Generate Theme Files"),
                permissions: [.writeToPackageDirectory(reason: "Generates Swift theme files from theme.json")]
            ),
            dependencies: ["ThemeKitGeneratorCLI"]
        ),
        .testTarget(
            name: "ThemeKitTests",
            dependencies: ["ThemeKit"]
        ),
        .testTarget(
            name: "ThemeKitGeneratorTests",
            dependencies: ["ThemeKitGenerator"]
        ),
    ]
)
