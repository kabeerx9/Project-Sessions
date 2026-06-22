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
    @State private var newSessionCommands: [String] = []
    @State private var newSessionCommandDraft = ""
    
    
    @State private var editingSession: ProjectSession?
    @State private var editSessionName = ""
    @State private var editSessionBrowser = Browser.chrome
    @State private var editSessionRepositoryPath = ""
    @State private var editSessionURLs: [String] = []
    @State private var editSessionURLDraft = ""
    @State private var editSessionCommands: [String] = []
    @State private var editSessionCommandDraft = ""
    
    @State private var sessionsToDelete: [ProjectSession] = []

    private func chooseRepositoryPathForNewSession() {
        guard let path = chooseRepositoryPath() else {
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

    private func launchSession(_ session: ProjectSession) {
        var urlsToOpen: [URL] = []
        
        for urlString in session.urls {
            if let url = normalizedWebURL(from: urlString) {
                urlsToOpen.append(url)
            } else {
                print("Skipping invalid URL: \(urlString)")
            }
        }
        
        for (index, url) in urlsToOpen.enumerated() {
            let delay = Double(index) * 1.0

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                print("Opening URL: \(url.absoluteString)")
                openURLWithSystemOpenCommand(url, browser: session.browser)
            }
        }
    }

    private func openURLWithSystemOpenCommand(_ url: URL, browser: Browser) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-a", browser.appName, url.absoluteString]

        do {
            try process.run()
        } catch {
            print("Could not open URL in \(browser.appName): \(url.absoluteString), error: \(error)")
            NSWorkspace.shared.open(url)
        }
    }
    
    private func normalizedWebURL(from urlString: String) -> URL? {
        let trimmedURLString = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedURLString.isEmpty else {
            return nil
        }
        
        if let url = URL(string: trimmedURLString), url.scheme != nil {
            return url
        }
        
        return URL(string: "https://\(trimmedURLString)")
    }
    
    private func resetNewSessionForm() {
        newSessionName = ""
        newSessionBrowser = .chrome
        newSessionRepositoryPath = ""
        newSessionURLs = []
        newSessionURLDraft = ""
        newSessionCommands = []
        newSessionCommandDraft = ""
    }

    private func startEditing(_ session: ProjectSession) {
        editingSession = session
        editSessionName = session.name
        editSessionBrowser = session.browser
        editSessionRepositoryPath = session.repositoryPath
        editSessionURLs = session.urls
        editSessionURLDraft = ""
        editSessionCommands = session.commands
        editSessionCommandDraft = ""
    }

    private func chooseRepositoryPathForEditSession() {
        guard let path = chooseRepositoryPath() else {
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
    
    private func expandedPath(_ path: String) -> String {
        let trimmedPath = path.trimmingCharacters(in: .whitespacesAndNewlines)
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser.path
        
        if trimmedPath.hasPrefix("~/") {
            return homeDirectory + trimmedPath.dropFirst()
        }
        
        if trimmedPath.hasPrefix("/") {
            return trimmedPath
        }

        return "\(homeDirectory)/\(trimmedPath)"
    }

    private func chooseRepositoryPath() -> String? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        panel.title = "Choose Repository Folder"
        panel.prompt = "Choose"

        let response = panel.runModal()

        guard response == .OK, let url = panel.url else {
            return nil
        }

        return url.path
    }
    
    private func openRepositoryInFinder(_ session: ProjectSession) {
        let expandedRepositoryPath = expandedPath(session.repositoryPath)
        let repositoryURL = URL(fileURLWithPath: expandedRepositoryPath)
        
        guard FileManager.default.fileExists(atPath: expandedRepositoryPath) else {
            print("Repository path does not exist: \(expandedRepositoryPath)")
            return
        }

        print("Opening repository folder: \(expandedRepositoryPath)")
        
        let didOpen = NSWorkspace.shared.open(repositoryURL)
        
        if !didOpen {
            print("Could not open repository folder: \(expandedRepositoryPath)")
        }
    }
    
    private func openRepositoryInCursor(_ session: ProjectSession) {
        let expandedRepositoryPath = expandedPath(session.repositoryPath)

        guard FileManager.default.fileExists(atPath: expandedRepositoryPath) else {
            print("Repository path does not exist: \(expandedRepositoryPath)")
            return
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-a", "Cursor", expandedRepositoryPath]

        do {
            try process.run()
        } catch {
            print("Could not open repository in Cursor: \(error)")
        }
    }

    private func restoreSession(_ session: ProjectSession) {
        launchSession(session)
        openRepositoryInCursor(session)
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
                onRestore: restoreSession,
                onLaunch: launchSession,
                onOpenFolder: openRepositoryInFinder,
                onOpenInCursor: openRepositoryInCursor,
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
                commandDraft: $newSessionCommandDraft,
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
                commandDraft: $editSessionCommandDraft,
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
