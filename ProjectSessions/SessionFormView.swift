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
            return "Session name is required"
        }

        if trimmedRepositoryPath.isEmpty {
            return "Repository path is required"
        }

        if !repositoryPathExists {
            return "Select an existing folder"
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
                    .font(.title2)
                    .fontWeight(.semibold)
            }

            Section {
                HStack(spacing: 8) {
                    Image(systemName: "textformat")
                        .foregroundStyle(.secondary)
                        .frame(width: 20)
                    TextField("Session name", text: $name)
                }
            } header: {
                Label("Session", systemImage: "doc.text")
                    .font(.headline)
                    .foregroundStyle(.primary)
            }

            Section {
                HStack(spacing: 8) {
                    Image(systemName: browserIcon(for: browser))
                        .foregroundStyle(.secondary)
                        .frame(width: 20)
                    Picker("Browser", selection: $browser) {
                        ForEach(browserOptions) { browser in
                            Text(browser.rawValue).tag(browser)
                        }
                    }
                    .pickerStyle(.menu)
                }

                if browser.supportsProfiles {
                    if browserProfiles.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "person")
                                .foregroundStyle(.secondary)
                                .frame(width: 20)
                            TextField("Browser profile", text: $browserProfileName)
                        }

                        Text("No profiles detected. Enter profile directory manually.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 28)
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "person")
                                .foregroundStyle(.secondary)
                                .frame(width: 20)
                            Picker("Profile", selection: $browserProfileName) {
                                Text("None").tag("")
                                ForEach(browserProfiles) { profile in
                                    Text(profile.pickerLabel).tag(profile.directoryName)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }
                }
            } header: {
                Label("Browser", systemImage: "globe")
                    .font(.headline)
                    .foregroundStyle(.primary)
            }

            Section {
                HStack(spacing: 8) {
                    Image(systemName: "folder")
                        .foregroundStyle(.secondary)
                        .frame(width: 20)
                    TextField("Repository path", text: $repositoryPath)
                    Button {
                        onChooseFolder()
                    } label: {
                        Image(systemName: "folder.badge.plus")
                    }
                    .buttonStyle(.borderless)
                    .help("Choose folder")
                }
            } header: {
                Label("Repository", systemImage: "folder.fill")
                    .font(.headline)
                    .foregroundStyle(.primary)
            }

            Section {
                HStack(spacing: 8) {
                    Image(systemName: "link")
                        .foregroundStyle(.secondary)
                        .frame(width: 20)
                    TextField("https://example.com", text: $urlDraft)
                    Button {
                        addURL()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.borderless)
                    .disabled(trimmedURLDraft.isEmpty)
                }

                if !urls.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(urls, id: \.self) { url in
                            HStack(spacing: 8) {
                                Image(systemName: "link.circle")
                                    .foregroundStyle(.blue)
                                    .frame(width: 20)
                                Text(url)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                Spacer()
                                Button {
                                    urls.removeAll { $0 == url }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                    .padding(.leading, 28)
                }
            } header: {
                Label("URLs", systemImage: "link.badge.plus")
                    .font(.headline)
                    .foregroundStyle(.primary)
            }

            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "terminal")
                            .foregroundStyle(.secondary)
                            .frame(width: 20)
                        TextField("Command name (optional)", text: $commandNameDraft)
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                            .frame(width: 20)
                        TextField("npm run dev", text: $commandDraft)
                    }

                    Toggle(isOn: $commandRunsInSeparateTerminal) {
                        HStack(spacing: 8) {
                            Spacer()
                                .frame(width: 20)
                            Text("Run in separate terminal")
                        }
                    }

                    HStack {
                        Spacer()
                        Button {
                            addCommand()
                        } label: {
                            Label("Add Command", systemImage: "plus")
                        }
                        .disabled(trimmedCommandDraft.isEmpty)
                        .controlSize(.small)
                    }
                }

                if !commands.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(commands) { command in
                            HStack(spacing: 8) {
                                Image(systemName: "terminal.fill")
                                    .foregroundStyle(.green)
                                    .frame(width: 20)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(command.name.isEmpty ? command.command : command.name)
                                        .fontWeight(.medium)
                                    if !command.name.isEmpty {
                                        Text(command.command)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                Spacer()

                                if command.runsInSeparateTerminal {
                                    Image(systemName: "window.terminal")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Button {
                                    commands.removeAll { $0.id == command.id }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.borderless)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(.leading, 28)
                }
            } header: {
                Label("Commands", systemImage: "terminal.fill")
                    .font(.headline)
                    .foregroundStyle(.primary)
            }

            Section {
                if let validationMessage {
                    Label(validationMessage, systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                HStack {
                    Button(role: .cancel) {
                        onCancel()
                    } label: {
                        Label("Cancel", systemImage: "xmark")
                    }

                    Spacer()

                    Button {
                        saveForm()
                    } label: {
                        Label("Save Session", systemImage: "checkmark")
                    }
                    .disabled(!canSave)
                    .keyboardShortcut(.defaultAction)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 480, height: 620)
        .onAppear {
            cleanBrowserSelection()
        }
        .onChange(of: browser) { _, newBrowser in
            cleanBrowserProfileSelection(for: newBrowser)
        }
    }

    private func browserIcon(for browser: Browser) -> String {
        switch browser {
        case .chrome: return "globe"
        case .brave: return "globe"
        case .edge: return "globe"
        case .firefox: return "globe"
        case .safari: return "safari"
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
