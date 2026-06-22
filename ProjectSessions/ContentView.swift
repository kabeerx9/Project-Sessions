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
    
    private func addNewSessionURL() {
        guard !newSessionURLDraft.isEmpty else {
            return
        }

        newSessionURLs.append(newSessionURLDraft)
        newSessionURLDraft = ""
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
    
    private var canSaveNewSession: Bool {
        !newSessionName.isEmpty && !newSessionRepositoryPath.isEmpty
    }
    
    private func resetNewSessionForm() {
        newSessionName = ""
        newSessionBrowser = "Chrome"
        newSessionRepositoryPath = ""
        newSessionURLs = []
        newSessionURLDraft = ""
    }
    
    private var canSaveEditedSession: Bool {
        !editSessionName.isEmpty && !editSessionRepositoryPath.isEmpty
    }

    private func startEditing(_ session: ProjectSession) {
        editingSession = session
        editSessionName = session.name
        editSessionBrowser = session.browser
        editSessionRepositoryPath = session.repositoryPath
        editSessionURLs = session.urls
        editSessionURLDraft = ""
    }

    private func addEditSessionURL() {
        guard !editSessionURLDraft.isEmpty else {
            return
        }

        editSessionURLs.append(editSessionURLDraft)
        editSessionURLDraft = ""
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
    
    
    var body: some View {
        NavigationSplitView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Project Sessions")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button("Create") {
                        isShowingNewSessionForm = true
                    }
                }
                .padding([.horizontal, .top])
                
                if sessions.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: "folder.badge.plus")
                            .font(.title)
                            .foregroundStyle(.secondary)
                        
                        Text("No sessions yet.")
                            .font(.headline)
                        
                        Text("Create your first project session.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    
                    Spacer()
                } else {
                    List(selection: $selectedSessionID) {
                        ForEach(sessions) { session in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(session.name)
                                    .font(.headline)
                                
                                Text("\(session.browser) · \(session.urls.count) URLs")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                            .tag(session.id)
                        }
                        .onDelete(perform: deleteSessions)
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 220, ideal: 260)
        } detail: {
            if let selectedSession {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(selectedSession.name)
                                .font(.largeTitle)
                            
                            Text(selectedSession.repositoryPath)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("Launch Session") {
                            launchSession(selectedSession)
                        }
                        .disabled(selectedSession.urls.isEmpty)
                        
                        Button("Edit") {
                            startEditing(selectedSession)
                        }
                        
                        Button("Delete") {
                            deleteSession(selectedSession)
                        }
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Browser")
                            .font(.headline)
                        
                        Text(selectedSession.browser)
                            .foregroundStyle(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("URLs")
                            .font(.headline)
                        
                        if selectedSession.urls.isEmpty {
                            Text("No URLs saved.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(selectedSession.urls, id: \.self) { url in
                                Text(url)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "sidebar.left")
                        .font(.system(size: 44))
                        .foregroundStyle(.secondary)
                    
                    Text("Select a session")
                        .font(.title2)
                    
                    Text("Choose a project session from the sidebar to view its details.")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            loadSessions()
        }
        .sheet(isPresented: $isShowingNewSessionForm) {
            Form {
                TextField("Session name", text: $newSessionName)
                TextField("Browser", text: $newSessionBrowser)
                TextField("Repository path", text: $newSessionRepositoryPath)
                TextField("URL", text: $newSessionURLDraft)

                Button("Add URL") {
                    addNewSessionURL()
                }
                .disabled(newSessionURLDraft.isEmpty)

                ForEach(newSessionURLs, id: \.self) { url in
                    HStack {
                        Text(url)
                        Spacer()
                        Button("Remove") {
                            newSessionURLs.removeAll { $0 == url }
                        }
                    }
                }

                HStack {
                    Button("Cancel") {
                        resetNewSessionForm()
                        isShowingNewSessionForm = false
                    }

                    Spacer()

                    Button("Save") {
                        let newSession = ProjectSession(
                            id: UUID(),
                            name: newSessionName,
                            browser: newSessionBrowser,
                            urls: newSessionURLs,
                            repositoryPath: newSessionRepositoryPath
                        )
                        
                        sessions.append(
                            newSession
                        )

                        saveSessions()
                        selectedSessionID = newSession.id
                        resetNewSessionForm()
                        isShowingNewSessionForm = false
                    }
                    .disabled(!canSaveNewSession)
                }
            }
            .padding()
            .frame(width: 420)
        }
        .sheet(item: $editingSession) { _ in
            Form {
                Text("Edit Session")
                    .font(.title)

                TextField("Session name", text: $editSessionName)
                TextField("Browser", text: $editSessionBrowser)
                TextField("Repository path", text: $editSessionRepositoryPath)
                TextField("URL", text: $editSessionURLDraft)

                Button("Add URL") {
                    addEditSessionURL()
                }
                .disabled(editSessionURLDraft.isEmpty)

                ForEach(editSessionURLs, id: \.self) { url in
                    HStack {
                        Text(url)
                        Spacer()
                        Button("Remove") {
                            editSessionURLs.removeAll { $0 == url }
                        }
                    }
                }

                HStack {
                    Button("Cancel") {
                        editingSession = nil
                    }

                    Spacer()

                    Button("Save") {
                        saveEditedSession()
                    }
                    .disabled(!canSaveEditedSession)
                }
            }
            .padding()
            .frame(width: 420)
        }
    }
}
#Preview {
    ContentView()
}
