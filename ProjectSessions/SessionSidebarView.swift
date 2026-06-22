import SwiftUI

struct SessionSidebarView: View {
    let sessions: [ProjectSession]
    @Binding var selectedSessionID: ProjectSession.ID?
    let onDeleteSessions: (IndexSet) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            if sessions.isEmpty {
                emptyState
            } else {
                List(selection: $selectedSessionID) {
                    ForEach(sessions) { session in
                        SessionRow(session: session)
                            .tag(session.id)
                            .contextMenu {
                                Button(role: .destructive) {
                                    if let index = sessions.firstIndex(where: { $0.id == session.id }) {
                                        onDeleteSessions(IndexSet(integer: index))
                                    }
                                } label: {
                                    Label("Delete Session", systemImage: "trash")
                                }
                            }
                    }
                    .onDelete(perform: onDeleteSessions)
                }
                .listStyle(.sidebar)
                .scrollContentBackground(.hidden)
            }
        }
        .background(WiseColors.canvasSoft)
    }

    private var header: some View {
        HStack {
            Text("Project Sessions")
                .font(.headline)

            Spacer()

            Text("\(sessions.count)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(WiseColors.border)
                .clipShape(Capsule())
        }
        .padding(.horizontal, 14)
        .padding(.top, 14)
        .padding(.bottom, 8)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "folder.badge.plus")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text("No sessions yet")
                .font(.headline)

            Text("Press Command-N to create your first workspace.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .padding(16)
    }
}

private struct SessionRow: View {
    let session: ProjectSession

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(session.name)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)

                Text(summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }

    private var summary: String {
        "\(session.browser.rawValue) · \(session.urls.count) URLs · \(session.commands.count) commands"
    }

    private var iconName: String {
        if !session.commands.isEmpty {
            return "terminal"
        }

        if !session.urls.isEmpty {
            return "globe"
        }

        return "folder"
    }
}
