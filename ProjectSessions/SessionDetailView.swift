import SwiftUI

struct SessionDetailView: View {
    let session: ProjectSession?
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
    
    @State private var copiedMessage: String?
    @State private var isRestoring = false

    var body: some View {
        ZStack {
            WiseColors.canvasSoft.ignoresSafeArea()

            if let session {
                ScrollView {
                    VStack(spacing: WiseRadii.xl) {
                        headerControls(session: session)
                        
                        bentoGrid(session: session)
                    }
                    .padding(32)
                    .frame(maxWidth: .infinity, alignment: .top)
                }
            } else {
                EmptyStateView()
            }

            if isRestoring {
                RestoreOverlayView()
                    .transition(.opacity.combined(with: .scale(scale: 1.05)))
                    .zIndex(2)
            }
        }
        .background(WiseColors.canvasSoft)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isRestoring)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: session?.id)
    }
    
    private func headerControls(session: ProjectSession) -> some View {
        HStack {
            Spacer()

            Button {
                onEdit(session)
            } label: {
                Label("Edit Session", systemImage: "pencil")
            }

            Button(role: .destructive) {
                onDelete(session)
            } label: {
                Label("Delete Session", systemImage: "trash")
            }
        }
    }

    private func bentoGrid(session: ProjectSession) -> some View {
        VStack(spacing: WiseRadii.xl) {
            // Hero Tile
            heroTile(session: session)
            
            // Stats & Actions Layer
            HStack(spacing: WiseRadii.xl) {
                // Left Column: Actions
                VStack(spacing: WiseRadii.xl) {
                    HStack(spacing: WiseRadii.xl) {
                        WiseActionTile(icon: "globe.americas.fill", title: "Open URLs", isDisabled: session.urls.isEmpty) { onLaunch(session) }
                        WiseActionTile(icon: "folder.fill", title: "Open Folder", isDisabled: session.repositoryPath.isEmpty) { onOpenFolder(session) }
                    }
                    HStack(spacing: WiseRadii.xl) {
                        WiseActionTile(icon: "cursorarrow.and.square.on.square.dashed", title: "Open Cursor", isDisabled: session.repositoryPath.isEmpty) { onOpenInCursor(session) }
                        WiseActionTile(icon: "terminal.fill", title: "Run Commands", isDisabled: session.repositoryPath.isEmpty || session.commands.isEmpty) { onRunCommandsInTerminal(session) }
                    }
                    HStack(spacing: WiseRadii.xl) {
                        WiseActionTile(icon: "power", title: "Shutdown Workspace", isDisabled: terminalProcessRecords.isEmpty) { onShutdownWorkspace(session) }
                    }
                }
                .frame(maxWidth: .infinity)
                
                // Right Column: Stats
                VStack(spacing: WiseRadii.xl) {
                    WiseStatTile(icon: "safari.fill", title: "Browser", value: session.browser.rawValue, subvalue: session.browserProfileName.isEmpty ? "Default Profile" : session.browserProfileName)
                    WiseStatTile(icon: "waveform.path.ecg", title: "Running Tasks", value: "\(terminalRunningCount)", subvalue: terminalRunningCount == 0 ? "Idle" : "Active processes", highlightColor: terminalRunningCount > 0 ? WiseColors.positive : nil)
                }
                .frame(maxWidth: .infinity)
            }
            
            // Lists Layer
            HStack(alignment: .top, spacing: WiseRadii.xl) {
                if !session.urls.isEmpty {
                    urlList(session: session)
                        .frame(maxWidth: .infinity, alignment: .top)
                }
                
                if !session.commands.isEmpty {
                    commandList(session: session)
                        .frame(maxWidth: .infinity, alignment: .top)
                }
            }
            
            if !terminalProcessRecords.isEmpty {
                terminalHealthBento()
            }
        }
    }

    private func heroTile(session: ProjectSession) -> some View {
        WiseCard {
            HStack(spacing: 32) {
                ZStack {
                    Circle()
                        .fill(WiseColors.canvasSoft)
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: iconName(for: session))
                        .font(.system(size: 40))
                        .foregroundStyle(WiseColors.ink)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(session.name)
                        .font(.system(size: 48, weight: .black, design: .default))
                        .foregroundStyle(WiseColors.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    
                    if !session.repositoryPath.isEmpty {
                        Text(session.repositoryPath)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(WiseColors.mute)
                            .lineLimit(1)
                    }
                }
                
                Spacer(minLength: 40)
                
                Button {
                    withAnimation { isRestoring = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                        onRestore(session)
                        withAnimation { isRestoring = false }
                    }
                } label: {
                    Text("Restore Session")
                        .font(.system(size: 20, weight: .black, design: .default))
                        .foregroundStyle(WiseColors.onPrimary)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 20)
                        .background(WiseColors.primary)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func urlList(session: ProjectSession) -> some View {
        WiseCard {
            VStack(alignment: .leading, spacing: 20) {
                Text("Web Resources")
                    .font(.system(size: 24, weight: .black, design: .default))
                    .foregroundStyle(WiseColors.ink)
                
                VStack(spacing: 12) {
                    ForEach(session.urls, id: \.self) { url in
                        HStack(spacing: 16) {
                            Image(systemName: "safari.fill")
                                .foregroundStyle(WiseColors.mute)
                                .font(.system(size: 20))
                            Text(url)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(WiseColors.ink)
                            Spacer()
                        }
                        .padding(16)
                        .background(WiseColors.canvasSoft)
                        .clipShape(RoundedRectangle(cornerRadius: WiseRadii.lg, style: .continuous))
                    }
                }
            }
        }
    }

    private func commandList(session: ProjectSession) -> some View {
        WiseCard {
            VStack(alignment: .leading, spacing: 20) {
                Text("Startup Commands")
                    .font(.system(size: 24, weight: .black, design: .default))
                    .foregroundStyle(WiseColors.ink)
                
                VStack(spacing: 12) {
                    ForEach(session.commands) { command in
                        HStack(spacing: 16) {
                            Image(systemName: "chevron.right")
                                .foregroundStyle(WiseColors.mute)
                                .font(.system(size: 20, weight: .bold))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(command.name.isEmpty ? command.command : command.name)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(WiseColors.ink)
                                if !command.name.isEmpty {
                                    Text(command.command)
                                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                                        .foregroundStyle(WiseColors.mute)
                                }
                            }
                            Spacer()
                        }
                        .padding(16)
                        .background(WiseColors.canvasSoft)
                        .clipShape(RoundedRectangle(cornerRadius: WiseRadii.lg, style: .continuous))
                    }
                }
            }
        }
    }

    private func terminalHealthBento() -> some View {
        WiseCard {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("Process Health")
                        .font(.system(size: 24, weight: .black, design: .default))
                        .foregroundStyle(WiseColors.ink)
                    Spacer()
                    Button { onRefreshTerminalProcesses() } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(WiseColors.ink)
                            .padding(12)
                            .background(WiseColors.canvasSoft)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(terminalProcessRecords) { record in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(statusColor(for: record.status))
                                .frame(width: 12, height: 12)
                            
                            Text(record.title)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(WiseColors.ink)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Text(record.status.rawValue.uppercased())
                                .font(.system(size: 12, weight: .black))
                                .foregroundStyle(statusColor(for: record.status))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(statusColor(for: record.status).opacity(0.15))
                                .clipShape(Capsule())
                        }
                        .padding(16)
                        .background(WiseColors.canvasSoft)
                        .clipShape(RoundedRectangle(cornerRadius: WiseRadii.lg, style: .continuous))
                    }
                }
            }
        }
    }

    private func iconName(for session: ProjectSession) -> String {
        if !session.repositoryPath.isEmpty { return "folder.fill" }
        if !session.urls.isEmpty { return "globe.americas.fill" }
        if !session.commands.isEmpty { return "terminal.fill" }
        return "doc.text.fill"
    }

    private func statusColor(for status: TerminalProcessStatus) -> Color {
        switch status {
        case .running: return WiseColors.positive
        case .stopped: return WiseColors.warningDeep
        case .launching: return WiseColors.accentCyan
        case .exited: return WiseColors.negative
        }
    }
}

