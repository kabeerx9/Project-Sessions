import AppKit

enum CommandClipboard {
    static func copyCommands(for session: ProjectSession) {
        let commandsText = session.commands.joined(separator: "\n")

        guard !commandsText.isEmpty else {
            return
        }

        copy(commandsText)
    }

    static func copyRepositoryPathAndCommands(for session: ProjectSession) {
        guard !session.commands.isEmpty else {
            return
        }

        let expandedRepositoryPath = expandedPath(session.repositoryPath)
        let cdCommand = "cd \(shellQuoted(expandedRepositoryPath))"
        let commandsText = ([cdCommand] + session.commands).joined(separator: "\n")

        copy(commandsText)
    }

    static func copyShellChain(for session: ProjectSession) {
        guard !session.commands.isEmpty else {
            return
        }

        let expandedRepositoryPath = expandedPath(session.repositoryPath)
        let cdCommand = "cd \(shellQuoted(expandedRepositoryPath))"
        let commandsText = ([cdCommand] + session.commands).joined(separator: " && ")

        copy(commandsText)
    }

    private static func copy(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
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
}
