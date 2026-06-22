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
final class ExperimentalCommandRunStore {
    private(set) var runs: [ExperimentalCommandRun] = []
    var selectedRunID: ExperimentalCommandRun.ID?

    @ObservationIgnored private var shellEnvironment: [String: String]?

    func runs(for session: ProjectSession) -> [ExperimentalCommandRun] {
        runs.filter { $0.sessionID == session.id }
    }

    func selectedRun(for session: ProjectSession) -> ExperimentalCommandRun? {
        let sessionRuns = runs(for: session)

        if let selectedRunID,
           let selectedRun = sessionRuns.first(where: { $0.id == selectedRunID }) {
            return selectedRun
        }

        return sessionRuns.first
    }

    func runningCount(for session: ProjectSession) -> Int {
        runs(for: session).filter(\.isRunning).count
    }

    func startAll(for session: ProjectSession) {
        guard !session.repositoryPath.isEmpty else {
            return
        }

        for command in session.commands {
            start(command, for: session)
        }
    }

    func start(_ command: TerminalCommand, for session: ProjectSession) {
        guard !session.repositoryPath.isEmpty else {
            return
        }

        if let existingRun = runs.first(where: { $0.sessionID == session.id && $0.commandID == command.id }) {
            if existingRun.isRunning {
                selectedRunID = existingRun.id
                return
            }

            runs.removeAll { $0.id == existingRun.id }
        }

        let run = ExperimentalCommandRun(
            sessionID: session.id,
            commandID: command.id,
            title: displayName(for: command),
            command: command.command,
            workingDirectory: session.repositoryPath
        )

        runs.append(run)
        selectedRunID = run.id
        run.start(environment: resolvedShellEnvironment())
    }

    func stop(_ run: ExperimentalCommandRun) {
        run.stop()
    }

    func restart(_ run: ExperimentalCommandRun, for session: ProjectSession) {
        guard let command = session.commands.first(where: { $0.id == run.commandID }) else {
            return
        }

        if run.isRunning {
            run.stop()
        }

        runs.removeAll { $0.id == run.id }
        selectedRunID = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.start(command, for: session)
        }
    }

    func stopAll(for session: ProjectSession) {
        for run in runs(for: session) where run.isRunning {
            run.stop()
        }
    }

    private func resolvedShellEnvironment() -> [String: String] {
        if let shellEnvironment {
            return shellEnvironment
        }

        let environment = ShellEnvironmentResolver.resolve()
        shellEnvironment = environment
        return environment
    }

    private func displayName(for command: TerminalCommand) -> String {
        command.name.isEmpty ? command.command : command.name
    }
}

@MainActor
@Observable
final class ExperimentalCommandRun: Identifiable {
    let id = UUID()
    let sessionID: ProjectSession.ID
    let commandID: TerminalCommand.ID
    let title: String
    let command: String
    let workingDirectory: String

    private(set) var status: ExperimentalCommandStatus = .idle
    private(set) var pid: Int32?
    private(set) var exitCode: Int32?
    private(set) var output = ""

    @ObservationIgnored private var process: Process?
    @ObservationIgnored private var outputPipe: Pipe?
    @ObservationIgnored private var errorPipe: Pipe?

    var isRunning: Bool {
        status == .running
    }

    init(
        sessionID: ProjectSession.ID,
        commandID: TerminalCommand.ID,
        title: String,
        command: String,
        workingDirectory: String
    ) {
        self.sessionID = sessionID
        self.commandID = commandID
        self.title = title
        self.command = command
        self.workingDirectory = workingDirectory
    }

    func start(environment: [String: String]) {
        guard !isRunning else {
            return
        }

        let process = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()

        self.outputPipe = outputPipe
        self.errorPipe = errorPipe

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
            pid = process.processIdentifier
            status = .running
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

    func clearOutput() {
        output = ""
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
