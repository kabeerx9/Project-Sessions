import Foundation

enum ShellEnvironmentResolver {
    static func resolve() -> [String: String] {
        let fallbackEnvironment = fallbackEnvironment()
        let process = Process()
        let outputPipe = Pipe()
        let markerStart = "__PROJECT_SESSIONS_ENV_START__"
        let markerEnd = "__PROJECT_SESSIONS_ENV_END__"
        let script = """
        printf '\\n\(markerStart)\\n'
        /usr/bin/env -0
        printf '\\n\(markerEnd)\\n'
        """

        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-l", "-i", "-c", script]
        process.environment = fallbackEnvironment
        process.standardOutput = outputPipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return fallbackEnvironment
        }

        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()

        guard process.terminationStatus == 0,
              let output = String(data: data, encoding: .utf8),
              let startRange = output.range(of: markerStart),
              let endRange = output.range(of: markerEnd) else {
            return fallbackEnvironment
        }

        let environmentBlock = output[startRange.upperBound..<endRange.lowerBound]
            .trimmingCharacters(in: .whitespacesAndNewlines)
        var resolvedEnvironment = fallbackEnvironment

        for entry in environmentBlock.split(separator: "\0", omittingEmptySubsequences: true) {
            guard let separatorIndex = entry.firstIndex(of: "=") else {
                continue
            }

            let key = String(entry[..<separatorIndex])
            let value = String(entry[entry.index(after: separatorIndex)...])
            resolvedEnvironment[key] = value
        }

        resolvedEnvironment["TERM"] = "xterm-256color"
        return resolvedEnvironment
    }

    private static func fallbackEnvironment() -> [String: String] {
        var environment = ProcessInfo.processInfo.environment
        let fallbackPath = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

        if let path = environment["PATH"], !path.isEmpty {
            environment["PATH"] = "\(fallbackPath):\(path)"
        } else {
            environment["PATH"] = fallbackPath
        }

        environment["TERM"] = "xterm-256color"
        return environment
    }
}
