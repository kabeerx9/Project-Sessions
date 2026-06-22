import Foundation

struct TerminalCommand: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var command: String
    var runsInSeparateTerminal: Bool

    init(
        id: UUID = UUID(),
        name: String = "",
        command: String,
        runsInSeparateTerminal: Bool = true
    ) {
        self.id = id
        self.name = name
        self.command = command
        self.runsInSeparateTerminal = runsInSeparateTerminal
    }
}
