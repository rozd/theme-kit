import Foundation
import ThemeKitGenerator

func run() throws {
    let args = CommandLine.arguments

    var configPath = "theme.json"
    var outputPath = "."
    var skipDefaults = false

    var i = 1
    while i < args.count {
        switch args[i] {
        case "--config":
            i += 1
            guard i < args.count else {
                throw GeneratorError.missingArgument("--config")
            }
            configPath = args[i]
        case "--output":
            i += 1
            guard i < args.count else {
                throw GeneratorError.missingArgument("--output")
            }
            outputPath = args[i]
        case "--skip-defaults":
            skipDefaults = true
        default:
            break
        }
        i += 1
    }

    let configURL = URL(fileURLWithPath: configPath)
    guard FileManager.default.fileExists(atPath: configURL.path) else {
        throw GeneratorError.configNotFound(configPath)
    }

    let data = try Data(contentsOf: configURL)
    let result = try ThemeFileGenerator().generate(fromJSON: data)

    // Combine base output path with config's relative path
    let baseURL = URL(fileURLWithPath: outputPath)
    let finalOutputURL = baseURL.appendingPathComponent(result.outputPath)

    try FileManager.default.createDirectory(at: finalOutputURL, withIntermediateDirectories: true)

    let filesToWrite = skipDefaults ? result.files.filter { $0.name != "Theme+Defaults.swift" } : result.files

    for file in filesToWrite {
        let fileURL = finalOutputURL.appendingPathComponent(file.name)
        try file.content.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    print("ThemeKit: Generated \(filesToWrite.count) files in \(finalOutputURL.path):")
    for file in filesToWrite {
        print("  - \(file.name)")
    }
}

nonisolated enum GeneratorError: Error, CustomStringConvertible {
    case missingArgument(String)
    case configNotFound(String)

    nonisolated var description: String {
        switch self {
        case .missingArgument(let flag):
            "Missing value for \(flag)"
        case .configNotFound(let path):
            "Config file not found: \(path)"
        }
    }
}

do {
    try run()
} catch {
    print("Error: \(error)")
    Foundation.exit(1)
}
