import AppKit
import Foundation

enum SessionLauncher {
    static func restore(_ session: ProjectSession, terminalProcessStore: TerminalProcessStore) {
        launchURLs(for: session)

        let expandedRepositoryPath = expandedPath(session.repositoryPath)

        guard repositoryPathExists(expandedRepositoryPath) else {
            showRepositoryPathAlert(expandedRepositoryPath)
            return
        }

        openRepositoryInCursor(session)

        if !session.commands.isEmpty {
            runCommandsInTerminal(for: session, terminalProcessStore: terminalProcessStore)
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

        launchURLs(urlsToOpen, browser: session.browser, profileName: session.browserProfileName)
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

    static func runCommandsInTerminal(
        for session: ProjectSession,
        terminalProcessStore: TerminalProcessStore
    ) {
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
            let record = terminalProcessRecord(
                for: session,
                plan: plan,
                workingDirectory: expandedRepositoryPath
            )

            terminalProcessStore.track(record)

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                launchTerminalCommand(
                    record: record,
                    reuseFrontWindowIfAvailable: !terminalWasRunning && index == 0,
                    terminalProcessStore: terminalProcessStore
                )
            }
        }
    }

    static func stopTerminalProcesses(for session: ProjectSession, terminalProcessStore: TerminalProcessStore) {
        terminalProcessStore.stopProcesses(for: session)
    }

    static func shutdownWorkspace(for session: ProjectSession, terminalProcessStore: TerminalProcessStore) {
        terminalProcessStore.stopProcesses(for: session)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            closeTerminalWindows(for: session, terminalProcessStore: terminalProcessStore)
            terminalProcessStore.clearRecords(for: session)
            terminalProcessStore.refresh()
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

    private static func launchTerminalCommand(
        record: TerminalProcessRecord,
        reuseFrontWindowIfAvailable: Bool,
        terminalProcessStore: TerminalProcessStore
    ) {
        guard let scriptURL = writeTerminalCommandScript(for: record) else {
            showLaunchAlert(
                title: "Could Not Prepare Terminal Command",
                message: record.title
            )
            return
        }

        let shellCommand = "clear; zsh \(shellQuoted(scriptURL.path))"
        let script: String

        if reuseFrontWindowIfAvailable {
            script = """
            tell application "Terminal"
                activate
                delay 0.4
                if (count of windows) is 0 then
                    set projectSessionsTab to do script "\(appleScriptEscaped(shellCommand))"
                else
                    do script "\(appleScriptEscaped(shellCommand))" in selected tab of front window
                    set projectSessionsTab to selected tab of front window
                end if
                set custom title of projectSessionsTab to "\(appleScriptEscaped(record.terminalTabTitle))"
                return id of front window
            end tell
            """
        } else {
            script = """
            tell application "Terminal"
                set projectSessionsTab to do script "\(appleScriptEscaped(shellCommand))"
                set custom title of projectSessionsTab to "\(appleScriptEscaped(record.terminalTabTitle))"
                activate
                return id of front window
            end tell
            """
        }

        var error: NSDictionary?

        guard let appleScript = NSAppleScript(source: script) else {
            print("Could not create Terminal AppleScript for command: \(record.title)")
            return
        }

        let result = appleScript.executeAndReturnError(&error)

        if let error {
            print("Could not run Terminal command \(record.title): \(error)")
            showTerminalAutomationPermissionAlertIfNeeded(error)
        } else {
            print("Opening Terminal command: \(record.title)")
            print("[Project Sessions Debug] Terminal launch result for record id=\(record.id) title=\(record.title): \(result.stringValue ?? String(result.int32Value))")

            if result.int32Value != 0 {
                terminalProcessStore.updateTerminalWindowID(
                    for: record.id,
                    windowID: Int(result.int32Value)
                )
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                terminalProcessStore.refresh()
            }
        }
    }

    private static func terminalProcessRecord(
        for session: ProjectSession,
        plan: TerminalLaunchPlan,
        workingDirectory: String
    ) -> TerminalProcessRecord {
        let id = UUID()
        let trackingDirectory = terminalProcessTrackingDirectory()
        let pidFileURL = trackingDirectory.appendingPathComponent("\(id.uuidString).pid")
        let exitFileURL = trackingDirectory.appendingPathComponent("\(id.uuidString).exit")

        return TerminalProcessRecord(
            id: id,
            sessionID: session.id,
            sessionName: session.name,
            title: plan.title,
            command: plan.shellCommand,
            workingDirectory: workingDirectory,
            terminalTabTitle: terminalTabTitle(sessionName: session.name, commandTitle: plan.title, id: id),
            terminalWindowID: nil,
            pidFilePath: pidFileURL.path,
            exitFilePath: exitFileURL.path,
            pid: nil,
            status: .launching,
            startedAt: Date()
        )
    }

    private static func terminalProcessTrackingDirectory() -> URL {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("ProjectSessions", isDirectory: true)
            .appendingPathComponent("TerminalProcesses", isDirectory: true)

        try? FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )

        return directoryURL
    }

