import Foundation

struct WorkspaceCommand: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var command: String

    init(
        id: UUID = UUID(),
        name: String = "",
        command: String
    ) {
        self.id = id
        self.name = name
        self.command = command
    }
}
