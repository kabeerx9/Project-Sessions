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
    
    private func addSession() {
        sessions.append(
            ProjectSession(
                id: UUID(),
                name: "New Session",
                browser: "Chrome",
                urls: [],
                repositoryPath: "~/Projects/new-session"
            )
        )

        saveSessions()
    }

    private func deleteSession(_ session: ProjectSession) {
        sessions.removeAll { $0.id == session.id }
        saveSessions()
    }
    
    private func printSessionsJSON() {
        do {
            let data = try JSONEncoder().encode(sessions)
            let json = String(data: data, encoding: .utf8) ?? ""
            print(json)
        } catch {
            print("Failed to encode sessions: \(error)")
        }
    }

    private func testDecodeSessions() {
        do {
            let data = try JSONEncoder().encode(sessions)
            let decodedSessions = try JSONDecoder().decode([ProjectSession].self, from: data)
            print("Decoded \(decodedSessions.count) sessions")
        } catch {
            print("Failed to decode sessions: \(error)")
        }
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
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Project Sessions")
                        .font(.largeTitle)

                    Text("Restore your development workspace.")
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button("Create Session") {
                    isShowingNewSessionForm = true
                }
            }

            List {
                ForEach(sessions) { session in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(session.name)
                            .font(.headline)

                        Text(session.repositoryPath)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text("\(session.browser) · \(session.urls.count) URLs")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        
                        Button("Delete Session") {
                            deleteSession(session)
                        }
                        
                        Button("Edit") {
                            startEditing(session)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onDelete { indexSet in
                    sessions.remove(atOffsets: indexSet)
                    saveSessions()
                }
            }
            .frame(minHeight: 180)

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
                        sessions.append(
                            ProjectSession(
                                id: UUID(),
                                name: newSessionName,
                                browser: newSessionBrowser,
                                urls: newSessionURLs,
                                repositoryPath: newSessionRepositoryPath
                            )
                        )

                        saveSessions()
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
