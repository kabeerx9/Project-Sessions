import Foundation

enum WorkspaceRuntimeStatus: String, Codable {
    case active
    case stopped
}

struct WorkspaceRuntime: Identifiable, Codable, Hashable {
    let sessionID: ProjectSession.ID
    var sessionName: String
    var status: WorkspaceRuntimeStatus
    var startedAt: Date
    var stoppedAt: Date?

    var id: ProjectSession.ID {
        sessionID
    }
}
