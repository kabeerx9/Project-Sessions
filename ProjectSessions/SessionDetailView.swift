import Foundation
import SwiftUI

struct SessionDetailView: View {
    let session: ProjectSession?
    let workspaceRuntime: WorkspaceRuntime?
    let terminalProcessRecords: [TerminalProcessRecord]
    let terminalRunningCount: Int
    let onRestore: @MainActor (ProjectSession) -> Void
    let onLaunch: @MainActor (ProjectSession) -> Void
    let onOpenFolder: @MainActor (ProjectSession) -> Void
    let onOpenInCursor: @MainActor (ProjectSession) -> Void
    let onRunCommandsInTerminal: @MainActor (ProjectSession) -> Void
    let onStopTerminalProcesses: @MainActor (ProjectSession) -> Void
    let onShutdownWorkspace: @MainActor (ProjectSession) -> Void
    let onRefreshTerminalProcesses: @MainActor () -> Void
    let onCopyCommands: @MainActor (ProjectSession) -> Void
    let onCopyRepositoryPathAndCommands: @MainActor (ProjectSession) -> Void
    let onCopyShellChain: @MainActor (ProjectSession) -> Void
    let onEdit: @MainActor (ProjectSession) -> Void
    let onDelete: @MainActor (ProjectSession) -> Void

