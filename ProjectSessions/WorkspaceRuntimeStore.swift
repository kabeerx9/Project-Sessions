import Foundation
import Observation

@Observable
class WorkspaceRuntimeStore {
    private(set) var runtimes: [WorkspaceRuntime] = []

    private let runtimesKey = "workspaceRuntimes.v1"

    init() {
        loadRuntimes()
    }

    func runtime(for session: ProjectSession) -> WorkspaceRuntime? {
        runtimes.first { $0.sessionID == session.id }
    }

    func isActive(_ session: ProjectSession) -> Bool {
        runtime(for: session)?.status == .active
    }

    func markStarted(_ session: ProjectSession) {
        let runtime = WorkspaceRuntime(
            sessionID: session.id,
            sessionName: session.name,
            status: .active,
            startedAt: Date(),
            stoppedAt: nil
        )

        upsert(runtime)
        print("[Project Sessions Debug] Workspace started session=\(session.name)")
    }

    func markStopped(_ session: ProjectSession) {
        guard let index = runtimes.firstIndex(where: { $0.sessionID == session.id }) else {
            return
        }

        runtimes[index].status = .stopped
        runtimes[index].stoppedAt = Date()
        saveRuntimes()
        print("[Project Sessions Debug] Workspace stopped session=\(session.name)")
    }

    func markAllStoppedOnLaunch() {
        let now = Date()
        var didUpdate = false

        for index in runtimes.indices where runtimes[index].status == .active {
            runtimes[index].status = .stopped
            runtimes[index].stoppedAt = now
            didUpdate = true
        }

        if didUpdate {
            saveRuntimes()
            print("[Project Sessions Debug] Cleared active workspace state on launch")
        }
    }

    func removeRuntime(for session: ProjectSession) {
        runtimes.removeAll { $0.sessionID == session.id }
        saveRuntimes()
    }

    func removeRuntimes(for sessions: [ProjectSession]) {
        let sessionIDs = Set(sessions.map(\.id))
        runtimes.removeAll { sessionIDs.contains($0.sessionID) }
        saveRuntimes()
    }

    private func upsert(_ runtime: WorkspaceRuntime) {
        if let index = runtimes.firstIndex(where: { $0.sessionID == runtime.sessionID }) {
            runtimes[index] = runtime
        } else {
            runtimes.append(runtime)
        }

        saveRuntimes()
    }

    private func saveRuntimes() {
        do {
            let data = try JSONEncoder().encode(runtimes)
            UserDefaults.standard.set(data, forKey: runtimesKey)
        } catch {
            print("Failed to save workspace runtimes: \(error)")
        }
    }

    private func loadRuntimes() {
        guard let data = UserDefaults.standard.data(forKey: runtimesKey) else {
            return
        }

        do {
            runtimes = try JSONDecoder().decode([WorkspaceRuntime].self, from: data)
        } catch {
            print("Failed to load workspace runtimes: \(error)")
        }
    }
}
