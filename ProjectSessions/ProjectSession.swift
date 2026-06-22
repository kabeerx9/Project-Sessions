import Foundation

struct ProjectSession: Identifiable, Codable {
    let id: UUID
    var name: String
    var browser: Browser
    var urls: [String]
    var repositoryPath: String
    var commands: [String]

    init(
        id: UUID,
        name: String,
        browser: Browser,
        urls: [String],
        repositoryPath: String,
        commands: [String] = []
    ) {
        self.id = id
        self.name = name
        self.browser = browser
        self.urls = urls
        self.repositoryPath = repositoryPath
        self.commands = commands
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case browser
        case urls
        case repositoryPath
        case commands
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        let savedBrowser = try container.decode(String.self, forKey: .browser)
        browser = Browser(rawValue: savedBrowser) ?? .chrome
        urls = try container.decode([String].self, forKey: .urls)
        repositoryPath = try container.decode(String.self, forKey: .repositoryPath)
        commands = try container.decodeIfPresent([String].self, forKey: .commands) ?? []
    }
}