    private static func trackedShellCommand(for record: TerminalProcessRecord) -> String {
        """
        unsetopt bgnice 2>/dev/null
        cd \(shellQuoted(record.workingDirectory)) || exit 1

        echo "[Project Sessions] \(record.title)"
        echo "$ \(record.command)"
        echo

        (
            \(record.command)
        ) &

        commandPID=$!
        echo $commandPID > \(shellQuoted(record.pidFilePath))
        wait $commandPID
        exitCode=$?
        echo $exitCode > \(shellQuoted(record.exitFilePath))

        echo
        echo "[Project Sessions] command finished with exit status $exitCode"
        """
    }

    private static func closeTerminalWindows(
        for session: ProjectSession,
        terminalProcessStore: TerminalProcessStore
    ) {
        let records = terminalProcessStore.records(for: session)
        let tabTitles = records
            .map(\.terminalTabTitle)
        let windowIDs = records
            .compactMap(\.terminalWindowID)

        print("[Project Sessions Debug] Shutdown close requested for session=\(session.name)")

        for record in records {
            print("[Project Sessions Debug] Close candidate title=\(record.title) status=\(record.status.rawValue) pid=\(String(describing: record.pid)) windowID=\(String(describing: record.terminalWindowID)) tabTitle=\(record.terminalTabTitle)")
        }

        guard !tabTitles.isEmpty || !windowIDs.isEmpty else {
            print("[Project Sessions Debug] No Terminal records available for close.")
            return
        }

        let windowIDList = windowIDs.isEmpty
            ? "{}"
            : "{\(windowIDs.map(String.init).joined(separator: ", "))}"

        let titleChecks = tabTitles.isEmpty
            ? "false"
            : tabTitles
                .map { "tabTitle is \"\(appleScriptEscaped($0))\"" }
                .joined(separator: " or ")

        let script = """
        tell application "Terminal"
            set targetWindowIDs to \(windowIDList)
            set matchingWindowIDs to {}
            set matchingTabTitles to {}

            repeat 3 times
                repeat with targetWindowID in targetWindowIDs
                    set targetWindowIDNumber to targetWindowID as integer
                    set windowToClose to missing value

                    repeat with terminalWindow in windows
                        if id of terminalWindow is targetWindowIDNumber then
                            set windowToClose to terminalWindow
                            set end of matchingWindowIDs to targetWindowIDNumber
                            exit repeat
                        end if
                    end repeat

                    if windowToClose is not missing value then
                        close windowToClose saving no
                    end if
                end repeat

                delay 0.2
            end repeat

            repeat 3 times
                set tabWindowToClose to missing value

                repeat with terminalWindow in windows
                    repeat with terminalTab in tabs of terminalWindow
                        set tabTitle to custom title of terminalTab

                        if \(titleChecks) then
                            set tabWindowToClose to terminalWindow
                            set end of matchingTabTitles to tabTitle
                            exit repeat
                        end if
                    end repeat

                    if tabWindowToClose is not missing value then
                        exit repeat
                    end if
                end repeat

                if tabWindowToClose is not missing value then
                    close tabWindowToClose saving no
                end if

                delay 0.2
            end repeat

            return "windowIDs=" & (matchingWindowIDs as string) & "; tabTitles=" & (matchingTabTitles as string)
        end tell
        """

        var error: NSDictionary?

        guard let appleScript = NSAppleScript(source: script) else {
            print("Could not create Terminal close AppleScript for session: \(session.name)")
            return
        }

        let result = appleScript.executeAndReturnError(&error)

        if let error {
            print("Could not close Terminal windows for \(session.name): \(error)")
            showTerminalAutomationPermissionAlertIfNeeded(error)
        } else {
            print("[Project Sessions Debug] Terminal close result for session=\(session.name): \(result.stringValue ?? String(result.int32Value))")
        }
    }

    private static func terminalTabTitle(sessionName: String, commandTitle: String, id: UUID) -> String {
        "Project Sessions - \(sessionName) - \(commandTitle) - \(id.uuidString)"
    }

    private static func writeTerminalCommandScript(for record: TerminalProcessRecord) -> URL? {
        let scriptURL = terminalProcessTrackingDirectory()
            .appendingPathComponent("\(record.id.uuidString).zsh")

        do {
            try trackedShellCommand(for: record).write(
                to: scriptURL,
                atomically: true,
                encoding: .utf8
            )

            return scriptURL
        } catch {
            print("Could not write terminal command script: \(error)")
            return nil
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
