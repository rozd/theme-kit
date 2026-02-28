// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ThemeKit",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .watchOS(.v11),
        .tvOS(.v18),
        .visionOS(.v2),
    ],
    products: [
        .library(
            name: "ThemeKit",
            targets: ["ThemeKit"]
        ),
        .plugin(
            name: "Generate Theme Files",
            targets: ["Generate Theme Files"]
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
            name: "Generate Theme Files",
            capability: .command(
                intent: .custom(verb: "generate-theme", description: "Generate Theme Files"),
                permissions: [.writeToPackageDirectory(reason: "Generates Swift theme files from theme.json")]
            ),
            dependencies: ["ThemeKitGeneratorCLI"],
            path: "Plugins/ThemeKitPlugin"
        ),
        .testTarget(
            name: "ThemeKitTests",
            dependencies: ["ThemeKit"]
        ),
        .testTarget(
            name: "ThemeKitGeneratorTests",
            dependencies: ["ThemeKitGenerator"]
        ),
        .plugin(
            name: "GenerateTestFixturesPlugin",
            capability: .buildTool(),
            dependencies: ["ThemeKitGeneratorCLI"],
            path: "Plugins/GenerateTestFixturesPlugin"
        ),
        // Generated code compilation verification targets
        .target(
            name: "GeneratedCodeSwift5",
            dependencies: ["ThemeKit"],
            path: "Tests/GeneratedCodeSwift5",
            swiftSettings: [.swiftLanguageMode(.v5)],
            plugins: [.plugin(name: "GenerateTestFixturesPlugin")]
        ),
        .target(
            name: "GeneratedCodeSwift5MainActor",
            dependencies: ["ThemeKit"],
            path: "Tests/GeneratedCodeSwift5MainActor",
            swiftSettings: [.swiftLanguageMode(.v5), .defaultIsolation(MainActor.self)],
            plugins: [.plugin(name: "GenerateTestFixturesPlugin")]
        ),
        .target(
            name: "GeneratedCodeSwift6",
            dependencies: ["ThemeKit"],
            path: "Tests/GeneratedCodeSwift6",
            swiftSettings: [.swiftLanguageMode(.v6)],
            plugins: [.plugin(name: "GenerateTestFixturesPlugin")]
        ),
        .target(
            name: "GeneratedCodeSwift6MainActor",
            dependencies: ["ThemeKit"],
            path: "Tests/GeneratedCodeSwift6MainActor",
            swiftSettings: [.swiftLanguageMode(.v6), .defaultIsolation(MainActor.self)],
            plugins: [.plugin(name: "GenerateTestFixturesPlugin")]
        ),
        .testTarget(
            name: "GeneratedCodeCompilationTests",
            dependencies: [
                "GeneratedCodeSwift5",
                "GeneratedCodeSwift5MainActor",
                "GeneratedCodeSwift6",
                "GeneratedCodeSwift6MainActor",
            ]
        ),
    ]
)
