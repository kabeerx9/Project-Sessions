import SwiftUI

struct SessionFormView: View {
    let title: String?
    @Binding var name: String
    @Binding var browser: Browser
    @Binding var repositoryPath: String
    @Binding var urls: [String]
    @Binding var urlDraft: String
    @Binding var commands: [TerminalCommand]
    @Binding var commandNameDraft: String
    @Binding var commandDraft: String
    @Binding var commandRunsInSeparateTab: Bool
    let onChooseFolder: () -> Void
    let onCancel: () -> Void
    let onSave: () -> Void

    private var canSave: Bool {
        !name.isEmpty && !repositoryPath.isEmpty
    }

    var body: some View {
        Form {
            if let title {
                Text(title)
                    .font(.title)
            }

            TextField("Session name", text: $name)

            Picker("Browser", selection: $browser) {
                ForEach(Browser.allCases) { browser in
                    Text(browser.rawValue).tag(browser)
                }
            }

            TextField("Repository path", text: $repositoryPath)

            Button("Choose Folder") {
                onChooseFolder()
            }

            TextField("URL", text: $urlDraft)

            Button("Add URL") {
                addURL()
            }
            .disabled(urlDraft.isEmpty)

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
            Toggle("Run in separate tab later", isOn: $commandRunsInSeparateTab)

            Button("Add Command") {
                addCommand()
            }
            .disabled(commandDraft.isEmpty)

            ForEach(commands) { command in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(command.name.isEmpty ? command.command : command.name)
                        Text(command.command)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if command.runsInSeparateTab {
                        Text("Separate tab")
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
                    onSave()
                }
                .disabled(!canSave)
            }
        }
        .padding()
        .frame(width: 420)
    }

    private func addURL() {
        guard !urlDraft.isEmpty else {
            return
        }

        urls.append(urlDraft)
        urlDraft = ""
    }

    private func addCommand() {
        guard !commandDraft.isEmpty else {
            return
        }

        commands.append(
            TerminalCommand(
                name: commandNameDraft,
                command: commandDraft,
                runsInSeparateTab: commandRunsInSeparateTab
            )
        )
        commandNameDraft = ""
        commandDraft = ""
        commandRunsInSeparateTab = true
    }
}

#Preview {
    SessionFormView(
        title: "Edit Session",
        name: .constant("Fantasy App"),
        browser: .constant(.chrome),
        repositoryPath: .constant("~/Projects/fantasy-app"),
        urls: .constant(["https://github.com", "http://localhost:3000"]),
        urlDraft: .constant(""),
        commands: .constant([
            TerminalCommand(name: "Web", command: "pnpm dev"),
            TerminalCommand(name: "Mobile", command: "expo start")
        ]),
        commandNameDraft: .constant(""),
        commandDraft: .constant(""),
        commandRunsInSeparateTab: .constant(true),
        onChooseFolder: {},
        onCancel: {},
        onSave: {}
    )
}
