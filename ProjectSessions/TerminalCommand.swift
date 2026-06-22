import Foundation

struct TerminalCommand: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var command: String
    var runsInSeparateTab: Bool

    init(
        id: UUID = UUID(),
        name: String = "",
        command: String,
        runsInSeparateTab: Bool = true
    ) {
        self.id = id
        self.name = name
        self.command = command
        self.runsInSeparateTab = runsInSeparateTab
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case command
        case runsInSeparateTab
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        command = try container.decode(String.self, forKey: .command)
        runsInSeparateTab = try container.decodeIfPresent(Bool.self, forKey: .runsInSeparateTab) ?? true
    }
}
