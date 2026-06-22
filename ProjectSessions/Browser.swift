import Foundation

enum Browser: String, Codable, CaseIterable, Identifiable {
    case chrome = "Chrome"
    case safari = "Safari"
    case arc = "Arc"

    var id: String {
        rawValue
    }
}
