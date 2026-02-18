import PackagePlugin
import Foundation

@main
struct ThemeKitPlugin: CommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        var extractor = ArgumentExtractor(arguments)
        let configArg = extractor.extractOption(named: "config").first ?? "theme.json"
        let outputArg = extractor.extractOption(named: "output").first

        let selectedTargets = extractor.extractOption(named: "target")
        let target = selectedTargets.first.flatMap { name in
            context.package.targets.first { $0.name == name }
        }

        let rootDir = context.package.directoryURL
        let targetDir = target?.directoryURL
        let configPath = resolveConfig(named: configArg, targetDir: targetDir, rootDir: rootDir)
        let outputPath = outputArg ?? targetDir?.path() ?? rootDir.path()

        let tool = try context.tool(named: "ThemeKitGeneratorCLI")
        try run(tool: tool.url, config: configPath, output: outputPath)
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension ThemeKitPlugin: XcodeCommandPlugin {
    func performCommand(context: XcodePluginContext, arguments: [String]) throws {
        var extractor = ArgumentExtractor(arguments)
        let configArg = extractor.extractOption(named: "config").first ?? "theme.json"
        let outputArg = extractor.extractOption(named: "output").first

        let selectedTargets = extractor.extractOption(named: "target")
        let projectDir = context.xcodeProject.directoryURL

        // Xcode targets don't expose a source directory — use convention: projectDir/targetName/
        let targetDir = selectedTargets.first.map { projectDir.appendingPathComponent($0) }

        let configPath = resolveConfig(named: configArg, targetDir: targetDir, rootDir: projectDir)
        let outputPath = outputArg ?? targetDir?.path() ?? projectDir.path()

        let tool = try context.tool(named: "ThemeKitGeneratorCLI")
        try run(tool: tool.url, config: configPath, output: outputPath)
    }
}
#endif

extension ThemeKitPlugin {
    func resolveConfig(named configArg: String, targetDir: URL?, rootDir: URL) -> String {
        // Check target directory first, then project root
        if let targetDir {
            let targetPath = targetDir.appendingPathComponent(configArg).path()
            if FileManager.default.fileExists(atPath: targetPath) {
                return targetPath
            }
        }
        return rootDir.appendingPathComponent(configArg).path()
    }

    func run(tool: URL, config: String, output: String) throws {
        guard FileManager.default.fileExists(atPath: config) else {
            Diagnostics.error("""
                Config file not found: \(config)
                Create a theme.json in your project root. Example:
                {
                  "styles": {
                    "colors": ["surface", {"name": "primary", "style": "primaryColor"}],
                    "gradients": ["primary"]
                  },
                  "config": {
                    "outputPath": "."
                  }
                }
                """)
            throw PluginError.configNotFound(config)
        }

        let pipe = Pipe()

        let process = Process()
        process.executableURL = tool
        process.arguments = ["--config", config, "--output", output]
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let message = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if process.terminationStatus != 0 {
            Diagnostics.error(message.isEmpty ? "Generation failed with exit code \(process.terminationStatus)" : message)
            throw PluginError.generationFailed(message)
        }

        if !message.isEmpty {
            Diagnostics.remark(message)
        }
    }
}

enum PluginError: Error, CustomStringConvertible {
    case configNotFound(String)
    case generationFailed(String)

    var description: String {
        switch self {
        case .configNotFound(let path):
            "Config file not found: \(path)"
        case .generationFailed(let detail):
            "Theme generation failed: \(detail)"
        }
    }
}
