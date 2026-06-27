import AppKit
import Foundation

struct TerminalLaunchResult {
    let didOpen: Bool
    let tty: String?
}

enum TerminalLauncher {
    static func title(
        sessionID: ProjectSession.ID,
        commandID: WorkspaceCommand.ID,
        displayTitle: String
    ) -> String {
        "\(titlePrefix(for: sessionID)) [\(commandID.uuidString)] \(displayTitle)"
    }

    static func closeTerminals(ttys: [String]) -> Bool {
        let normalizedTTYs = ttys
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !normalizedTTYs.isEmpty else {
            return true
        }

        let script = """
        set targetTTYs to {\(appleScriptList(normalizedTTYs))}

        if application "Terminal" is running then
            tell application "Terminal"
                repeat with windowIndex from (count of windows) to 1 by -1
                    set terminalWindow to window windowIndex
                    repeat with tabIndex from (count of tabs of terminalWindow) to 1 by -1
                        set terminalTab to tab tabIndex of terminalWindow
                        set tabTTY to ""

                        try
                            set tabTTY to tty of terminalTab as text
                        end try

                        if targetTTYs contains tabTTY then
                            close terminalTab saving no
                        end if
                    end repeat
                end repeat
            end tell
        end if
        """

        return runAppleScriptString(
            script,
            alertTitle: "Could Not Close Terminal Tabs"
        ) != nil
    }

    static func openTerminal(at workingDirectory: String, title: String) -> TerminalLaunchResult {
        let terminalCommand = "cd \(shellQuoted(expandedPath(workingDirectory)))"

        let script = """
        tell application "Terminal"
            set newTab to do script \(appleScriptQuoted(terminalCommand))
            set custom title of newTab to \(appleScriptQuoted(title))
            activate

            try
                return tty of newTab as text
            on error
                return ""
            end try
        end tell
        """

        guard let tty = runAppleScriptString(script) else {
            return TerminalLaunchResult(didOpen: false, tty: nil)
        }

        let trimmedTTY = tty.trimmingCharacters(in: .whitespacesAndNewlines)
        return TerminalLaunchResult(
            didOpen: true,
            tty: trimmedTTY.isEmpty ? nil : trimmedTTY
        )
    }

    private static func titlePrefix(for sessionID: ProjectSession.ID) -> String {
        "Project Sessions [\(sessionID.uuidString)]"
    }

    private static func runAppleScriptString(
        _ script: String,
        alertTitle: String = "Could Not Open Terminal"
    ) -> String? {
        var error: NSDictionary?
        let appleScript = NSAppleScript(source: script)
        let result = appleScript?.executeAndReturnError(&error)

        if let error {
            showLaunchAlert(
                title: alertTitle,
                message: error.description
            )
            return nil
        }

        return result?.stringValue ?? ""
    }

    private static func expandedPath(_ path: String) -> String {
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

    private static func shellQuoted(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
    }

    private static func appleScriptQuoted(_ value: String) -> String {
        let escapedValue = value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")

        return "\"\(escapedValue)\""
    }

    private static func appleScriptList(_ values: [String]) -> String {
        values.map(appleScriptQuoted).joined(separator: ", ")
    }

    private static func showLaunchAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = title
            alert.informativeText = message
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
}
