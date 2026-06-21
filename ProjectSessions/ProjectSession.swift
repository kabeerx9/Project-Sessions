import Foundation

struct ProjectSession: Identifiable, Codable {
    let id: UUID
    var name: String
    var browser: String
    var urls: [String]
    var repositoryPath: String
}
