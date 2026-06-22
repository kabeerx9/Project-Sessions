import Foundation
import Observation

enum ExperimentalCommandStatus: String {
    case idle
    case running
    case exited
    case failed
    case stopped
}

@MainActor
@Observable
final class ExperimentalCommandRunner {
    private(set) var title = ""
    private(set) var command = ""
    private(set) var status: ExperimentalCommandStatus = .idle
    private(set) var pid: Int32?
    private(set) var exitCode: Int32?
    private(set) var output = ""

    @ObservationIgnored private var process: Process?
    @ObservationIgnored private var outputPipe: Pipe?
    @ObservationIgnored private var errorPipe: Pipe?
    @ObservationIgnored private var shellEnvironment: [String: String]?

    var isRunning: Bool {
        status == .running
    }

    func start(title: String, command: String, workingDirectory: String) {
        guard !isRunning else {
            return
        }

        reset(title: title, command: command)

        let process = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        let environment = resolvedShellEnvironment()

        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-lc", command]
        process.currentDirectoryURL = URL(fileURLWithPath: expandedPath(workingDirectory))
        process.environment = environment
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        outputPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData

            guard !data.isEmpty else {
                return
            }

            let text = String(data: data, encoding: .utf8) ?? ""

            DispatchQueue.main.async { [weak self] in
                self?.append(text)
            }
        }

        errorPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData

            guard !data.isEmpty else {
                return
            }

            let text = String(data: data, encoding: .utf8) ?? ""

            DispatchQueue.main.async { [weak self] in
                self?.append(text)
            }
        }

        process.terminationHandler = { [weak self] process in
            let exitCode = process.terminationStatus

            DispatchQueue.main.async { [weak self] in
                self?.finish(exitCode: exitCode)
            }
        }

        do {
            try process.run()
            self.process = process
            self.outputPipe = outputPipe
            self.errorPipe = errorPipe
            self.pid = process.processIdentifier
            self.status = .running
            append("$ \(command)\n\n")
        } catch {
            status = .failed
            append("Could not start command: \(error.localizedDescription)\n")
            closePipes()
        }
    }

    func stop() {
        guard let process, process.isRunning else {
            return
        }

        status = .stopped
        terminateProcessTree(process.processIdentifier)
    }

    private func reset(title: String, command: String) {
        self.title = title
        self.command = command
        status = .idle
        pid = nil
        exitCode = nil
        output = ""
        closePipes()
        process = nil
    }

    private func append(_ text: String) {
        output += text

        if output.count > 40_000 {
            output.removeFirst(output.count - 40_000)
        }
    }

    private func finish(exitCode: Int32) {
        self.exitCode = exitCode

        if status != .stopped {
            status = exitCode == 0 ? .exited : .failed
        }

        append("\n[Project Sessions] command finished with exit status \(exitCode)\n")
        closePipes()
        process = nil
    }

    private func closePipes() {
        outputPipe?.fileHandleForReading.readabilityHandler = nil
        errorPipe?.fileHandleForReading.readabilityHandler = nil
        outputPipe = nil
        errorPipe = nil
    }

    private func terminateProcessTree(_ pid: Int32) {
        for childPID in childPIDs(of: pid) {
            terminateProcessTree(childPID)
        }

        kill(pid, SIGTERM)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if kill(pid, 0) == 0 {
                kill(pid, SIGKILL)
            }
        }
    }

    private func childPIDs(of pid: Int32) -> [Int32] {
        let process = Process()
        let output = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
        process.arguments = ["-P", String(pid)]
        process.standardOutput = output

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return []
        }

        let data = output.fileHandleForReading.readDataToEndOfFile()
        let contents = String(data: data, encoding: .utf8) ?? ""

        return contents
            .split(separator: "\n")
            .compactMap { Int32($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
    }

    private func resolvedShellEnvironment() -> [String: String] {
        if let shellEnvironment {
            return shellEnvironment
        }

        let environment = ShellEnvironmentResolver.resolve()
        shellEnvironment = environment
        return environment
    }

    private func expandedPath(_ path: String) -> String {
        let trimmedPath = path.trimmingCharacters(in: .whitespacesAndNewlines)
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser.path

        if trimmedPath.hasPrefix("~/") {
            return homeDirectory + trimmedPath.dropFirst()
        }

        if trimmedPath.hasPrefix("/") {
            return trimmedPath
        }

        return "\(homeDirectory)/\(trimmedPath)"
    }
}
