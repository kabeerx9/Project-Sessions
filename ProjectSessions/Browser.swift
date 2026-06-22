import Foundation

enum Browser: String, Codable, CaseIterable, Identifiable {
    case chrome = "Chrome"
    case safari = "Safari"
    case brave = "Brave"
    case edge = "Microsoft Edge"
    case firefox = "Firefox"

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
        case .edge:
            "Microsoft Edge"
        case .firefox:
            "Firefox"
        }
    }

    var bundleIdentifier: String {
        switch self {
        case .chrome:
            "com.google.Chrome"
        case .safari:
            "com.apple.Safari"
        case .brave:
            "com.brave.Browser"
        case .edge:
            "com.microsoft.edgemac"
        case .firefox:
            "org.mozilla.firefox"
        }
    }

    var supportsProfiles: Bool {
        switch self {
        case .chrome, .brave, .edge:
            true
        case .safari, .firefox:
            false
        }
    }
}
