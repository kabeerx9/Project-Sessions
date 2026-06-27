import Foundation

enum WorkspaceCommandLaunchMode: String, Codable, Hashable {
    case appConsole
    case interactiveTerminal
}

struct WorkspaceCommand: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var command: String
    var launchMode: WorkspaceCommandLaunchMode

    init(
        id: UUID = UUID(),
        name: String = "",
        command: String,
        launchMode: WorkspaceCommandLaunchMode = .appConsole
    ) {
        self.id = id
        self.name = name
        self.command = command
        self.launchMode = launchMode
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case command
        case launchMode
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        command = try container.decode(String.self, forKey: .command)
        launchMode = try container.decodeIfPresent(WorkspaceCommandLaunchMode.self, forKey: .launchMode) ?? .appConsole
    }
}
