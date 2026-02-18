import PackagePlugin
import Foundation

@main
struct ThemeKitPlugin: CommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        var extractor = ArgumentExtractor(arguments)
        let configArg = extractor.extractOption(named: "config").first ?? "theme.json"
        let outputArg = extractor.extractOption(named: "output").first

        let configPath = context.package.directoryURL.appendingPathComponent(configArg).path()
        let outputPath = outputArg ?? context.package.directoryURL.path()

        let tool = try context.tool(named: "ThemeKitGeneratorCLI")

        let process = Process()
        process.executableURL = tool.url
        process.arguments = ["--config", configPath, "--output", outputPath]

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            Diagnostics.error("ThemeKitGeneratorCLI exited with status \(process.terminationStatus)")
            return
        }
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension ThemeKitPlugin: XcodeCommandPlugin {
    func performCommand(context: XcodePluginContext, arguments: [String]) throws {
        var extractor = ArgumentExtractor(arguments)
        let configArg = extractor.extractOption(named: "config").first ?? "theme.json"
        let outputArg = extractor.extractOption(named: "output").first

        let configPath = context.xcodeProject.directoryURL.appendingPathComponent(configArg).path()
        let outputPath = outputArg ?? context.xcodeProject.directoryURL.path()

        let tool = try context.tool(named: "ThemeKitGeneratorCLI")

        let process = Process()
        process.executableURL = tool.url
        process.arguments = ["--config", configPath, "--output", outputPath]

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            Diagnostics.error("ThemeKitGeneratorCLI exited with status \(process.terminationStatus)")
            return
        }
    }
}
#endif
