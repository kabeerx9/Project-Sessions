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

        launchURLs(urlsToOpen, browser: session.browser, profileName: session.browserProfileName)
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

    private static func launchURLs(_ urls: [URL], browser: Browser, profileName: String) {
        let trimmedProfileName = profileName.trimmingCharacters(in: .whitespacesAndNewlines)

        if !trimmedProfileName.isEmpty && !browser.supportsProfiles {
            showLaunchAlert(
                title: "\(browser.rawValue) Profiles Are Not Supported",
                message: "Project Sessions can use profile names with Chrome and Brave."
            )
        }

        if !trimmedProfileName.isEmpty && browser.supportsProfiles {
            openURLsWithBrowserProfile(urls, browser: browser, profileName: trimmedProfileName)
            return
        }

        for (index, url) in urls.enumerated() {
            let delay = Double(index) * 1.0

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                print("Opening URL: \(url.absoluteString)")
                openURLWithSystemOpenCommand(url, browser: browser)
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

    private static func openURLsWithBrowserProfile(_ urls: [URL], browser: Browser, profileName: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = [
            "-na",
            browser.appName,
            "--args",
            "--profile-directory=\(profileName)"
        ] + urls.map(\.absoluteString)

        do {
            try process.run()
            process.waitUntilExit()

            if process.terminationStatus != 0 {
                showLaunchAlert(
                    title: "Could Not Open \(browser.rawValue) Profile",
                    message: "Check that the profile directory name is correct."
                )
            }
        } catch {
            showLaunchAlert(
                title: "Could Not Open \(browser.rawValue) Profile",
                message: error.localizedDescription
            )
        }
    }

    private static func browserIsInstalled(_ browser: Browser) -> Bool {
        BrowserDetector.isInstalled(browser)
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
}
