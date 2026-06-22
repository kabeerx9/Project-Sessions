import SwiftUI

struct SessionFormView: View {
    let title: String?
    @Binding var name: String
    @Binding var browser: String
    @Binding var repositoryPath: String
    @Binding var urls: [String]
    @Binding var urlDraft: String
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
            TextField("Browser", text: $browser)
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
}

#Preview {
    SessionFormView(
        title: "Edit Session",
        name: .constant("Fantasy App"),
        browser: .constant("Chrome"),
        repositoryPath: .constant("~/Projects/fantasy-app"),
        urls: .constant(["https://github.com", "http://localhost:3000"]),
        urlDraft: .constant(""),
        onChooseFolder: {},
        onCancel: {},
        onSave: {}
    )
}
