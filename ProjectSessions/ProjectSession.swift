import Foundation

struct ProjectSession: Identifiable, Codable {
    let id: UUID
    var name: String
    var browser: Browser
    var urls: [String]
    var repositoryPath: String
    var commands: [TerminalCommand]

    init(
        id: UUID,
        name: String,
        browser: Browser,
        urls: [String],
        repositoryPath: String,
        commands: [TerminalCommand] = []
    ) {
        self.id = id
        self.name = name
        self.browser = browser
        self.urls = urls
        self.repositoryPath = repositoryPath
        self.commands = commands
    }
}
