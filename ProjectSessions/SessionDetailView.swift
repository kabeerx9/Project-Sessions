import Foundation
import SwiftUI

struct SessionDetailView: View {
    let session: ProjectSession?
    let workspaceRuntime: WorkspaceRuntime?
    let commandRunStore: CommandRunStore
    let onRestore: @MainActor (ProjectSession) -> Void
    let onLaunch: @MainActor (ProjectSession) -> Void
    let onOpenFolder: @MainActor (ProjectSession) -> Void
    let onOpenInCursor: @MainActor (ProjectSession) -> Void
    let onShutdownWorkspace: @MainActor (ProjectSession) -> Void
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
                        commandConsole(session)
                        detailsGrid(session)
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
        return Panel {
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

                    Spacer()

                    Text("\(session.urls.count) URLs")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("\(session.commands.count) commands")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("\(commandRunStore.runningCount(for: session)) running")
                        .font(.caption)
                        .foregroundStyle(commandRunStore.runningCount(for: session) > 0 ? WiseColors.positive : .secondary)
                }
            }
        }
    }

    private func quickActions(_ session: ProjectSession) -> some View {
        return Panel {
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

                }
            }
        }
    }

    private func commandConsole(_ session: ProjectSession) -> some View {
        let runs = commandRunStore.runs(for: session)
        let selectedRun = commandRunStore.selectedRun(for: session)
        let selectedOutput = selectedRun?.output ?? ""
        let logBottomID = "command-console-log-bottom"

        return Panel {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    SectionHeader("Command Console", systemImage: "terminal")

                    Spacer()

                    StatusPill(
                        text: commandConsoleStatusText(for: session),
                        color: commandConsoleStatusColor(for: session)
                    )
                }

                HStack(spacing: 10) {
                    Button {
                        commandRunStore.startAll(for: session)
                    } label: {
                        Label("Run All", systemImage: "play.fill")
                    }
                    .disabled(session.commands.isEmpty || session.repositoryPath.isEmpty)

                    Button {
                        commandRunStore.stopAll(for: session)
                    } label: {
                        Label("Stop All", systemImage: "stop.fill")
                    }
                    .disabled(commandRunStore.runningCount(for: session) == 0)
                }

                if !runs.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(runs) { run in
                                Button {
                                    commandRunStore.selectedRunID = run.id
                                } label: {
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(statusColor(for: run.status))
                                            .frame(width: 7, height: 7)

                                        Text(run.title)
                                            .lineLimit(1)
                                    }
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .tint(run.id == selectedRun?.id ? WiseColors.primary : WiseColors.mute)
                            }
                        }
                    }
                }

                HStack(alignment: .center, spacing: 12) {
                    selectedRunSummary(selectedRun)

                    Spacer()

                    Button {
                        selectedRun?.clearOutput()
                    } label: {
                        Label("Clear Log", systemImage: "trash")
                    }
                    .controlSize(.small)
                    .disabled(selectedRun == nil)
                }

                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(selectedOutput.isEmpty ? "No output yet." : selectedOutput)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(.primary)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .topLeading)
                                .padding(12)

                            Color.clear
                                .frame(height: 1)
                                .id(logBottomID)
                        }
                    }
                    .onChange(of: selectedOutput) {
                        proxy.scrollTo(logBottomID, anchor: .bottom)
                    }
                    .onChange(of: selectedRun?.id) {
                        proxy.scrollTo(logBottomID, anchor: .bottom)
                    }
                }
                .frame(minHeight: 180, maxHeight: 260)
                .background(Color.black.opacity(0.88))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: WiseRadii.md, style: .continuous))
            }
        }
    }

    private func selectedRunSummary(_ run: CommandRun?) -> some View {
        HStack(spacing: 8) {
            if let run {
                Text(run.title)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)

                StatusPill(
                    text: commandStatusText(for: run),
                    color: commandStatusColor(for: run)
                )

                if let pid = run.pid, run.isRunning {
                    Text("PID \(pid)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let exitCode = run.exitCode, !run.isRunning {
                    Text("Exit \(exitCode)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("No command selected")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(minHeight: 28)
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
                            commandRow(command, in: session)
                        }
                    }
                }
            }
        }
    }

    private func commandRow(_ command: WorkspaceCommand, in session: ProjectSession) -> some View {
        let run = commandRunStore.run(for: command, in: session)

        return HStack(alignment: .center, spacing: 10) {
            Circle()
                .fill(commandStatusColor(for: run))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(command.name.isEmpty ? command.command : command.name)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)

                    StatusPill(
                        text: commandStatusText(for: run),
                        color: commandStatusColor(for: run)
                    )
                }

                if !command.name.isEmpty {
                    Text(command.command)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }

            Spacer()

            HStack(spacing: 8) {
                Button {
                    if let run, run.isRunning {
                        commandRunStore.stop(run)
                    } else {
                        commandRunStore.start(command, for: session)
                    }
                } label: {
                    Label(run?.isRunning == true ? "Stop" : "Run", systemImage: run?.isRunning == true ? "stop.fill" : "play.fill")
                }
                .controlSize(.small)
                .disabled(session.repositoryPath.isEmpty)

                Button {
                    if let run {
                        commandRunStore.restart(run, for: session)
                    }
                } label: {
                    Label("Restart", systemImage: "arrow.clockwise")
                }
                .controlSize(.small)
                .disabled(run == nil || session.repositoryPath.isEmpty)
            }
        }
        .padding(10)
        .background(WiseColors.canvas)
        .clipShape(RoundedRectangle(cornerRadius: WiseRadii.md, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: WiseRadii.md, style: .continuous)
                .stroke(commandRunStore.selectedRunID == run?.id ? WiseColors.primary.opacity(0.6) : WiseColors.border, lineWidth: 1)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if let run {
                commandRunStore.selectedRunID = run.id
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

    private func commandConsoleStatusText(for session: ProjectSession) -> String {
        let runningCount = commandRunStore.runningCount(for: session)
        let runCount = commandRunStore.runs(for: session).count

        if runningCount > 0 {
            return "\(runningCount) Running"
        }

        if runCount > 0 {
            return "Stopped"
        }

        return "Idle"
    }

    private func commandConsoleStatusColor(for session: ProjectSession) -> Color {
        commandRunStore.runningCount(for: session) > 0 ? WiseColors.positive : WiseColors.mute
    }

    private func statusColor(for status: CommandRunStatus) -> Color {
        switch status {
        case .idle:
            WiseColors.mute
        case .running:
            WiseColors.positive
        case .exited:
            WiseColors.mute
        case .failed:
            WiseColors.negative
        case .stopped:
            WiseColors.warningDeep
        }
    }

    private func commandStatusText(for run: CommandRun?) -> String {
        guard let run else {
            return "Not Run"
        }

        switch run.status {
        case .idle:
            return "Idle"
        case .running:
            return "Running"
        case .exited:
            return "Exited"
        case .failed:
            if let exitCode = run.exitCode {
                return "Failed \(exitCode)"
            }

            return "Failed"
        case .stopped:
            return "Stopped"
        }
    }

    private func commandStatusColor(for run: CommandRun?) -> Color {
        guard let run else {
            return WiseColors.mute
        }

        return statusColor(for: run.status)
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
