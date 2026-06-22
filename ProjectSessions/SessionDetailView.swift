import SwiftUI

struct SessionDetailView: View {
    let session: ProjectSession?
    let onRestore: (ProjectSession) -> Void
    let onLaunch: (ProjectSession) -> Void
    let onOpenFolder: (ProjectSession) -> Void
    let onOpenInCursor: (ProjectSession) -> Void
    let onEdit: (ProjectSession) -> Void
    let onDelete: (ProjectSession) -> Void

    var body: some View {
        if let session {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(session.name)
                            .font(.largeTitle)

                        Text(session.repositoryPath)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button("Restore Session") {
                        onRestore(session)
                    }

                    Button("Launch Session") {
                        onLaunch(session)
                    }
                    .disabled(session.urls.isEmpty)

                    Button("Open Folder") {
                        onOpenFolder(session)
                    }
                    .disabled(session.repositoryPath.isEmpty)

                    Button("Open in Cursor") {
                        onOpenInCursor(session)
                    }
                    .disabled(session.repositoryPath.isEmpty)

                    Button("Edit") {
                        onEdit(session)
                    }

                    Button("Delete") {
                        onDelete(session)
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Browser")
                        .font(.headline)

                    Text(session.browser)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("URLs")
                        .font(.headline)

                    if session.urls.isEmpty {
                        Text("No URLs saved.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(session.urls, id: \.self) { url in
                            Text(url)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        } else {
            VStack(spacing: 12) {
                Image(systemName: "sidebar.left")
                    .font(.system(size: 44))
                    .foregroundStyle(.secondary)

                Text("Select a session")
                    .font(.title2)

                Text("Choose a project session from the sidebar to view its details.")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    SessionDetailView(
        session: ProjectSession(
            id: UUID(),
            name: "Fantasy App",
            browser: "Chrome",
            urls: ["https://github.com", "http://localhost:3000"],
            repositoryPath: "~/Projects/fantasy-app"
        ),
        onRestore: { _ in },
        onLaunch: { _ in },
        onOpenFolder: { _ in },
        onOpenInCursor: { _ in },
        onEdit: { _ in },
        onDelete: { _ in }
    )
}
