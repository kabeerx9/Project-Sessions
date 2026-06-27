import Foundation

struct CommandProcessRecord: Identifiable, Codable, Hashable {
    let id: UUID
    let sessionID: ProjectSession.ID
    let commandID: WorkspaceCommand.ID
    let pid: Int32
    let processStartSignature: String
    let command: String
    let workingDirectory: String
    let startedAt: Date

    init(
        id: UUID = UUID(),
        sessionID: ProjectSession.ID,
        commandID: WorkspaceCommand.ID,
        pid: Int32,
        processStartSignature: String,
        command: String,
        workingDirectory: String,
        startedAt: Date = Date()
    ) {
        self.id = id
        self.sessionID = sessionID
        self.commandID = commandID
        self.pid = pid
        self.processStartSignature = processStartSignature
        self.command = command
        self.workingDirectory = workingDirectory
        self.startedAt = startedAt
    }
}

final class CommandProcessRegistry {
    private(set) var records: [CommandProcessRecord] = []

    private let recordsKey = "commandProcessRecords.v1"

    init() {
        loadRecords()
    }

    func register(
        sessionID: ProjectSession.ID,
        commandID: WorkspaceCommand.ID,
        pid: Int32,
        command: String,
        workingDirectory: String
    ) {
        let record = CommandProcessRecord(
            sessionID: sessionID,
            commandID: commandID,
            pid: pid,
            processStartSignature: ProcessTree.startSignature(for: pid),
            command: command,
            workingDirectory: workingDirectory
        )

        records.removeAll {
            $0.pid == pid || ($0.sessionID == sessionID && $0.commandID == commandID)
        }
        records.append(record)
        saveRecords()
    }

    func unregister(pid: Int32?) {
        guard let pid else {
            return
        }

        records.removeAll { $0.pid == pid }
        saveRecords()
    }

    func stopAllRegisteredProcesses(forceImmediately: Bool = false) {
        stopRegisteredProcesses(records, forceImmediately: forceImmediately)
    }

    func sweepOrphanedProcessesOnLaunch() {
        stopRegisteredProcesses(records, forceImmediately: true)
    }

    private func stopRegisteredProcesses(_ recordsToStop: [CommandProcessRecord], forceImmediately: Bool) {
        for record in recordsToStop where isSameProcess(record) {
            ProcessTree.terminate(record.pid, forceImmediately: forceImmediately)
        }

        records.removeAll { record in
            recordsToStop.contains { $0.id == record.id }
        }
        saveRecords()
    }

    private func isSameProcess(_ record: CommandProcessRecord) -> Bool {
        guard ProcessTree.isRunning(record.pid) else {
            return false
        }

        let currentSignature = ProcessTree.startSignature(for: record.pid)
        return !currentSignature.isEmpty && currentSignature == record.processStartSignature
    }

    private func saveRecords() {
        do {
            let data = try JSONEncoder().encode(records)
            UserDefaults.standard.set(data, forKey: recordsKey)
        } catch {
            print("Failed to save command process records: \(error)")
        }
    }

    private func loadRecords() {
        guard let data = UserDefaults.standard.data(forKey: recordsKey) else {
            return
        }

        do {
            records = try JSONDecoder().decode([CommandProcessRecord].self, from: data)
        } catch {
            print("Failed to load command process records: \(error)")
        }
    }
}
