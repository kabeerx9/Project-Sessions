import Foundation

enum TerminalProcessStatus: String, Codable {
    case launching
    case running
    case exited
    case stopped
}

struct TerminalProcessRecord: Identifiable, Codable, Hashable {
    let id: UUID
    let sessionID: ProjectSession.ID
    var sessionName: String
    var title: String
    var command: String
    var workingDirectory: String
    var pidFilePath: String
    var exitFilePath: String
    var pid: Int32?
    var status: TerminalProcessStatus
    var startedAt: Date
}
