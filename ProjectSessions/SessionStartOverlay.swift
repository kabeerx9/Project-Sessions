import AppKit
import SwiftUI

@MainActor
enum SessionStartOverlay {
    private static var window: NSWindow?

    static func show(sessionName: String, duration: TimeInterval = 1.8) {
        hide()

        guard let screen = NSScreen.main else {
            return
        }

        let overlayView = SessionStartOverlayView(sessionName: sessionName)
        let hostingController = NSHostingController(rootView: overlayView)
        let overlayWindow = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        overlayWindow.contentViewController = hostingController
        overlayWindow.backgroundColor = .clear
        overlayWindow.isOpaque = false
        overlayWindow.hasShadow = false
        overlayWindow.ignoresMouseEvents = true
        overlayWindow.level = .screenSaver
        overlayWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        overlayWindow.makeKeyAndOrderFront(nil)

        window = overlayWindow

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            hide()
        }
    }

    static func hide() {
        window?.orderOut(nil)
        window = nil
    }
}

private struct SessionStartOverlayView: View {
    let sessionName: String

    @State private var isVisible = false
    @State private var progress: CGFloat = 0

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.black.opacity(0.28))
                .ignoresSafeArea()

            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(.white.opacity(0.22), lineWidth: 8)
                        .frame(width: 72, height: 72)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(.white, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 72, height: 72)
                        .rotationEffect(.degrees(-90))

                    Image(systemName: "play.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(spacing: 4) {
                    Text("Starting session")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)

                    Text(sessionName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.78))
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 34)
            .padding(.vertical, 28)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.white.opacity(0.18), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.22), radius: 28, y: 14)
            .scaleEffect(isVisible ? 1 : 0.96)
            .opacity(isVisible ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.18)) {
                isVisible = true
            }

            withAnimation(.linear(duration: 1.55)) {
                progress = 1
            }
        }
    }
}
