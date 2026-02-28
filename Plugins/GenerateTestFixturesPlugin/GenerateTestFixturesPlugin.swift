import PackagePlugin
import Foundation

@main
struct GenerateTestFixturesPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        guard let sourceModule = target as? SourceModuleTarget else { return [] }

        let configFile = sourceModule.sourceFiles.first { $0.url.lastPathComponent == "theme.json" }
        guard let configFile else {
            Diagnostics.error("No theme.json found in target \(target.name)")
            return []
        }

        let tool = try context.tool(named: "ThemeKitGeneratorCLI")
        let outputDir = context.pluginWorkDirectoryURL
        let outputFiles = try computeOutputFiles(configURL: configFile.url, outputDir: outputDir)

        return [
            .buildCommand(
                displayName: "Generate ThemeKit fixtures for \(target.name)",
                executable: tool.url,
                arguments: [
                    "--config", configFile.url.path(),
                    "--output", outputDir.path(),
                    "--skip-defaults",
                ],
                inputFiles: [configFile.url],
                outputFiles: outputFiles
            ),
        ]
    }

    /// Parses theme.json minimally to compute the list of files the generator will produce.
    private func computeOutputFiles(configURL: URL, outputDir: URL) throws -> [URL] {
        let data = try Data(contentsOf: configURL)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        let styles = json["styles"] as? [String: Any] ?? [:]
        let config = json["config"] as? [String: Any] ?? [:]

        let categoryKeys = styles.keys
        let shouldGeneratePreview = config["shouldGeneratePreview"] as? Bool ?? false

        // Map JSON category keys to struct names
        let categoryStructNames: [String: String] = [
            "colors": "ThemeColors",
            "gradients": "ThemeGradients",
            "meshGradients": "ThemeMeshGradients",
            "shadows": "ThemeShadows",
        ]

        var files: [String] = []

        // Static files (always generated)
        files.append("ThemeShapeStyle.swift")
        files.append("Environment+Theme.swift")
        files.append("Theme.swift")
        files.append("Theme+CopyWith.swift")

        // Conditional: ThemeShadowedStyle only when shadows present
        if categoryKeys.contains("shadows") {
            files.append("ThemeShadowedStyle.swift")
        }

        // Per-category files
        for key in categoryKeys {
            guard let structName = categoryStructNames[key] else { continue }
            files.append("\(structName).swift")
            files.append("\(structName)+CopyWith.swift")
            files.append("ShapeStyle+\(structName).swift")
        }

        // Optional preview file
        if shouldGeneratePreview {
            files.append("Theme+Preview.swift")
        }

        return files.map { outputDir.appendingPathComponent($0) }
    }
}
