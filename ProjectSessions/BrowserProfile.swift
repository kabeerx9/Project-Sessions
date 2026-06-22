import Foundation

struct BrowserProfile: Identifiable, Hashable {
    let directoryName: String
    let displayName: String

    var id: String {
        directoryName
    }

    var pickerLabel: String {
        displayName == directoryName ? displayName : "\(displayName) (\(directoryName))"
    }
}
