import Foundation

struct TerminalCommand: Identifiable, Codable, Hashable {
    let id: UUID
    var command: String

    init(id: UUID = UUID(), command: String) {
        self.id = id
        self.command = command
    }
}
