import SwiftUI

struct SessionSidebarView: View {
    let sessions: [ProjectSession]
    @Binding var selectedSessionID: ProjectSession.ID?
    let onDeleteSessions: (IndexSet) -> Void

    @Namespace private var animation

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Sessions")
                    .font(.system(size: 24, weight: .black, design: .default))
                    .foregroundStyle(WiseColors.ink)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 16)

            if sessions.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(sessions) { session in
                            SessionPillRow(
                                session: session,
                                isSelected: selectedSessionID == session.id,
                                animation: animation
                            )
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedSessionID = session.id
                                }
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    if let index = sessions.firstIndex(where: { $0.id == session.id }) {
                                        onDeleteSessions(IndexSet(integer: index))
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 20)
                }
            }
        }
        .background(WiseColors.canvasSoft)
        .scrollContentBackground(.hidden)
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            ZStack {
                Circle()
                    .fill(WiseColors.canvas)
                    .frame(width: 70, height: 70)
                Image(systemName: "plus.app.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(WiseColors.primary)
            }

            VStack(spacing: 6) {
                Text("No Sessions")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(WiseColors.ink)
                Text("Press ⌘N to create one")
                    .font(.system(size: 13))
                    .foregroundStyle(WiseColors.mute)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

private struct SessionPillRow: View {
    let session: ProjectSession
    let isSelected: Bool
    var animation: Namespace.ID

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isSelected ? WiseColors.canvasSoft : WiseColors.canvas)
                    .frame(width: 32, height: 32)

                Image(systemName: iconName(for: session))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(WiseColors.ink)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(session.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(WiseColors.ink)
                    .lineLimit(1)

                Text("\(session.urls.count) URLs · \(session.browser.rawValue)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(WiseColors.mute)
            }

            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: WiseRadii.lg, style: .continuous)
                    .fill(WiseColors.canvas)
                    .matchedGeometryEffect(id: "selection", in: animation)
            } else if isHovered {
                RoundedRectangle(cornerRadius: WiseRadii.lg, style: .continuous)
                    .fill(WiseColors.canvas.opacity(0.5))
            }
        }
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }

    private func iconName(for session: ProjectSession) -> String {
        if !session.repositoryPath.isEmpty { return "folder.fill" }
        if !session.urls.isEmpty { return "globe.americas.fill" }
        if !session.commands.isEmpty { return "terminal.fill" }
        return "doc.text.fill"
    }
}
