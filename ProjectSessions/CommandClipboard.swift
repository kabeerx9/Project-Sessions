import AppKit

enum CommandClipboard {
    static func copyCommands(for session: ProjectSession) {
        let commandsText = session.commands.joined(separator: "\n")

        guard !commandsText.isEmpty else {
            return
        }

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(commandsText, forType: .string)
    }
}
