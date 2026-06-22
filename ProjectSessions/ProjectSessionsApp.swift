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
    @State private var terminalProcessStore = TerminalProcessStore()
    @State private var workspaceRuntimeStore = WorkspaceRuntimeStore()
    @State private var experimentalCommandRunStore = ExperimentalCommandRunStore()
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView(
                sessionStore: sessionStore,
                terminalProcessStore: terminalProcessStore,
                workspaceRuntimeStore: workspaceRuntimeStore,
                experimentalCommandRunStore: experimentalCommandRunStore
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
                            workspaceRuntimeStore.markStarted(session)
                            SessionLauncher.restore(session, terminalProcessStore: terminalProcessStore)
                        }

                        Button("Open URLs") {
                            SessionLauncher.launchURLs(for: session)
                        }

                        Button("Open in Cursor") {
                            SessionLauncher.openRepositoryInCursor(session)
                        }

                        Button("Run Commands in Terminal") {
                            SessionLauncher.runCommandsInTerminal(
                                for: session,
                                terminalProcessStore: terminalProcessStore
                            )
                        }
                        .disabled(session.repositoryPath.isEmpty || session.commands.isEmpty)

                        Button("Stop Commands") {
                            SessionLauncher.stopTerminalProcesses(
                                for: session,
                                terminalProcessStore: terminalProcessStore
                            )
                        }
                        .disabled(terminalProcessStore.runningCount(for: session) == 0)

                        Button("Shutdown Workspace") {
                            SessionLauncher.shutdownWorkspace(
                                for: session,
                                terminalProcessStore: terminalProcessStore
                            )
                            workspaceRuntimeStore.markStopped(session)
                        }
                        .disabled(!workspaceRuntimeStore.isActive(session) && terminalProcessStore.records(for: session).isEmpty)

                        Button("Refresh Health") {
                            terminalProcessStore.refresh()
                        }

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
