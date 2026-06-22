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

    var bundleIdentifier: String {
        switch self {
        case .chrome:
            "com.google.Chrome"
        case .safari:
            "com.apple.Safari"
        case .brave:
            "com.brave.Browser"
        }
    }

    var supportsProfiles: Bool {
        switch self {
        case .chrome, .brave:
            true
        case .safari:
            false
        }
    }
}