    var body: some View {
        ZStack {
            WiseColors.canvasSoft.ignoresSafeArea()

            if let session {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        header(session)
                        quickActions(session)
                        detailsGrid(session)

                        if !terminalProcessRecords.isEmpty {
                            processHealth
                        }
                    }
                    .padding(24)
                    .frame(maxWidth: 1080, alignment: .topLeading)
                    .frame(maxWidth: .infinity, alignment: .top)
                }
            } else {
                EmptyStateView()
            }

        }
        .background(WiseColors.canvasSoft)
        .animation(.easeOut(duration: 0.16), value: session?.id)
    }

    private func header(_ session: ProjectSession) -> some View {
        Panel {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Text(session.name)
                                .font(.system(size: 28, weight: .semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)

                            StatusPill(
                                text: isWorkspaceActive ? "Active" : "Stopped",
                                color: isWorkspaceActive ? WiseColors.positive : WiseColors.mute
                            )
                        }

                        Text(session.repositoryPath.isEmpty ? "No repository selected" : session.repositoryPath)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)

                        if isWorkspaceActive {
                            Text(workspaceOpenSinceText)
                                .font(.caption)
                                .foregroundStyle(WiseColors.positive)
                        }
                    }

                    Spacer()

                    Button {
                        onEdit(session)
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        onDelete(session)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }

                Divider()

                HStack(spacing: 10) {
                    Button {
                        if isWorkspaceActive {
                            onShutdownWorkspace(session)
                        } else {
                            SessionStartOverlay.show(sessionName: session.name)
                            onRestore(session)
                        }
                    } label: {
                        Label(
                            isWorkspaceActive ? "Shutdown Workspace" : "Start Session",
                            systemImage: isWorkspaceActive ? "power" : "play.fill"
                        )
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(isWorkspaceActive ? WiseColors.negative : WiseColors.primary)

                    if !isWorkspaceActive && !terminalProcessRecords.isEmpty {
                        Button {
                            onShutdownWorkspace(session)
                        } label: {
                            Label("Clean Up Workspace", systemImage: "power")
                        }
                    }

                    Spacer()

                    Text("\(session.urls.count) URLs")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("\(session.commands.count) commands")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("\(terminalRunningCount) running")
                        .font(.caption)
                        .foregroundStyle(terminalRunningCount > 0 ? WiseColors.positive : .secondary)
                }
            }
        }
    }

    private func quickActions(_ session: ProjectSession) -> some View {
        Panel {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader("Actions", systemImage: "bolt")

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 170), spacing: 10)], spacing: 10) {
                    ActionButton(
                        title: "Open URLs",
                        subtitle: session.urls.isEmpty ? "No URLs saved" : "\(session.urls.count) saved",
                        systemImage: "globe",
                        isDisabled: session.urls.isEmpty
                    ) {
                        onLaunch(session)
                    }

                    ActionButton(
                        title: "Open Folder",
                        subtitle: session.repositoryPath.isEmpty ? "No path saved" : "Finder",
                        systemImage: "folder",
                        isDisabled: session.repositoryPath.isEmpty
                    ) {
                        onOpenFolder(session)
                    }

                    ActionButton(
                        title: "Open in Cursor",
                        subtitle: session.repositoryPath.isEmpty ? "No path saved" : "Workspace",
                        systemImage: "cursorarrow.and.square.on.square.dashed",
                        isDisabled: session.repositoryPath.isEmpty
                    ) {
                        onOpenInCursor(session)
                    }

                    ActionButton(
                        title: "Run Commands",
                        subtitle: session.commands.isEmpty ? "No commands saved" : "Terminal",
                        systemImage: "terminal",
                        isDisabled: session.repositoryPath.isEmpty || session.commands.isEmpty
                    ) {
                        onRunCommandsInTerminal(session)
                    }
                }
            }
        }
    }

    private func detailsGrid(_ session: ProjectSession) -> some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
            Panel {
                VStack(alignment: .leading, spacing: 14) {
                    SectionHeader("Browser", systemImage: "safari")

                    InfoRow(title: "App", value: session.browser.rawValue)
                    InfoRow(
                        title: "Profile",
                        value: session.browserProfileName.isEmpty ? "Default" : session.browserProfileName
                    )
                }
            }

            Panel {
                VStack(alignment: .leading, spacing: 14) {
                    SectionHeader("Workspace", systemImage: "rectangle.connected.to.line.below")

                    InfoRow(title: "Status", value: isWorkspaceActive ? "Active" : "Stopped")
                    InfoRow(title: "Activity", value: workspaceStatusSubvalue)
                }
            }

            Panel {
                VStack(alignment: .leading, spacing: 14) {
                    SectionHeader("URLs", systemImage: "link")

                    if session.urls.isEmpty {
                        EmptyMessage("No URLs saved.")
                    } else {
                        ForEach(session.urls, id: \.self) { url in
                            ListValue(text: url, systemImage: "globe")
                        }
                    }
                }
            }

            Panel {
                VStack(alignment: .leading, spacing: 14) {
                    SectionHeader("Commands", systemImage: "terminal")

                    if session.commands.isEmpty {
                        EmptyMessage("No commands saved.")
                    } else {
                        ForEach(session.commands) { command in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                    Text(command.name.isEmpty ? command.command : command.name)
                                        .font(.system(size: 13, weight: .semibold))
                                        .lineLimit(1)

                                    Spacer()

                                    if command.runsInSeparateTerminal {
                                        Text("Separate")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(WiseColors.border)
                                            .clipShape(Capsule())
                                    }
                                }

                                if !command.name.isEmpty {
                                    Text(command.command)
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                        .padding(.leading, 20)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
    }

    private var processHealth: some View {
        Panel {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    SectionHeader("Process Health", systemImage: "waveform.path.ecg")

                    Spacer()

                    Button {
                        onRefreshTerminalProcesses()
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .controlSize(.small)
                }

                ForEach(terminalProcessRecords) { record in
                    HStack(spacing: 10) {
                        Circle()
                            .fill(statusColor(for: record.status))
                            .frame(width: 8, height: 8)

                        Text(record.title)
                            .font(.system(size: 13, weight: .medium))
                            .lineLimit(1)

                        Spacer()

                        Text(record.status.rawValue.capitalized)
                            .font(.caption)
                            .foregroundStyle(statusColor(for: record.status))
                    }
                    .padding(.vertical, 5)
                }
            }
        }
    }

    private var isWorkspaceActive: Bool {
        workspaceRuntime?.status == .active
    }

    private var workspaceStatusSubvalue: String {
        guard let workspaceRuntime else {
            return "Not started"
        }

        switch workspaceRuntime.status {
        case .active:
            return "Started \(workspaceRuntime.startedAt.formatted(date: .omitted, time: .shortened))"
        case .stopped:
            guard let stoppedAt = workspaceRuntime.stoppedAt else {
                return "Stopped"
            }

            return "Stopped \(stoppedAt.formatted(date: .omitted, time: .shortened))"
        }
    }

    private var workspaceOpenSinceText: String {
        guard let workspaceRuntime, workspaceRuntime.status == .active else {
            return ""
        }

        return "Open since \(workspaceRuntime.startedAt.formatted(date: .omitted, time: .shortened))"
    }

    private func statusColor(for status: TerminalProcessStatus) -> Color {
        switch status {
        case .running:
            WiseColors.positive
        case .stopped:
            WiseColors.warningDeep
        case .launching:
            WiseColors.accentCyan
        case .exited:
            WiseColors.mute
        }
    }
}

private struct Panel<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(WiseColors.panel)
            .clipShape(RoundedRectangle(cornerRadius: WiseRadii.lg, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: WiseRadii.lg, style: .continuous)
                    .stroke(WiseColors.border, lineWidth: 1)
            }
    }
}

private struct SectionHeader: View {
    let title: String
    let systemImage: String

    init(_ title: String, systemImage: String) {
        self.title = title
        self.systemImage = systemImage
    }

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.primary)
    }
}

private struct ActionButton: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(isDisabled ? .secondary : WiseColors.primary)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(10)
            .frame(minHeight: 54)
            .background(WiseColors.canvas)
            .clipShape(RoundedRectangle(cornerRadius: WiseRadii.md, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: WiseRadii.md, style: .continuous)
                    .stroke(WiseColors.border, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.55 : 1)
    }
}

private struct InfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.system(size: 13, weight: .medium))
                .multilineTextAlignment(.trailing)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }
}

private struct ListValue: View {
    let text: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 14)

            Text(text)
                .font(.system(size: 13))
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(.vertical, 3)
    }
}

private struct StatusPill: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}

private struct EmptyMessage: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.callout)
            .foregroundStyle(.secondary)
    }
}

private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "sidebar.left")
                .font(.system(size: 38))
                .foregroundStyle(.secondary)

            Text("Select a session")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Choose a project session from the sidebar.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
