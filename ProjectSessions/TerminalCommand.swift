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

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case command
        case runsInSeparateTerminal
        case runsInSeparateTab
    }

    init(from decoder: Decoder) throws {
        if let container = try? decoder.singleValueContainer(),
           let savedCommand = try? container.decode(String.self) {
            id = UUID()
            name = ""
            command = savedCommand
            runsInSeparateTerminal = true
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        command = try container.decode(String.self, forKey: .command)
        runsInSeparateTerminal = try container.decodeIfPresent(Bool.self, forKey: .runsInSeparateTerminal)
            ?? container.decodeIfPresent(Bool.self, forKey: .runsInSeparateTab)
            ?? true
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(command, forKey: .command)
        try container.encode(runsInSeparateTerminal, forKey: .runsInSeparateTerminal)
    }
}
