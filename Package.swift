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
            type: .dynamic,
            targets: ["ThemeKit"]
        ),
        .plugin(
            name: "Generate Theme Files",
            targets: ["Generate Theme Files"]
        ),
    ],
    dependencies: [
        .package(url: "https://source.skip.tools/skip.git", from: "1.9.5"),
        .package(url: "https://source.skip.tools/skip-fuse-ui.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "ThemeKit",
            dependencies: [
                .product(name: "SkipFuseUI", package: "skip-fuse-ui")
            ],
            plugins: [.plugin(name: "skipstone", package: "skip")]
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

// Setting the SKIP_ZERO=1 environment strips the Skip plugin and all Skip dependencies,
// restoring a plain SwiftPM package for Apple-only consumers.
if Context.environment["SKIP_ZERO"] ?? "0" != "0" {
    package.targets.forEach { target in
        target.plugins?.removeAll(where: {
            if case .plugin(let name, _) = $0 {
                return name == "skipstone"
            } else {
                return false
            }
        })

        target.dependencies.removeAll(where: { dependency in
            if case .productItem(_, let package, _, _) = dependency {
                return package == "skip" || package?.hasPrefix("skip-") == true
            } else {
                return false
            }
        })
    }

    package.dependencies.removeAll(where: { dependency in
        if case .sourceControl(_, let url, _) = dependency.kind {
            return url.hasPrefix("https://source.skip.dev/") || url.hasPrefix("https://source.skip.tools/")
        } else {
            return false
        }
    })

    // Restore the default (automatic) library type — dynamic is only needed for Android/JNI loading.
    package.products = [
        .library(name: "ThemeKit", targets: ["ThemeKit"]),
        .plugin(name: "Generate Theme Files", targets: ["Generate Theme Files"]),
    ]
}

// Setting SKIP_DEPENDENCY_ROOT to a directory of local Skip checkouts points every Skip
// dependency at those working copies, for developing against unreleased Skip changes.
//
// The rewrite is deliberately all-or-nothing: skip-fuse-ui's own manifest reads the same
// variable and redirects every dependency whose name begins with "skip", so redirecting only
// some of them here would leave two different declarations of the same package identity and
// fail resolution outright.
//
// This runs last on purpose. The SKIP_ZERO block above matches on `.sourceControl`, and would
// no longer recognise these dependencies once they had become `.fileSystem`.
//
// No fork URL appears anywhere in this manifest — only local paths, and only when the variable
// is set — so nothing can leak into a consumer's Package.resolved.
if Context.environment["SKIP_ZERO"] ?? "0" == "0",
   let dependencyRoot = Context.environment["SKIP_DEPENDENCY_ROOT"] {
    package.dependencies = package.dependencies.map { dependency in
        guard case .sourceControl(_, let url, _) = dependency.kind,
              let name = url.split(separator: "/").last?.split(separator: ".").first,
              name.hasPrefix("skip") else {
            return dependency
        }
        return .package(path: "\(dependencyRoot)/\(name)")
    }

    // A root package's path dependencies override transitive declarations of the same identity,
    // so the Skip packages this manifest never names directly have to be pinned here too.
    package.dependencies.append(.package(path: "\(dependencyRoot)/skip-model"))
}
