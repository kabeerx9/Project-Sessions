import AppKit
import Foundation

enum SessionLauncher {
    static func restore(_ session: ProjectSession) {
        launchURLs(for: session)
        openRepositoryInCursor(session)

        if session.commands.isEmpty {
            openRepositoryInGhostty(session)
        } else {
            runCommandsInTerminal(for: session)
        }
    }

    static func launchURLs(for session: ProjectSession) {
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

    static func openRepositoryInFinder(_ session: ProjectSession) {
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

    static func openRepositoryInCursor(_ session: ProjectSession) {
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

    static func openRepositoryInGhostty(_ session: ProjectSession) {
        let expandedRepositoryPath = expandedPath(session.repositoryPath)

        guard FileManager.default.fileExists(atPath: expandedRepositoryPath) else {
            print("Repository path does not exist: \(expandedRepositoryPath)")
            return
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = [
            "-na",
            "Ghostty.app",
            "--args",
            "--working-directory=\(expandedRepositoryPath)",
            "--window-save-state=never"
        ]

        do {
            try process.run()
        } catch {
            print("Could not open repository in Ghostty: \(error)")
        }
    }

    static func runCommandsInTerminal(for session: ProjectSession) {
        let expandedRepositoryPath = expandedPath(session.repositoryPath)

        guard FileManager.default.fileExists(atPath: expandedRepositoryPath) else {
            print("Repository path does not exist: \(expandedRepositoryPath)")
            return
        }

        let plans = TerminalLaunchPlanner.plans(for: session)

        guard !plans.isEmpty else {
            openRepositoryInGhostty(session)
            return
        }

        for (index, plan) in plans.enumerated() {
            let delay = Double(index) * 0.5

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                launchTerminalCommand(
                    workingDirectory: expandedRepositoryPath,
                    plan: plan
                )
            }
        }
    }

    private static func openURLWithSystemOpenCommand(_ url: URL, browser: Browser) {
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

    private static func normalizedWebURL(from urlString: String) -> URL? {
        let trimmedURLString = urlString.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedURLString.isEmpty else {
            return nil
        }

        if let url = URL(string: trimmedURLString), url.scheme != nil {
            return url
        }

        return URL(string: "https://\(trimmedURLString)")
    }

    private static func launchTerminalCommand(
        workingDirectory: String,
        plan: TerminalLaunchPlan
    ) {
        let shellCommand = "cd \(shellQuoted(workingDirectory)) && \(plan.shellCommand)"
        let script = """
        tell application "Terminal"
            activate
            do script "\(appleScriptEscaped(shellCommand))"
        end tell
        """

        var error: NSDictionary?

        guard let appleScript = NSAppleScript(source: script) else {
            print("Could not create Terminal AppleScript for command: \(plan.title)")
            return
        }

        appleScript.executeAndReturnError(&error)

        if let error {
            print("Could not run Terminal command \(plan.title): \(error)")
        } else {
            print("Opening Terminal command: \(plan.title)")
        }
    }

    private static func expandedPath(_ path: String) -> String {
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

    private static func shellQuoted(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
    }

    private static func appleScriptEscaped(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
}
