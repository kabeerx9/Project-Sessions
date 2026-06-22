//
//  ContentView.swift
//  ProjectSessions
//
//  Created by Kabeer Joshi on 21/06/26.
//

import SwiftUI


private let sessionsKey = "projectSessions"



struct ContentView: View {
    @State private var sessions = [
        ProjectSession(
            id : UUID(),
            name: "Fantasy App",
            browser: .chrome,
            urls: ["https://github.com", "http://localhost:3000"],
            repositoryPath: "~/Projects/fantasy-app",
            commands: ["pnpm dev", "expo start"]
        ),
        ProjectSession(
            id : UUID(),
            name: "Dashboard",
            browser: .chrome,
            urls: ["https://figma.com"],
            repositoryPath: "~/Projects/dashboard",
            commands: ["npm run dev"]
        ),
        ProjectSession(
            id : UUID(),
            name: "SaaS",
            browser: .safari,
            urls: ["https://developer.apple.com"],
            repositoryPath: "~/Projects/saas",
            commands: []
        )
    ]
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
    
    @State private var sessionToDelete: ProjectSession?

    private func chooseRepositoryPathForNewSession() {
        guard let path = chooseRepositoryPath() else {
            return
        }

        newSessionRepositoryPath = path
    }
    
    private var selectedSession: ProjectSession? {
        sessions.first { $0.id == selectedSessionID }
    }

    private func deleteSession(_ session: ProjectSession) {
        sessions.removeAll { $0.id == session.id }
        
        if selectedSessionID == session.id {
            selectedSessionID = nil
        }
        
        saveSessions()
    }
    
    private func deleteSessions(at offsets: IndexSet) {
        let deletedIDs = offsets.map { sessions[$0].id }
        sessions.remove(atOffsets: offsets)
        
        if let selectedSessionID, deletedIDs.contains(selectedSessionID) {
            self.selectedSessionID = nil
        }
        
        saveSessions()
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
    
    private func saveSessions() {
        do {
            let data = try JSONEncoder().encode(sessions)
            UserDefaults.standard.set(data, forKey: sessionsKey)
        } catch {
            print("Failed to save sessions: \(error)")
        }
    }

    private func loadSessions() {
        guard let data = UserDefaults.standard.data(forKey: sessionsKey) else {
            return
        }

        do {
            sessions = try JSONDecoder().decode([ProjectSession].self, from: data)
        } catch {
            print("Failed to load sessions: \(error)")
        }
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

        guard let index = sessions.firstIndex(where: { $0.id == editingSession.id }) else {
            return
        }

        sessions[index] = ProjectSession(
            id: editingSession.id,
            name: editSessionName,
            browser: editSessionBrowser,
            urls: editSessionURLs,
            repositoryPath: editSessionRepositoryPath,
            commands: editSessionCommands
        )

        saveSessions()
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
                sessions: sessions,
                selectedSessionID: $selectedSessionID,
                onCreateSession: {
                    isShowingNewSessionForm = true
                },
                onDeleteSessions: deleteSessions
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
                    sessionToDelete = session
                }
            )
        }
        .onAppear {
            loadSessions()
        }
        .toolbar {
            Button {
                isShowingNewSessionForm = true
            } label: {
                Label("New Session", systemImage: "plus")
            }
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

                    sessions.append(newSession)

                    saveSessions()
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
            "Delete Session?",
            isPresented: Binding(
                get: {
                    sessionToDelete != nil
                },
                set: { isPresented in
                    if !isPresented {
                        sessionToDelete = nil
                    }
                }
            ),
            presenting: sessionToDelete
        ) { session in
            Button("Cancel", role: .cancel) {
                sessionToDelete = nil
            }

            Button("Delete", role: .destructive) {
                deleteSession(session)
                sessionToDelete = nil
            }
        } message: { session in
            Text("This will delete \(session.name).")
        }
    }
}
#Preview {
    ContentView()
}
