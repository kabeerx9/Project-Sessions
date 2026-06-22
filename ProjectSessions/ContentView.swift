//
//  ContentView.swift
//  ProjectSessions
//
//  Created by Kabeer Joshi on 21/06/26.
//

import SwiftUI

struct ContentView: View {
    let sessionStore: SessionStore
    @State private var selectedSessionID: ProjectSession.ID?
    
    @State private var isShowingNewSessionForm = false

    
    @State private var newSessionName = ""
    @State private var newSessionBrowser = Browser.chrome
    @State private var newSessionRepositoryPath = ""
    @State private var newSessionURLs: [String] = []
    @State private var newSessionURLDraft = ""
    @State private var newSessionCommands: [TerminalCommand] = []
    @State private var newSessionCommandNameDraft = ""
    @State private var newSessionCommandDraft = ""
    @State private var newSessionCommandRunsInSeparateTab = true
    
    
    @State private var editingSession: ProjectSession?
    @State private var editSessionName = ""
    @State private var editSessionBrowser = Browser.chrome
    @State private var editSessionRepositoryPath = ""
    @State private var editSessionURLs: [String] = []
    @State private var editSessionURLDraft = ""
    @State private var editSessionCommands: [TerminalCommand] = []
    @State private var editSessionCommandNameDraft = ""
    @State private var editSessionCommandDraft = ""
    @State private var editSessionCommandRunsInSeparateTab = true
    
    @State private var sessionsToDelete: [ProjectSession] = []

    private func chooseRepositoryPathForNewSession() {
        guard let path = RepositoryFolderPicker.chooseRepositoryPath() else {
            return
        }

        newSessionRepositoryPath = path
    }
    
    private var selectedSession: ProjectSession? {
        sessionStore.sessions.first { $0.id == selectedSessionID }
    }

    private func confirmDeleteSessions(at offsets: IndexSet) {
        sessionsToDelete = offsets.map { sessionStore.sessions[$0] }
    }

    private func deleteSessions(_ sessionsToDelete: [ProjectSession]) {
        let deletedIDs = sessionsToDelete.map(\.id)
        sessionStore.deleteSessions(sessionsToDelete)
        
        if let selectedSessionID, deletedIDs.contains(selectedSessionID) {
            self.selectedSessionID = nil
        }
    }

    private func resetNewSessionForm() {
        newSessionName = ""
        newSessionBrowser = .chrome
        newSessionRepositoryPath = ""
        newSessionURLs = []
        newSessionURLDraft = ""
        newSessionCommands = []
        newSessionCommandNameDraft = ""
        newSessionCommandDraft = ""
        newSessionCommandRunsInSeparateTab = true
    }

    private func startEditing(_ session: ProjectSession) {
        editingSession = session
        editSessionName = session.name
        editSessionBrowser = session.browser
        editSessionRepositoryPath = session.repositoryPath
        editSessionURLs = session.urls
        editSessionURLDraft = ""
        editSessionCommands = session.commands
        editSessionCommandNameDraft = ""
        editSessionCommandDraft = ""
        editSessionCommandRunsInSeparateTab = true
    }

    private func chooseRepositoryPathForEditSession() {
        guard let path = RepositoryFolderPicker.chooseRepositoryPath() else {
            return
        }

        editSessionRepositoryPath = path
    }

    private func saveEditedSession() {
        guard let editingSession else {
            return
        }

        let updatedSession = ProjectSession(
            id: editingSession.id,
            name: editSessionName,
            browser: editSessionBrowser,
            urls: editSessionURLs,
            repositoryPath: editSessionRepositoryPath,
            commands: editSessionCommands
        )

        sessionStore.updateSession(updatedSession)
        self.editingSession = nil
    }
    
