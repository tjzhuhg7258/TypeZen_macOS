import SwiftUI
import Combine

/// 主题管理器
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: Theme = .system
    @Published var accentColor: AccentColorOption = .blue
    
    private let themeKey = "selectedTheme"
    private let accentColorKey = "selectedAccentColor"
    
    private init() {
        loadTheme()
    }
    
    func loadTheme() {
        if let themeRaw = UserDefaults.standard.string(forKey: themeKey),
           let theme = Theme(rawValue: themeRaw) {
            currentTheme = theme
        }
        
        if let colorRaw = UserDefaults.standard.string(forKey: accentColorKey),
           let color = AccentColorOption(rawValue: colorRaw) {
            accentColor = color
        }
    }
    
    func saveTheme() {
        UserDefaults.standard.set(currentTheme.rawValue, forKey: themeKey)
        UserDefaults.standard.set(accentColor.rawValue, forKey: accentColorKey)
    }
    
    func setTheme(_ theme: Theme) {
        currentTheme = theme
        saveTheme()
        applyTheme()
    }
    
    func setAccentColor(_ color: AccentColorOption) {
        accentColor = color
        saveTheme()
    }
    
    private func applyTheme() {
        switch currentTheme {
        case .light:
            NSApp.appearance = NSAppearance(named: .aqua)
        case .dark:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        case .system:
            NSApp.appearance = nil
        }
    }
}

// MARK: - 主题枚举

enum Theme: String, CaseIterable {
    case light = "light"
    case dark = "dark"
    case system = "system"
    
    var displayName: String {
        switch self {
        case .light: return "浅色"
        case .dark: return "深色"
        case .system: return "跟随系统"
        }
    }
}

// MARK: - 强调色选项

enum AccentColorOption: String, CaseIterable {
    case blue = "blue"
    case purple = "purple"
    case pink = "pink"
    case red = "red"
    case orange = "orange"
    case yellow = "yellow"
    case green = "green"
    case teal = "teal"
    
    var color: Color {
        switch self {
        case .blue: return .blue
        case .purple: return .purple
        case .pink: return .pink
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .teal: return .teal
        }
    }
    
    var displayName: String {
        switch self {
        case .blue: return "蓝色"
        case .purple: return "紫色"
        case .pink: return "粉色"
        case .red: return "红色"
        case .orange: return "橙色"
        case .yellow: return "黄色"
        case .green: return "绿色"
        case .teal: return "青色"
        }
    }
}
