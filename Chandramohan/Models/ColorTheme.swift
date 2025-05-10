import SwiftUI

struct AppColors {
    // App background color - cream
    static let background = Color(hex: "#FFF8E1")
    
    // Main accent color for buttons and selections - matte orange
    static let primary = Color(hex: "#E67E22")
    
    // Secondary accent color - darker orange
    static let secondary = Color(hex: "#D35400")
    
    // Text colors
    static let textPrimary = Color.black
    static let textSecondary = Color.gray
    static let textOnColor = Color.white
    
    // Card background
    static let cardBackground = Color.white
    
    // Rating star color
    static let star = Color(hex: "#F39C12")
}

// Extension to create a Color from hex string
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
} 