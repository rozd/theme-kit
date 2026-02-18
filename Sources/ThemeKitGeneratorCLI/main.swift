import Foundation
import ThemeKitGenerator

func run() throws {
    let args = CommandLine.arguments

    var configPath = "theme.json"
    var outputPath = "."

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
    let files = try ThemeFileGenerator().generate(fromJSON: data)

    let outputURL = URL(fileURLWithPath: outputPath)
    try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)

    for file in files {
        let fileURL = outputURL.appendingPathComponent(file.name)
        try file.content.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    print("ThemeKit: Generated \(files.count) files in \(outputPath):")
    for file in files {
        print("  - \(file.name)")
    }
}

enum GeneratorError: Error, CustomStringConvertible {
    case missingArgument(String)
    case configNotFound(String)

    var description: String {
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
