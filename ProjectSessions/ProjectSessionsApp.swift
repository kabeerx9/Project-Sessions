//
//  ProjectSessionsApp.swift
//  ProjectSessions
//
//  Created by Kabeer Joshi on 21/06/26.
//

import SwiftUI

@main
struct ProjectSessionsApp: App {
    @State private var sessionStore = SessionStore()
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView(sessionStore: sessionStore)
        }
        .defaultSize(width: 1000, height: 650)

        MenuBarExtra("Project Sessions", systemImage: "folder") {
            if sessionStore.sessions.isEmpty {
                Text("No sessions")
            } else {
                ForEach(sessionStore.sessions) { session in
                    Menu(session.name) {
                        Button("Restore Session") {
                            SessionLauncher.restore(session)
                        }

                        Button("Open URLs") {
                            SessionLauncher.launchURLs(for: session)
                        }

                        Button("Open in Cursor") {
                            SessionLauncher.openRepositoryInCursor(session)
                        }

                        Button("Copy Commands") {
                            CommandClipboard.copyCommands(for: session)
                        }
                        .disabled(session.commands.isEmpty)
                    }
                }
            }

            Divider()

            Button("Open Main Window") {
                openWindow(id: "main")
            }

            Button("Quit Project Sessions") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}
