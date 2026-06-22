import SwiftUI

struct SessionSidebarView: View {
    let sessions: [ProjectSession]
    @Binding var selectedSessionID: ProjectSession.ID?
    let onCreateSession: () -> Void
    let onDeleteSessions: (IndexSet) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Project Sessions")
                    .font(.headline)

                Spacer()

                Button("Create") {
                    onCreateSession()
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            .padding([.horizontal, .top])

            if sessions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: "folder.badge.plus")
                        .font(.title)
                        .foregroundStyle(.secondary)

                    Text("No sessions yet.")
                        .font(.headline)

                    Text("Create your first project session.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()

                Spacer()
            } else {
                List(selection: $selectedSessionID) {
                    ForEach(sessions) { session in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(session.name)
                                .font(.headline)

                            Text("\(session.browser.rawValue) · \(session.urls.count) URLs")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                        .tag(session.id)
                    }
                    .onDelete(perform: onDeleteSessions)
                }
            }
        }
        .navigationSplitViewColumnWidth(min: 220, ideal: 260)
    }
}

#Preview {
    SessionSidebarView(
        sessions: [
            ProjectSession(
                id: UUID(),
                name: "Fantasy App",
                browser: .chrome,
                urls: ["https://github.com", "http://localhost:3000"],
                repositoryPath: "~/Projects/fantasy-app",
                commands: ["pnpm dev", "expo start"]
            )
        ],
        selectedSessionID: .constant(nil),
        onCreateSession: {},
        onDeleteSessions: { _ in }
    )
}
