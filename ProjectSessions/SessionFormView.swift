import SwiftUI

struct SessionFormView: View {
    let title: String?
    @Binding var name: String
    @Binding var browser: Browser
    @Binding var browserProfileName: String
    @Binding var repositoryPath: String
    @Binding var urls: [String]
    @Binding var urlDraft: String
    @Binding var commands: [TerminalCommand]
    @Binding var commandNameDraft: String
    @Binding var commandDraft: String
    @Binding var commandRunsInSeparateTerminal: Bool
    let onChooseFolder: () -> Void
    let onCancel: () -> Void
    let onSave: () -> Void

    private var canSave: Bool {
        validationMessage == nil
    }

    private var validationMessage: String? {
        if trimmedName.isEmpty {
            return "Add a session name."
        }

        if trimmedRepositoryPath.isEmpty {
            return "Add a repository path."
        }

        if !repositoryPathExists {
            return "Choose an existing repository folder."
        }

        return nil
    }

    private var browserProfiles: [BrowserProfile] {
        BrowserProfileDetector.profiles(for: browser)
    }

    private var browserOptions: [Browser] {
        BrowserDetector.installedSupportedBrowsers
    }

    var body: some View {
        Form {
            if let title {
                Text(title)
                    .font(.title)
            }

            TextField("Session name", text: $name)

            Picker("Browser", selection: $browser) {
                ForEach(browserOptions) { browser in
                    Text(browser.rawValue).tag(browser)
                }
            }

            if browser.supportsProfiles {
                if browserProfiles.isEmpty {
                    TextField("Browser profile", text: $browserProfileName)

                    Text("No browser profiles detected. You can still enter a profile directory manually.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Picker("Browser profile", selection: $browserProfileName) {
                        Text("None").tag("")

                        ForEach(browserProfiles) { profile in
                            Text(profile.pickerLabel).tag(profile.directoryName)
                        }
                    }
                }
            }

            if !browser.supportsProfiles && !trimmedBrowserProfileName.isEmpty {
                Text("Profiles are only supported for Chrome, Brave, and Edge.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            TextField("Repository path", text: $repositoryPath)

            Button("Choose Folder") {
                onChooseFolder()
            }

            TextField("URL", text: $urlDraft)

            Button("Add URL") {
                addURL()
            }
            .disabled(trimmedURLDraft.isEmpty)

            ForEach(urls, id: \.self) { url in
                HStack {
                    Text(url)
                    Spacer()
                    Button("Remove") {
                        urls.removeAll { $0 == url }
                    }
                }
            }

            TextField("Command name", text: $commandNameDraft)
            TextField("Command", text: $commandDraft)
            Toggle("Run in separate terminal", isOn: $commandRunsInSeparateTerminal)

            Button("Add Command") {
                addCommand()
            }
            .disabled(trimmedCommandDraft.isEmpty)

            ForEach(commands) { command in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(command.name.isEmpty ? command.command : command.name)
                        Text(command.command)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if command.runsInSeparateTerminal {
                        Text("Separate terminal")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Button("Remove") {
                        commands.removeAll { $0.id == command.id }
                    }
                }
            }

            HStack {
                Button("Cancel") {
                    onCancel()
                }

                Spacer()

                Button("Save") {
                    saveForm()
                }
                .disabled(!canSave)
            }

            if let validationMessage {
                Text(validationMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .frame(width: 420)
        .onAppear {
            cleanBrowserSelection()
        }
        .onChange(of: browser) { _, newBrowser in
            cleanBrowserProfileSelection(for: newBrowser)
        }
    }

    private func addURL() {
        guard !trimmedURLDraft.isEmpty else {
            return
        }

        if !urls.contains(trimmedURLDraft) {
            urls.append(trimmedURLDraft)
        }

        urlDraft = ""
    }

    private func addCommand() {
        guard !trimmedCommandDraft.isEmpty else {
            return
        }

        commands.append(
            TerminalCommand(
                name: trimmedCommandNameDraft,
                command: trimmedCommandDraft,
                runsInSeparateTerminal: commandRunsInSeparateTerminal
            )
        )
        commandNameDraft = ""
        commandDraft = ""
        commandRunsInSeparateTerminal = true
    }

    private func saveForm() {
        guard canSave else {
            return
        }

        name = trimmedName
        browserProfileName = browser.supportsProfiles ? trimmedBrowserProfileName : ""
        repositoryPath = trimmedRepositoryPath
        urls = urls
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        commands = commands.compactMap { command in
            let trimmedName = command.name.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedCommand = command.command.trimmingCharacters(in: .whitespacesAndNewlines)

            guard !trimmedCommand.isEmpty else {
                return nil
            }

            return TerminalCommand(
                id: command.id,
                name: trimmedName,
                command: trimmedCommand,
                runsInSeparateTerminal: command.runsInSeparateTerminal
            )
        }

        onSave()
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedRepositoryPath: String {
        repositoryPath.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedBrowserProfileName: String {
        browserProfileName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedURLDraft: String {
        urlDraft.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedCommandNameDraft: String {
        commandNameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedCommandDraft: String {
        commandDraft.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var repositoryPathExists: Bool {
        var isDirectory: ObjCBool = false

        return FileManager.default.fileExists(
            atPath: expandedRepositoryPath,
            isDirectory: &isDirectory
        ) && isDirectory.boolValue
    }

    private var expandedRepositoryPath: String {
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser.path

        if trimmedRepositoryPath.hasPrefix("~/") {
            return homeDirectory + trimmedRepositoryPath.dropFirst()
        }

        if trimmedRepositoryPath.hasPrefix("/") {
            return trimmedRepositoryPath
        }

        return "\(homeDirectory)/\(trimmedRepositoryPath)"
    }

    private func cleanBrowserProfileSelection(for browser: Browser) {
        guard browser.supportsProfiles else {
            browserProfileName = ""
            return
        }

        let profiles = BrowserProfileDetector.profiles(for: browser)

        guard !profiles.isEmpty,
              !profiles.contains(where: { $0.directoryName == browserProfileName }) else {
            return
        }

        browserProfileName = ""
    }

    private func cleanBrowserSelection() {
        guard !browserOptions.contains(browser),
              let firstBrowser = browserOptions.first else {
            return
        }

        browser = firstBrowser
        cleanBrowserProfileSelection(for: firstBrowser)
    }
}

#Preview {
    SessionFormView(
        title: "Edit Session",
        name: .constant("Fantasy App"),
        browser: .constant(.chrome),
        browserProfileName: .constant("Default"),
        repositoryPath: .constant("~/Projects/fantasy-app"),
        urls: .constant(["https://github.com", "http://localhost:3000"]),
        urlDraft: .constant(""),
        commands: .constant([
            TerminalCommand(name: "Web", command: "pnpm dev"),
            TerminalCommand(name: "Mobile", command: "expo start")
        ]),
        commandNameDraft: .constant(""),
        commandDraft: .constant(""),
        commandRunsInSeparateTerminal: .constant(true),
        onChooseFolder: {},
        onCancel: {},
        onSave: {}
    )
}
