import SwiftUI

enum AppThemeMode: String, CaseIterable, Codable {
    case system = "system"
    case light = "light"
    case dark = "dark"

    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}

@MainActor
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    private let themeKey = "morningproof_theme_mode"

    @Published var themeMode: AppThemeMode {
        didSet {
            saveThemeMode()
        }
    }

    /// Returns the ColorScheme to apply, or nil for system default
    var preferredColorScheme: ColorScheme? {
        switch themeMode {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    private init() {
        if let savedMode = UserDefaults.standard.string(forKey: themeKey),
           let mode = AppThemeMode(rawValue: savedMode) {
            self.themeMode = mode
        } else {
            self.themeMode = .dark
        }
    }

    private func saveThemeMode() {
        UserDefaults.standard.set(themeMode.rawValue, forKey: themeKey)
    }
}
