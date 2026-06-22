import AppKit

enum RepositoryFolderPicker {
    static func chooseRepositoryPath() -> String? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        panel.title = "Choose Repository Folder"
        panel.prompt = "Choose"

        let response = panel.runModal()

        guard response == .OK, let url = panel.url else {
            return nil
        }

        return url.path
    }
}
