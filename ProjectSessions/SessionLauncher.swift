import AppKit
import Foundation

enum SessionLauncher {
    static func restore(_ session: ProjectSession) {
        launchURLs(for: session)

        let expandedRepositoryPath = expandedPath(session.repositoryPath)

        guard repositoryPathExists(expandedRepositoryPath) else {
            showRepositoryPathAlert(expandedRepositoryPath)
            return
        }

        openRepositoryInCursor(session)

        if !session.commands.isEmpty {
            runCommandsInTerminal(for: session)
        }
    }

    static func launchURLs(for session: ProjectSession) {
        var urlsToOpen: [URL] = []
        var invalidURLs: [String] = []

        for urlString in session.urls {
            if let url = normalizedWebURL(from: urlString) {
                urlsToOpen.append(url)
            } else {
                invalidURLs.append(urlString)
            }
        }

        if !invalidURLs.isEmpty {
            showLaunchAlert(
                title: "Some URLs Could Not Open",
                message: invalidURLs.joined(separator: "\n")
            )
        }

        guard !urlsToOpen.isEmpty else {
            return
        }

        guard browserIsInstalled(session.browser) else {
            showLaunchAlert(
                title: "\(session.browser.rawValue) Is Not Installed",
                message: "Install \(session.browser.rawValue), or choose a different browser for this session."
            )
            return
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

        guard repositoryPathExists(expandedRepositoryPath) else {
            showRepositoryPathAlert(expandedRepositoryPath)
            return
        }

        print("Opening repository folder: \(expandedRepositoryPath)")

        let didOpen = NSWorkspace.shared.open(repositoryURL)

        if !didOpen {
            showLaunchAlert(
                title: "Could Not Open Folder",
                message: expandedRepositoryPath
            )
        }
    }

    static func openRepositoryInCursor(_ session: ProjectSession) {
        let expandedRepositoryPath = expandedPath(session.repositoryPath)

        guard repositoryPathExists(expandedRepositoryPath) else {
            showRepositoryPathAlert(expandedRepositoryPath)
            return
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-a", "Cursor", expandedRepositoryPath]

        do {
            try process.run()
            process.waitUntilExit()

            if process.terminationStatus != 0 {
                showLaunchAlert(
                    title: "Could Not Open Cursor",
                    message: "Make sure Cursor is installed, then try again."
                )
            }
        } catch {
            showLaunchAlert(
                title: "Could Not Open Cursor",
                message: error.localizedDescription
            )
        }
    }

    static func runCommandsInTerminal(for session: ProjectSession) {
        let expandedRepositoryPath = expandedPath(session.repositoryPath)

        guard repositoryPathExists(expandedRepositoryPath) else {
            showRepositoryPathAlert(expandedRepositoryPath)
            return
        }

        let plans = TerminalLaunchPlanner.plans(for: session)

        guard !plans.isEmpty else {
            return
        }

        let terminalWasRunning = isTerminalRunning()

        for (index, plan) in plans.enumerated() {
            let delay = Double(index) * 0.5

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                launchTerminalCommand(
                    workingDirectory: expandedRepositoryPath,
                    plan: plan,
                    reuseFrontWindowIfAvailable: !terminalWasRunning && index == 0
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
            process.waitUntilExit()

            if process.terminationStatus != 0 {
                NSWorkspace.shared.open(url)
            }
        } catch {
            NSWorkspace.shared.open(url)
        }
    }

    private static func browserIsInstalled(_ browser: Browser) -> Bool {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: browser.bundleIdentifier) != nil
    }

    private static func repositoryPathExists(_ path: String) -> Bool {
        var isDirectory: ObjCBool = false

        return FileManager.default.fileExists(
            atPath: path,
            isDirectory: &isDirectory
        ) && isDirectory.boolValue
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
        plan: TerminalLaunchPlan,
        reuseFrontWindowIfAvailable: Bool
    ) {
        let shellCommand = "cd \(shellQuoted(workingDirectory)) && \(plan.shellCommand)"
        let script: String

        if reuseFrontWindowIfAvailable {
            script = """
            tell application "Terminal"
                activate
                delay 0.4
                if (count of windows) is 0 then
                    do script "\(appleScriptEscaped(shellCommand))"
                else
                    do script "\(appleScriptEscaped(shellCommand))" in selected tab of front window
                end if
            end tell
            """
        } else {
            script = """
            tell application "Terminal"
                do script "\(appleScriptEscaped(shellCommand))"
                activate
            end tell
            """
        }

        var error: NSDictionary?

        guard let appleScript = NSAppleScript(source: script) else {
            print("Could not create Terminal AppleScript for command: \(plan.title)")
            return
        }

        appleScript.executeAndReturnError(&error)

        if let error {
            print("Could not run Terminal command \(plan.title): \(error)")
            showTerminalAutomationPermissionAlertIfNeeded(error)
        } else {
            print("Opening Terminal command: \(plan.title)")
        }
    }

    private static func isTerminalRunning() -> Bool {
        !NSRunningApplication.runningApplications(
            withBundleIdentifier: "com.apple.Terminal"
        ).isEmpty
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

    private static func showRepositoryPathAlert(_ path: String) {
        showLaunchAlert(
            title: "Repository Folder Not Found",
            message: path
        )
    }

    private static func showLaunchAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = title
            alert.informativeText = message
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }

    private static func shellQuoted(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
    }

    private static func appleScriptEscaped(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }

    private static func showTerminalAutomationPermissionAlertIfNeeded(_ error: NSDictionary) {
        let errorNumber = error[NSAppleScript.errorNumber] as? Int

        guard errorNumber == -1743 else {
            return
        }

        let alert = NSAlert()
        alert.messageText = "Terminal Permission Needed"
        alert.informativeText = """
        Project Sessions needs permission to control Terminal so it can run saved project commands.

        Open System Settings > Privacy & Security > Automation, then enable Terminal under ProjectSessions.
        """
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "OK")

        let response = alert.runModal()

        if response == .alertFirstButtonReturn,
           let settingsURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") {
            NSWorkspace.shared.open(settingsURL)
        }
    }
}
