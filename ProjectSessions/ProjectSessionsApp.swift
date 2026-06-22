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
    @State private var workspaceRuntimeStore = WorkspaceRuntimeStore()
    @State private var commandRunStore = CommandRunStore()
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView(
                sessionStore: sessionStore,
                workspaceRuntimeStore: workspaceRuntimeStore,
                commandRunStore: commandRunStore
            )
        }
        .defaultSize(width: 1000, height: 650)

        MenuBarExtra("Project Sessions", systemImage: "folder") {
            if sessionStore.sessions.isEmpty {
                Text("No sessions")
            } else {
                ForEach(sessionStore.sessions) { session in
                    Menu(session.name) {
                        Button("Start Session") {
                            SessionStartOverlay.show(sessionName: session.name)
                            guard SessionLauncher.restore(session) else {
                                return
                            }

                            commandRunStore.startAll(for: session)
                            workspaceRuntimeStore.markStarted(session)
                        }

                        Button("Open URLs") {
                            SessionLauncher.launchURLs(for: session)
                        }

                        Button("Open in Cursor") {
                            SessionLauncher.openRepositoryInCursor(session)
                        }

                        Button("Shutdown Workspace") {
                            commandRunStore.stopAll(for: session)
                            workspaceRuntimeStore.markStopped(session)
                        }
                        .disabled(!workspaceRuntimeStore.isActive(session))

                        Button("Copy Commands") {
                            CommandClipboard.copyCommands(for: session)
                        }
                        .disabled(session.commands.isEmpty)

                        Button("Copy cd + Commands") {
                            CommandClipboard.copyRepositoryPathAndCommands(for: session)
                        }
                        .disabled(session.commands.isEmpty || session.repositoryPath.isEmpty)

                        Button("Copy Shell Chain") {
                            CommandClipboard.copyShellChain(for: session)
                        }
                        .disabled(session.commands.isEmpty || session.repositoryPath.isEmpty)
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
