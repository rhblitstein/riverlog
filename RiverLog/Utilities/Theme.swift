import SwiftUI

struct Theme {
    // River-inspired color palette
    static let primaryBlue = Color(red: 0.2, green: 0.5, blue: 0.7) // River blue
    static let darkBlue = Color(red: 0.1, green: 0.3, blue: 0.5)
    static let lightBlue = Color(red: 0.7, green: 0.85, blue: 0.95)
    static let accentTeal = Color(red: 0.2, green: 0.7, blue: 0.7)
    static let cardBackground = Color(.systemGray6) // Changed to gray
    static let pageBackground = Color(.systemBackground) // White background for pages
}

extension View {
    func cardStyle() -> some View {
        self
            .background(Theme.cardBackground)
            .cornerRadius(0) // No rounded edges
    }
}