    var body: some View {
        NavigationSplitView {
            SessionSidebarView(
                sessions: sessionStore.sessions,
                selectedSessionID: $selectedSessionID,
                onDeleteSessions: confirmDeleteSessions
            )
        } detail: {
            SessionDetailView(
                session: selectedSession,
                onRestore: { session in
                    SessionLauncher.restore(session)
                },
                onLaunch: { session in
                    SessionLauncher.launchURLs(for: session)
                },
                onOpenFolder: { session in
                    SessionLauncher.openRepositoryInFinder(session)
                },
                onOpenInCursor: { session in
                    SessionLauncher.openRepositoryInCursor(session)
                },
                onOpenInGhostty: { session in
                    SessionLauncher.openRepositoryInGhostty(session)
                },
                onRunCommandsInGhostty: { session in
                    SessionLauncher.runCommandsInGhostty(for: session)
                },
                onCopyCommands: { session in
                    CommandClipboard.copyCommands(for: session)
                },
                onCopyRepositoryPathAndCommands: { session in
                    CommandClipboard.copyRepositoryPathAndCommands(for: session)
                },
                onCopyShellChain: { session in
                    CommandClipboard.copyShellChain(for: session)
                },
                onEdit: startEditing,
                onDelete: { session in
                    sessionsToDelete = [session]
                }
            )
        }
        .toolbar {
            Button {
                isShowingNewSessionForm = true
            } label: {
                Label("New Session", systemImage: "plus")
            }
            .keyboardShortcut("n", modifiers: .command)
        }
        .sheet(isPresented: $isShowingNewSessionForm) {
            SessionFormView(
                title: nil,
                name: $newSessionName,
                browser: $newSessionBrowser,
                repositoryPath: $newSessionRepositoryPath,
                urls: $newSessionURLs,
                urlDraft: $newSessionURLDraft,
                commands: $newSessionCommands,
                commandNameDraft: $newSessionCommandNameDraft,
                commandDraft: $newSessionCommandDraft,
                commandRunsInSeparateTab: $newSessionCommandRunsInSeparateTab,
                onChooseFolder: {
                    chooseRepositoryPathForNewSession()
                },
                onCancel: {
                    resetNewSessionForm()
                    isShowingNewSessionForm = false
                },
                onSave: {
                    let newSession = ProjectSession(
                        id: UUID(),
                        name: newSessionName,
                        browser: newSessionBrowser,
                        urls: newSessionURLs,
                        repositoryPath: newSessionRepositoryPath,
                        commands: newSessionCommands
                    )

                    sessionStore.addSession(newSession)
                    selectedSessionID = newSession.id
                    resetNewSessionForm()
                    isShowingNewSessionForm = false
                }
            )
        }
        .sheet(item: $editingSession) { _ in
            SessionFormView(
                title: "Edit Session",
                name: $editSessionName,
                browser: $editSessionBrowser,
                repositoryPath: $editSessionRepositoryPath,
                urls: $editSessionURLs,
                urlDraft: $editSessionURLDraft,
                commands: $editSessionCommands,
                commandNameDraft: $editSessionCommandNameDraft,
                commandDraft: $editSessionCommandDraft,
                commandRunsInSeparateTab: $editSessionCommandRunsInSeparateTab,
                onChooseFolder: {
                    chooseRepositoryPathForEditSession()
                },
                onCancel: {
                    editingSession = nil
                },
                onSave: {
                    saveEditedSession()
                }
            )
        }
        .alert(
            deleteAlertTitle,
            isPresented: Binding(
                get: {
                    !sessionsToDelete.isEmpty
                },
                set: { isPresented in
                    if !isPresented {
                        sessionsToDelete = []
                    }
                }
            )
        ) {
            Button("Cancel", role: .cancel) {
                sessionsToDelete = []
            }

            Button("Delete", role: .destructive) {
                deleteSessions(sessionsToDelete)
                sessionsToDelete = []
            }
        } message: {
            Text(deleteAlertMessage)
        }
    }

    private var deleteAlertTitle: String {
        sessionsToDelete.count == 1 ? "Delete Session?" : "Delete Sessions?"
    }

    private var deleteAlertMessage: String {
        if let session = sessionsToDelete.first, sessionsToDelete.count == 1 {
            return "This will delete \(session.name)."
        }

        return "This will delete \(sessionsToDelete.count) sessions."
    }
}
#Preview {
    ContentView(sessionStore: SessionStore())
}