// MARK: - Wise Components

private struct WiseCard<Content: View>: View {
    @ViewBuilder let content: Content
    
    var body: some View {
        content
            .padding(32)
            .background(WiseColors.canvas)
            .clipShape(RoundedRectangle(cornerRadius: WiseRadii.xl, style: .continuous))
    }
}

private struct WiseActionTile: View {
    let icon: String
    let title: String
    let isDisabled: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(isDisabled ? WiseColors.mute : WiseColors.ink)
                
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(isDisabled ? WiseColors.mute : WiseColors.ink)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(32)
            .background(isHovered && !isDisabled ? WiseColors.canvasSoft.opacity(0.8) : WiseColors.canvasSoft)
            .clipShape(RoundedRectangle(cornerRadius: WiseRadii.xl, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .scaleEffect(isHovered && !isDisabled ? 0.98 : 1.0)
        .onHover { hovering in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                isHovered = hovering
            }
        }
    }
}

private struct WiseStatTile: View {
    let icon: String
    let title: String
    let value: String
    let subvalue: String
    var highlightColor: Color? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(WiseColors.mute)
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(WiseColors.mute)
            }
            
            Text(value)
                .font(.system(size: 40, weight: .black, design: .default))
                .foregroundStyle(highlightColor ?? WiseColors.ink)
            
            Text(subvalue)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(WiseColors.mute)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(32)
        .background(WiseColors.canvas)
        .clipShape(RoundedRectangle(cornerRadius: WiseRadii.xl, style: .continuous))
    }
}

private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(WiseColors.canvas)
                    .frame(width: 120, height: 120)
                
                Image(systemName: "square.grid.3x3.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(WiseColors.mute)
            }

            VStack(spacing: 8) {
                Text("Select a Workspace")
                    .font(.system(size: 32, weight: .black, design: .default))
                    .foregroundStyle(WiseColors.ink)
                Text("Choose a session from the dashboard to view details")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(WiseColors.mute)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct RestoreOverlayView: View {
    @State private var isPulsing = false

    var body: some View {
        ZStack {
            WiseColors.ink
                .ignoresSafeArea()
            
            VStack(spacing: 48) {
                ZStack {
                    Circle()
                        .fill(WiseColors.primary.opacity(0.1))
                        .frame(width: 200, height: 200)
                        .scaleEffect(isPulsing ? 1.5 : 1.0)
                        .opacity(isPulsing ? 0 : 1)
                    
                    Circle()
                        .fill(WiseColors.primary)
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(WiseColors.ink)
                }
                
                Text("Starting Session")
                    .font(.system(size: 40, weight: .black, design: .default))
                    .foregroundStyle(WiseColors.primary)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: false)) {
                isPulsing = true
            }
        }
    }
}
