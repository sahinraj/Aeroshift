import SwiftUI

extension Color {
    static let primaryBrand = Color(hex: 0x00828A)
    static let oceanBlue = Color(hex: 0x005B7F)
    static let warningAlert = Color(hex: 0xFF9F0A)

    static let adaptiveCanvasBackground = Color(uiColor: .systemGroupedBackground)
    static let adaptiveCardBackground = Color(uiColor: .secondarySystemGroupedBackground)

    init(hex: UInt, alpha: Double = 1.0) {
        let red = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue = Double(hex & 0xFF) / 255

        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}
