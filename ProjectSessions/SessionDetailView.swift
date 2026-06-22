import SwiftUI

struct SessionDetailView: View {
    let session: ProjectSession?
    let onRestore: @MainActor (ProjectSession) -> Void
    let onLaunch: @MainActor (ProjectSession) -> Void
    let onOpenFolder: @MainActor (ProjectSession) -> Void
    let onOpenInCursor: @MainActor (ProjectSession) -> Void
    let onOpenInGhostty: @MainActor (ProjectSession) -> Void
    let onRunCommandsInTerminal: @MainActor (ProjectSession) -> Void
    let onCopyCommands: @MainActor (ProjectSession) -> Void
    let onCopyRepositoryPathAndCommands: @MainActor (ProjectSession) -> Void
    let onCopyShellChain: @MainActor (ProjectSession) -> Void
    let onEdit: @MainActor (ProjectSession) -> Void
    let onDelete: @MainActor (ProjectSession) -> Void
    @State private var copiedMessage: String?

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

                    Button("Open URLs") {
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

                    Button("Open in Ghostty") {
                        onOpenInGhostty(session)
                    }
                    .disabled(session.repositoryPath.isEmpty)

                    Button("Run Commands in Terminal") {
                        onRunCommandsInTerminal(session)
                    }
                    .disabled(session.repositoryPath.isEmpty || session.commands.isEmpty)

                    Button("Copy Commands") {
                        onCopyCommands(session)
                        showCopiedMessage("Copied commands")
                    }
                    .disabled(session.commands.isEmpty)

                    Button("Copy cd + Commands") {
                        onCopyRepositoryPathAndCommands(session)
                        showCopiedMessage("Copied cd + commands")
                    }
                    .disabled(session.commands.isEmpty || session.repositoryPath.isEmpty)

                    Button("Copy Shell Chain") {
                        onCopyShellChain(session)
                        showCopiedMessage("Copied shell chain")
                    }
                    .disabled(session.commands.isEmpty || session.repositoryPath.isEmpty)

                    Button("Edit") {
                        onEdit(session)
                    }

                    Button("Delete") {
                        onDelete(session)
                    }
                }

                Divider()

                if let copiedMessage {
                    Text(copiedMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 16) {
                    Text("\(session.urls.count) URLs")
                    Text("\(session.commands.count) commands")
                    Text("Browser: \(session.browser.rawValue)")
                    Text("Command runner: Terminal")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Browser")
                        .font(.headline)

                    Text(session.browser.rawValue)
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

                VStack(alignment: .leading, spacing: 8) {
                    Text("Commands")
                        .font(.headline)

                    if session.commands.isEmpty {
                        Text("No commands saved.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(session.commands) { command in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(command.name.isEmpty ? command.command : command.name)
                                    .foregroundStyle(.secondary)

                                Text(command.command)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                if command.runsInSeparateTab {
                                    Text("Separate terminal tab later")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
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

    private func showCopiedMessage(_ message: String) {
        copiedMessage = message

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if copiedMessage == message {
                copiedMessage = nil
            }
        }
    }
}

#Preview {
    SessionDetailView(
        session: ProjectSession(
            id: UUID(),
            name: "Fantasy App",
            browser: .chrome,
            urls: ["https://github.com", "http://localhost:3000"],
            repositoryPath: "~/Projects/fantasy-app",
            commands: [
                TerminalCommand(name: "Web", command: "pnpm dev"),
                TerminalCommand(name: "Mobile", command: "expo start")
            ]
        ),
        onRestore: { _ in },
        onLaunch: { _ in },
        onOpenFolder: { _ in },
        onOpenInCursor: { _ in },
        onOpenInGhostty: { _ in },
        onRunCommandsInTerminal: { _ in },
        onCopyCommands: { _ in },
        onCopyRepositoryPathAndCommands: { _ in },
        onCopyShellChain: { _ in },
        onEdit: { _ in },
        onDelete: { _ in }
    )
}
