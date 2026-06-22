import Foundation
import Observation

@Observable
class SessionStore {
    var sessions: [ProjectSession] = [
        ProjectSession(
            id: UUID(),
            name: "Fantasy App",
            browser: .chrome,
            urls: ["https://github.com", "http://localhost:3000"],
            repositoryPath: "~/Projects/fantasy-app",
            commands: ["pnpm dev", "expo start"]
        ),
        ProjectSession(
            id: UUID(),
            name: "Dashboard",
            browser: .chrome,
            urls: ["https://figma.com"],
            repositoryPath: "~/Projects/dashboard",
            commands: ["npm run dev"]
        ),
        ProjectSession(
            id: UUID(),
            name: "SaaS",
            browser: .safari,
            urls: ["https://developer.apple.com"],
            repositoryPath: "~/Projects/saas",
            commands: []
        )
    ]

    private let sessionsKey = "projectSessions"

    init() {
        loadSessions()
    }

    func addSession(_ session: ProjectSession) {
        sessions.append(session)
        saveSessions()
    }

    func updateSession(_ session: ProjectSession) {
        guard let index = sessions.firstIndex(where: { $0.id == session.id }) else {
            return
        }

        sessions[index] = session
        saveSessions()
    }

    func deleteSessions(_ sessionsToDelete: [ProjectSession]) {
        let deletedIDs = sessionsToDelete.map(\.id)
        sessions.removeAll { deletedIDs.contains($0.id) }
        saveSessions()
    }

    private func saveSessions() {
        do {
            let data = try JSONEncoder().encode(sessions)
            UserDefaults.standard.set(data, forKey: sessionsKey)
        } catch {
            print("Failed to save sessions: \(error)")
        }
    }

    private func loadSessions() {
        guard let data = UserDefaults.standard.data(forKey: sessionsKey) else {
            return
        }

        do {
            sessions = try JSONDecoder().decode([ProjectSession].self, from: data)
        } catch {
            print("Failed to load sessions: \(error)")
        }
    }
}
