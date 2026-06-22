import AppKit
import SwiftUI

@MainActor
enum SessionStartOverlay {
    private static var window: NSWindow?

    static func show(sessionName: String, duration: TimeInterval = 4) {
        print("[Project Sessions Debug] Showing start overlay for session=\(sessionName)")
        hide()

        guard let screen = NSScreen.main else {
            print("[Project Sessions Debug] Could not show start overlay: NSScreen.main is nil")
            return
        }

        print("[Project Sessions Debug] Start overlay screen frame=\(screen.frame)")

        let overlayView = SessionStartOverlayView(sessionName: sessionName)
            .frame(width: screen.frame.width, height: screen.frame.height)
        let hostingView = NSHostingView(rootView: overlayView)
        hostingView.frame = NSRect(origin: .zero, size: screen.frame.size)

        let overlayWindow = SessionOverlayPanel(
            contentRect: screen.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        overlayWindow.contentView = hostingView
        overlayWindow.backgroundColor = .clear
        overlayWindow.isOpaque = false
        overlayWindow.hasShadow = false
        overlayWindow.ignoresMouseEvents = true
        overlayWindow.level = .screenSaver
        overlayWindow.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary,
            .ignoresCycle
        ]
        overlayWindow.isReleasedWhenClosed = false
        overlayWindow.setFrame(screen.frame, display: true)
        overlayWindow.orderFrontRegardless()

        window = overlayWindow
        print("[Project Sessions Debug] Start overlay window shown level=\(overlayWindow.level.rawValue) frame=\(overlayWindow.frame) visible=\(overlayWindow.isVisible)")

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            hide()
        }
    }

    static func hide() {
        if window != nil {
            print("[Project Sessions Debug] Hiding start overlay")
        }
        window?.orderOut(nil)
        window = nil
    }
}

private final class SessionOverlayPanel: NSPanel {
    override var canBecomeKey: Bool {
        false
    }

    override var canBecomeMain: Bool {
        false
    }
}

private struct SessionStartOverlayView: View {
    let sessionName: String

    @State private var isVisible = false
    @State private var progress: CGFloat = 0
    @State private var scanOffset: CGFloat = -170
    @State private var pulse = false
    @State private var ringRotation = 0.0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.black.opacity(0.82),
                    Color(red: 0.02, green: 0.08, blue: 0.12).opacity(0.88),
                    Color.black.opacity(0.78)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
                .ignoresSafeArea()

            gridBackground

            VStack(spacing: 22) {
                ZStack {
                    Circle()
                        .stroke(Color.cyan.opacity(0.10), lineWidth: 22)
                        .frame(width: 210, height: 210)
                        .scaleEffect(pulse ? 1.12 : 0.96)
                        .opacity(pulse ? 0.28 : 0.55)

                    Circle()
                        .stroke(Color.cyan.opacity(0.18), lineWidth: 1)
                        .frame(width: 172, height: 172)

                    Circle()
                        .trim(from: 0.05, to: 0.34)
                        .stroke(Color.cyan, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 172, height: 172)
                        .rotationEffect(.degrees(ringRotation))

                    Circle()
                        .trim(from: 0.58, to: 0.86)
                        .stroke(Color.white.opacity(0.72), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .frame(width: 138, height: 138)
                        .rotationEffect(.degrees(-ringRotation * 1.4))

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            LinearGradient(
                                colors: [.cyan, .white, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 7, lineCap: .round)
                        )
                        .frame(width: 104, height: 104)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 3) {
                        Image(systemName: "cpu")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(.white)

                        Text("BOOT")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(.cyan)
                    }
                }

                VStack(spacing: 8) {
                    Text("STARTING SESSION")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .tracking(2.4)
                        .foregroundStyle(.cyan)

                    Text(sessionName)
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    HStack(spacing: 10) {
                        BootStep(text: "Browser")
                        BootStep(text: "Cursor")
                        BootStep(text: "Terminal")
                    }
                    .padding(.top, 6)
                }

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.white.opacity(0.12))
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.cyan, .white.opacity(0.9)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(12, proxy.size.width * progress))
                    }
                }
                .frame(width: 260, height: 5)
                .padding(.top, 2)
            }
            .padding(.horizontal, 46)
            .padding(.vertical, 38)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.ultraThinMaterial)

                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [.cyan.opacity(0.16), .clear, .blue.opacity(0.10)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, .white.opacity(0.18), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 90)
                        .offset(y: scanOffset)
                        .blur(radius: 8)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [.cyan.opacity(0.65), .white.opacity(0.22), .blue.opacity(0.50)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: .cyan.opacity(0.22), radius: 30, y: 12)
            .shadow(color: .black.opacity(0.35), radius: 38, y: 22)
            .scaleEffect(isVisible ? 1 : 0.94)
            .opacity(isVisible ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.22)) {
                isVisible = true
            }

            withAnimation(.linear(duration: 1.55)) {
                progress = 1
            }

            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                ringRotation = 360
            }

            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                pulse = true
            }

            withAnimation(.easeInOut(duration: 1.35).repeatForever(autoreverses: false)) {
                scanOffset = 170
            }
        }
    }

    private var gridBackground: some View {
        Canvas { context, size in
            let spacing: CGFloat = 44
            var path = Path()

            for x in stride(from: CGFloat(0), through: size.width, by: spacing) {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
            }

            for y in stride(from: CGFloat(0), through: size.height, by: spacing) {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
            }

            context.stroke(path, with: .color(.cyan.opacity(0.055)), lineWidth: 1)
        }
        .ignoresSafeArea()
    }
}

private struct BootStep: View {
    let text: String

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(.cyan)
                .frame(width: 5, height: 5)

            Text(text.uppercased())
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.76))
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(.white.opacity(0.08))
        .clipShape(Capsule())
    }
}
