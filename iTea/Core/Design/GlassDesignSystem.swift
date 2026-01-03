import SwiftUI

// MARK: - Glass Design System for Modern iOS

/// Semantic glass variants for different UI contexts
enum GlassStyle {
    case regular       // Standard glass for navigation elements
    case clear         // More transparent glass for overlays
    case interactive   // For tappable custom controls
}

// MARK: - Corner Radius Constants

struct CornerRadii {
    static let card: CGFloat = 16
    static let button: CGFloat = 12
    static let small: CGFloat = 8
    static let input: CGFloat = 10
}

// MARK: - View Modifiers for Glass Effects

extension View {
    /// Apply glass effect to navigation bars
    func glassNavigationBar() -> some View {
        self.toolbarBackground(.ultraThinMaterial, for: .navigationBar)
    }

    /// Apply glass effect to tab bars
    func glassTabBar() -> some View {
        self.toolbarBackground(.ultraThinMaterial, for: .tabBar)
    }

    /// Apply material background for content cards
    func materialCard() -> some View {
        self
            .padding(14)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadii.card))
    }

    /// Apply thin material for subtle backgrounds
    func thinMaterialCard() -> some View {
        self
            .padding(14)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadii.card))
    }

    /// Apply glass effect for floating controls (comment bars, FABs)
    func floatingGlass() -> some View {
        self
            .padding()
            .background(.ultraThinMaterial)
    }
}

// MARK: - Status Colors

struct StatusColors {
    static let open = Color.green
    static let closed = Color.purple
    static let merged = Color.purple
    static let error = Color.red
    static let warning = Color.orange
    static let pending = Color.yellow
}

// MARK: - Accent Colors

enum AccentColorOption: String, CaseIterable, Identifiable {
    case system = "system"
    case green = "green"
    case blue = "blue"
    case purple = "purple"
    case orange = "orange"
    case pink = "pink"
    case red = "red"
    case teal = "teal"
    case indigo = "indigo"

    var id: String { rawValue }

    var color: Color? {
        switch self {
        case .system: return nil
        case .green: return .green
        case .blue: return .blue
        case .purple: return .purple
        case .orange: return .orange
        case .pink: return .pink
        case .red: return .red
        case .teal: return .teal
        case .indigo: return .indigo
        }
    }

    var displayName: String {
        switch self {
        case .system: return "Follow System"
        default: return rawValue.capitalized
        }
    }

    var previewColor: Color {
        color ?? .accentColor
    }
}
