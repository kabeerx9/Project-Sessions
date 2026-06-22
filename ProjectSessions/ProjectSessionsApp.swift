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

    var body: some Scene {
        WindowGroup {
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
                    }
                }
            }
        }
    }
}
