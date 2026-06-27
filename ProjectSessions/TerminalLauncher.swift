import AppKit
import Foundation

enum TerminalLauncher {
    static func openTerminal(at workingDirectory: String, title: String) -> Bool {
        let terminalCommand = "cd \(shellQuoted(expandedPath(workingDirectory)))"
        let script = """
        tell application "Terminal"
            set newTab to do script \(appleScriptQuoted(terminalCommand))
            set custom title of newTab to \(appleScriptQuoted(title))
            activate
        end tell
        """

        return runAppleScript(script)
    }

    private static func runAppleScript(_ script: String) -> Bool {
        var error: NSDictionary?
        let appleScript = NSAppleScript(source: script)
        appleScript?.executeAndReturnError(&error)

        if let error {
            showLaunchAlert(
                title: "Could Not Open Terminal",
                message: error.description
            )
            return false
        }

        return true
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
