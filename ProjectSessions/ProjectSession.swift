import Foundation

struct ProjectSession: Identifiable, Codable {
    let id: UUID
    var name: String
    var browser: Browser
    var browserProfileName: String
    var urls: [String]
    var repositoryPath: String
    var commands: [WorkspaceCommand]

    init(
        id: UUID,
        name: String,
        browser: Browser,
        browserProfileName: String = "",
        urls: [String],
        repositoryPath: String,
        commands: [WorkspaceCommand] = []
    ) {
        self.id = id
        self.name = name
        self.browser = browser
        self.browserProfileName = browserProfileName
        self.urls = urls
        self.repositoryPath = repositoryPath
        self.commands = commands
    }
}
