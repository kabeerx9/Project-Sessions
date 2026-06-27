import Foundation
import Observation

enum CommandRunStatus: String {
    case idle
    case running
    case exited
    case failed
    case stopped
    case terminalOpened
}

@MainActor
@Observable
final class CommandRunStore {
    private(set) var runs: [CommandRun] = []
    var selectedRunID: CommandRun.ID?

    @ObservationIgnored private let processRegistry: CommandProcessRegistry
    @ObservationIgnored private var shellEnvironment: [String: String]?

    init(processRegistry: CommandProcessRegistry) {
        self.processRegistry = processRegistry
    }

    func runs(for session: ProjectSession) -> [CommandRun] {
        runs.filter { $0.sessionID == session.id }
    }

    func run(for command: WorkspaceCommand, in session: ProjectSession) -> CommandRun? {
        runs.first { $0.sessionID == session.id && $0.commandID == command.id }
    }

    func selectedRun(for session: ProjectSession) -> CommandRun? {
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

    func terminalTTYs(for session: ProjectSession) -> [String] {
        runs(for: session).compactMap(\.terminalTTY)
    }

    func startAll(for session: ProjectSession) {
        guard !session.repositoryPath.isEmpty else {
            return
        }

        for command in session.commands {
            start(command, for: session)
        }
    }

    func start(_ command: WorkspaceCommand, for session: ProjectSession) {
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

        let run = CommandRun(
            sessionID: session.id,
            commandID: command.id,
            title: displayName(for: command),
            command: command.command,
            workingDirectory: session.repositoryPath,
            processRegistry: processRegistry
        )

        runs.append(run)
        selectedRunID = run.id

        if command.launchMode == .interactiveTerminal {
            run.openInteractiveTerminal()
            return
        }

        run.start(environment: resolvedShellEnvironment())
    }

    func stop(_ run: CommandRun) {
        run.stop()
    }

    func restart(_ run: CommandRun, for session: ProjectSession) {
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

    private func displayName(for command: WorkspaceCommand) -> String {
        command.name.isEmpty ? command.command : command.name
    }
}

@MainActor
@Observable
final class CommandRun: Identifiable {
    let id = UUID()
    let sessionID: ProjectSession.ID
    let commandID: WorkspaceCommand.ID
    let title: String
    let command: String
    let workingDirectory: String
    private let processRegistry: CommandProcessRegistry

    private(set) var status: CommandRunStatus = .idle
    private(set) var pid: Int32?
    private(set) var terminalTTY: String?
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
        commandID: WorkspaceCommand.ID,
        title: String,
        command: String,
        workingDirectory: String,
        processRegistry: CommandProcessRegistry
    ) {
        self.sessionID = sessionID
        self.commandID = commandID
        self.title = title
        self.command = command
        self.workingDirectory = workingDirectory
        self.processRegistry = processRegistry
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
            processRegistry.register(
                sessionID: sessionID,
                commandID: commandID,
                pid: process.processIdentifier,
                command: command,
                workingDirectory: workingDirectory
            )
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
        ProcessTree.terminate(process.processIdentifier)
    }

    func clearOutput() {
        output = ""
    }

    func openInteractiveTerminal() {
        guard !isRunning else {
            return
        }

        let result = TerminalLauncher.openTerminal(
            at: workingDirectory,
            title: terminalTitle
        )
        terminalTTY = result.tty
        status = result.didOpen ? .terminalOpened : .failed
        append(
            """
            $ \(command)

            [Project Sessions] Opened Terminal.app at \(workingDirectory).
            [Project Sessions] Terminal title: \(terminalTitle)
            [Project Sessions] Terminal TTY: \(terminalTTY ?? "Unknown")
            [Project Sessions] Running the saved command in Terminal.app is the next step.

            """
        )
    }

    private var terminalTitle: String {
        TerminalLauncher.title(
            sessionID: sessionID,
            commandID: commandID,
            displayTitle: title
        )
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
        processRegistry.unregister(pid: pid)
        closePipes()
        process = nil
    }

    private func closePipes() {
        outputPipe?.fileHandleForReading.readabilityHandler = nil
        errorPipe?.fileHandleForReading.readabilityHandler = nil
        outputPipe = nil
        errorPipe = nil
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
