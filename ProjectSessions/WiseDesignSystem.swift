import SwiftUI

struct WiseColors {
    static let primary = Color.accentColor
    static let onPrimary = Color.white
    static let primaryActive = Color.accentColor.opacity(0.18)
    static let primaryNeutral = Color.accentColor.opacity(0.12)
    static let primaryPale = Color.accentColor.opacity(0.08)

    static let ink = Color.primary
    static let inkDeep = Color.primary
    static let body = Color.secondary
    static let mute = Color.secondary.opacity(0.78)

    static let canvas = Color(nsColor: .controlBackgroundColor)
    static let canvasSoft = Color(nsColor: .windowBackgroundColor)
    static let panel = Color(nsColor: .textBackgroundColor)
    static let border = Color.primary.opacity(0.10)

    static let positive = Color.green
    static let positiveDeep = Color.green
    static let warning = Color.orange
    static let warningDeep = Color.orange
    static let warningContent = Color.orange
    static let negative = Color.red
    static let negativeDeep = Color.red
    static let negativeDarkest = Color.red
    static let negativeBg = Color.red.opacity(0.12)

    static let accentOrange = Color.orange
    static let accentCyan = Color.cyan
}

struct WiseRadii {
    static let sm: CGFloat = 6
    static let md: CGFloat = 8
    static let lg: CGFloat = 10
    static let xl: CGFloat = 12
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: alpha
        )
    }
}
