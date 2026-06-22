import Foundation
import Observation

@Observable
class TerminalProcessStore {
    private(set) var records: [TerminalProcessRecord] = []

    private let recordsKey = "terminalProcessRecords.v2"

    init() {
        loadRecords()
        refresh()
    }

    func records(for session: ProjectSession) -> [TerminalProcessRecord] {
        records.filter { $0.sessionID == session.id }
    }

    func runningCount(for session: ProjectSession) -> Int {
        records(for: session).filter { $0.status == .running || $0.status == .launching }.count
    }

    func track(_ record: TerminalProcessRecord) {
        records.append(record)
        saveRecords()
    }

    func refresh() {
        var didChange = false

        for index in records.indices {
            let oldRecord = records[index]
            var record = oldRecord

            if record.status == .stopped {
                continue
            }

            if FileManager.default.fileExists(atPath: record.exitFilePath) {
                record.status = .exited
            } else if let pid = record.pid ?? readPID(from: record.pidFilePath) {
                record.pid = pid
                record.status = isProcessAlive(pid) ? .running : .exited
            } else {
                record.status = .launching
            }

            if record != oldRecord {
                records[index] = record
                didChange = true
            }
        }

        if didChange {
            saveRecords()
        }
    }

    func stopProcesses(for session: ProjectSession) {
        refresh()

        for index in records.indices where records[index].sessionID == session.id {
            guard records[index].status == .running || records[index].status == .launching else {
                continue
            }

            if let pid = records[index].pid ?? readPID(from: records[index].pidFilePath) {
                terminateProcessTree(pid)
            }

            records[index].status = .stopped
        }

        saveRecords()
    }

    private func readPID(from path: String) -> Int32? {
        guard let contents = try? String(contentsOfFile: path, encoding: .utf8) else {
            return nil
        }

        return Int32(contents.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private func isProcessAlive(_ pid: Int32) -> Bool {
        kill(pid, 0) == 0
    }

    private func terminateProcessTree(_ pid: Int32) {
        for childPID in childPIDs(of: pid) {
            terminateProcessTree(childPID)
        }

        kill(pid, SIGTERM)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if self.isProcessAlive(pid) {
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

    private func saveRecords() {
        do {
            let data = try JSONEncoder().encode(records)
            UserDefaults.standard.set(data, forKey: recordsKey)
        } catch {
            print("Failed to save terminal process records: \(error)")
        }
    }

    private func loadRecords() {
        guard let data = UserDefaults.standard.data(forKey: recordsKey) else {
            return
        }

        do {
            records = try JSONDecoder().decode([TerminalProcessRecord].self, from: data)
        } catch {
            print("Failed to load terminal process records: \(error)")
        }
    }
}
