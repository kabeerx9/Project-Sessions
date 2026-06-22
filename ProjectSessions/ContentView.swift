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
            browser: "Chrome",
            urls: ["https://github.com", "http://localhost:3000"],
            repositoryPath: "~/Projects/fantasy-app"
        ),
        ProjectSession(
            id : UUID(),
            name: "Dashboard",
            browser: "Chrome",
            urls: ["https://figma.com"],
            repositoryPath: "~/Projects/dashboard"
        ),
        ProjectSession(
            id : UUID(),
            name: "SaaS",
            browser: "Safari",
            urls: ["https://developer.apple.com"],
            repositoryPath: "~/Projects/saas"
        )
    ]
    @State private var selectedSessionID: ProjectSession.ID?
    
    @State private var isShowingNewSessionForm = false

    
    @State private var newSessionName = ""
    @State private var newSessionBrowser = "Chrome"
    @State private var newSessionRepositoryPath = ""
    @State private var newSessionURLs: [String] = []
    @State private var newSessionURLDraft = ""
    
    
    @State private var editingSession: ProjectSession?
    @State private var editSessionName = ""
    @State private var editSessionBrowser = "Chrome"
    @State private var editSessionRepositoryPath = ""
    @State private var editSessionURLs: [String] = []
    @State private var editSessionURLDraft = ""

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
                openURLWithSystemOpenCommand(url)
            }
        }
    }

    private func openURLWithSystemOpenCommand(_ url: URL) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = [url.absoluteString]

        do {
            try process.run()
        } catch {
            print("Could not open URL with /usr/bin/open: \(url.absoluteString), error: \(error)")
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
        newSessionBrowser = "Chrome"
        newSessionRepositoryPath = ""
        newSessionURLs = []
        newSessionURLDraft = ""
    }

    private func startEditing(_ session: ProjectSession) {
        editingSession = session
        editSessionName = session.name
        editSessionBrowser = session.browser
        editSessionRepositoryPath = session.repositoryPath
        editSessionURLs = session.urls
        editSessionURLDraft = ""
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
            repositoryPath: editSessionRepositoryPath
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
                onDelete: deleteSession
            )
        }
        .onAppear {
            loadSessions()
        }
        .sheet(isPresented: $isShowingNewSessionForm) {
            SessionFormView(
                title: nil,
                name: $newSessionName,
                browser: $newSessionBrowser,
                repositoryPath: $newSessionRepositoryPath,
                urls: $newSessionURLs,
                urlDraft: $newSessionURLDraft,
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
                        repositoryPath: newSessionRepositoryPath
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
    }
}
#Preview {
    ContentView()
}
