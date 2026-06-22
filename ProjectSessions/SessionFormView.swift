import SwiftUI

struct SessionFormView: View {
    let title: String?
    @Binding var name: String
    @Binding var browser: Browser
    @Binding var browserProfileName: String
    @Binding var repositoryPath: String
    @Binding var urls: [String]
    @Binding var urlDraft: String
    @Binding var commands: [WorkspaceCommand]
    @Binding var commandNameDraft: String
    @Binding var commandDraft: String
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
            return "Choose a repository folder."
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
        VStack(spacing: 0) {
            header

            Divider()

            ScrollView {
                HStack(alignment: .top, spacing: 18) {
                    VStack(spacing: 14) {
                        basicsSection
                        browserSection
                    }
                    .frame(maxWidth: .infinity, alignment: .top)

                    VStack(spacing: 14) {
                        urlsSection
                        commandsSection
                    }
                    .frame(maxWidth: .infinity, alignment: .top)
                }
                .padding(20)
            }

            Divider()

            footer
        }
        .frame(width: 760, height: 640)
        .background(WiseColors.canvasSoft)
        .onAppear {
            cleanBrowserSelection()
        }
        .onChange(of: browser) { _, newBrowser in
            cleanBrowserProfileSelection(for: newBrowser)
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title ?? "New Session")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Save the apps, links, folder, and commands needed to start this workspace.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(20)
    }

    private var basicsSection: some View {
        FormPanel(title: "Basics", systemImage: "folder") {
            VStack(alignment: .leading, spacing: 12) {
                FieldLabel("Session name")
                TextField("Fantasy App", text: $name)

                FieldLabel("Repository folder")
                HStack(spacing: 8) {
                    TextField("/Users/kabeer/Desktop/projects/app", text: $repositoryPath)
                        .lineLimit(1)

                    Button {
                        onChooseFolder()
                    } label: {
                        Label("Choose", systemImage: "folder")
                    }
                }

                if !trimmedRepositoryPath.isEmpty && !repositoryPathExists {
                    Label("Folder not found", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
    }

    private var browserSection: some View {
        FormPanel(title: "Browser", systemImage: "globe") {
            VStack(alignment: .leading, spacing: 12) {
                FieldLabel("Browser")
                Picker("Browser", selection: $browser) {
                    ForEach(browserOptions) { browser in
                        Text(browser.rawValue).tag(browser)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)

                if browser.supportsProfiles {
                    FieldLabel("Profile")

                    if browserProfiles.isEmpty {
                        TextField("Profile directory name", text: $browserProfileName)

                        Text("No profiles detected. You can enter a profile directory manually.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Profile", selection: $browserProfileName) {
                            Text("Default browser profile").tag("")

                            ForEach(browserProfiles) { profile in
                                Text(profile.pickerLabel).tag(profile.directoryName)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    Text("\(browser.rawValue) does not expose profile launching here.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var urlsSection: some View {
        FormPanel(title: "URLs", systemImage: "link") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    TextField("https://github.com/...", text: $urlDraft)

                    Button {
                        addURL()
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                    .disabled(trimmedURLDraft.isEmpty)
                }

                if urls.isEmpty {
                    EmptyListHint("Add links that should open when the session starts.")
                } else {
                    VStack(spacing: 6) {
                        ForEach(urls, id: \.self) { url in
                            RemovableRow(
                                title: url,
                                subtitle: nil,
                                systemImage: "globe"
                            ) {
                                urls.removeAll { $0 == url }
                            }
                        }
                    }
                }
            }
        }
    }

    private var commandsSection: some View {
        FormPanel(title: "Commands", systemImage: "terminal") {
            VStack(alignment: .leading, spacing: 12) {
                TextField("Name, optional", text: $commandNameDraft)
                TextField("Command, for example pnpm dev", text: $commandDraft)
                    .font(.system(.body, design: .monospaced))

                HStack {
                    Spacer()

                    Button {
                        addCommand()
                    } label: {
                        Label("Add Command", systemImage: "plus")
                    }
                    .disabled(trimmedCommandDraft.isEmpty)
                }

                if commands.isEmpty {
                    EmptyListHint("Commands run from the repository folder when the session starts.")
                } else {
                    VStack(spacing: 6) {
                        ForEach(commands) { command in
                            RemovableRow(
                                title: command.name.isEmpty ? command.command : command.name,
                                subtitle: command.name.isEmpty ? nil : command.command,
                                systemImage: "terminal"
                            ) {
                                commands.removeAll { $0.id == command.id }
                            }
                        }
                    }
                }
            }
        }
    }

    private var footer: some View {
        HStack {
            if let validationMessage {
                Label(validationMessage, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            Spacer()

            Button("Cancel", role: .cancel) {
                onCancel()
            }

            Button {
                saveForm()
            } label: {
                Text(title == nil ? "Create Session" : "Save Changes")
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canSave)
            .keyboardShortcut(.defaultAction)
        }
        .padding(20)
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
            WorkspaceCommand(
                name: trimmedCommandNameDraft,
                command: trimmedCommandDraft
            )
        )
        commandNameDraft = ""
        commandDraft = ""
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

            return WorkspaceCommand(
                id: command.id,
                name: trimmedName,
                command: trimmedCommand
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

private struct FormPanel<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: systemImage)
                .font(.headline)

            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(WiseColors.panel)
        .clipShape(RoundedRectangle(cornerRadius: WiseRadii.lg, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: WiseRadii.lg, style: .continuous)
                .stroke(WiseColors.border, lineWidth: 1)
        }
    }
}

private struct FieldLabel: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}

private struct EmptyListHint: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.callout)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(WiseColors.canvas)
            .clipShape(RoundedRectangle(cornerRadius: WiseRadii.md, style: .continuous))
    }
}

private struct RemovableRow: View {
    let title: String
    let subtitle: String?
    let systemImage: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.middle)

                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }

            Spacer()

            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Remove")
        }
        .padding(10)
        .background(WiseColors.canvas)
        .clipShape(RoundedRectangle(cornerRadius: WiseRadii.md, style: .continuous))
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
            WorkspaceCommand(name: "Web", command: "pnpm dev"),
            WorkspaceCommand(name: "Mobile", command: "expo start")
        ]),
        commandNameDraft: .constant(""),
        commandDraft: .constant(""),
        onChooseFolder: {},
        onCancel: {},
        onSave: {}
    )
}
