import Foundation

enum Browser: String, Codable, CaseIterable, Identifiable {
    case chrome = "Chrome"
    case safari = "Safari"
    case brave = "Brave"

    var id: String {
        rawValue
    }

    var appName: String {
        switch self {
        case .chrome:
            "Google Chrome"
        case .safari:
            "Safari"
        case .brave:
            "Brave Browser"
        }
    }
}
