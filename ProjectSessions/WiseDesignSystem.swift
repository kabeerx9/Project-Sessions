import SwiftUI

struct WiseColors {
    static let primary = Color(hex: 0x9FE870)
    static let onPrimary = Color(hex: 0x0E0F0C)
    static let primaryActive = Color(hex: 0xCDFFAD)
    static let primaryNeutral = Color(hex: 0xC5EDAB)
    static let primaryPale = Color(hex: 0xE2F6D5)
    
    static let ink = Color(hex: 0x0E0F0C)
    static let inkDeep = Color(hex: 0x163300)
    static let body = Color(hex: 0x454745)
    static let mute = Color(hex: 0x868685)
    
    static let canvas = Color(hex: 0xFFFFFF)
    static let canvasSoft = Color(hex: 0xE8EBE6)
    
    static let positive = Color(hex: 0x2EAD4B)
    static let positiveDeep = Color(hex: 0x054D28)
    static let warning = Color(hex: 0xFFD11A)
    static let warningDeep = Color(hex: 0xB86700)
    static let warningContent = Color(hex: 0x4A3B1C)
    static let negative = Color(hex: 0xD03238)
    static let negativeDeep = Color(hex: 0xA72027)
    static let negativeDarkest = Color(hex: 0xA7000D)
    static let negativeBg = Color(hex: 0x320707)
    
    static let accentOrange = Color(hex: 0xFFC091)
    static let accentCyan = Color(hex: 0x38C8FF)
}

struct WiseRadii {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
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
