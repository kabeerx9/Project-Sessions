import Foundation

enum ProcessTree {
    static func terminate(_ pid: Int32, forceImmediately: Bool = false) {
        for childPID in childPIDs(of: pid) {
            terminate(childPID, forceImmediately: forceImmediately)
        }

        kill(pid, SIGTERM)

        if forceImmediately {
            usleep(200_000)

            if isRunning(pid) {
                kill(pid, SIGKILL)
            }

            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if isRunning(pid) {
                kill(pid, SIGKILL)
            }
        }
    }

    static func isRunning(_ pid: Int32) -> Bool {
        kill(pid, 0) == 0
    }

    static func startSignature(for pid: Int32) -> String {
        processOutput(arguments: ["-p", String(pid), "-o", "lstart="])
    }

    private static func childPIDs(of pid: Int32) -> [Int32] {
        processOutput(arguments: ["-P", String(pid)])
            .split(separator: "\n")
            .compactMap { Int32($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
    }

    private static func processOutput(arguments: [String]) -> String {
        let process = Process()
        let output = Pipe()

        process.executableURL = URL(fileURLWithPath: arguments.first == "-P" ? "/usr/bin/pgrep" : "/bin/ps")
        process.arguments = arguments
        process.standardOutput = output

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return ""
        }

        let data = output.fileHandleForReading.readDataToEndOfFile()
        return (String(data: data, encoding: .utf8) ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
