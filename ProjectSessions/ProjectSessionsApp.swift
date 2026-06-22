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
    }
}
