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
                    addSession()
                    printSessionsJSON()
                    testDecodeSessions()
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
                    }
                    .padding(.vertical, 4)
                }
                .onDelete { indexSet in
                    sessions.remove(atOffsets: indexSet)
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
    }
}
#Preview {
    ContentView()
}
