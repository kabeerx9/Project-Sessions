import SwiftUI

struct SessionFormView: View {
    let title: String?
    @Binding var name: String
    @Binding var browser: Browser
    @Binding var repositoryPath: String
    @Binding var urls: [String]
    @Binding var urlDraft: String
    @Binding var commands: [TerminalCommand]
    @Binding var commandDraft: String
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

            TextField("Command", text: $commandDraft)

            Button("Add Command") {
                addCommand()
            }
            .disabled(commandDraft.isEmpty)

            ForEach(commands) { command in
                HStack {
                    Text(command.command)
                    Spacer()
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

        commands.append(TerminalCommand(command: commandDraft))
        commandDraft = ""
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
        commands: .constant([TerminalCommand(command: "pnpm dev"), TerminalCommand(command: "expo start")]),
        commandDraft: .constant(""),
        onChooseFolder: {},
        onCancel: {},
        onSave: {}
    )
}
