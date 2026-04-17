import SwiftUI

struct AppearanceSettingsView: View {
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 标题
                Text("外观设置")
                    .font(.title3)
                    .fontWeight(.bold)
                
                // 主题选择
                VStack(alignment: .leading, spacing: 12) {
                    Text("主题")
                        .font(.headline)
                    
                    Picker("主题", selection: $themeManager.currentTheme) {
                        ForEach(Theme.allCases, id: \.self) { theme in
                            Text(theme.displayName).tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: themeManager.currentTheme) { _, newValue in
                        themeManager.setTheme(newValue)
                    }
                }
                .padding()
                .background(Color(.controlBackgroundColor))
                .cornerRadius(10)
                
                // 强调色选择
                VStack(alignment: .leading, spacing: 12) {
                    Text("强调色")
                        .font(.headline)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(AccentColorOption.allCases, id: \.self) { option in
                            ColorOptionButton(
                                option: option,
                                isSelected: themeManager.accentColor == option,
                                action: {
                                    themeManager.setAccentColor(option)
                                }
                            )
                        }
                    }
                    
                    Text("强调色将应用于按钮、链接等交互元素")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.controlBackgroundColor))
                .cornerRadius(10)
                
                // 预览
                VStack(alignment: .leading, spacing: 12) {
                    Text("预览")
                        .font(.headline)
                    
                    HStack(spacing: 16) {
                        Button("主要按钮") {}
                            .buttonStyle(.borderedProminent)
                            .tint(themeManager.accentColor.color)
                        
                        Button("次要按钮") {}
                            .buttonStyle(.bordered)
                        
                        Button("文本按钮") {}
                            .buttonStyle(.plain)
                            .foregroundColor(themeManager.accentColor.color)
                    }
                    .padding()
                    .background(Color(.windowBackgroundColor))
                    .cornerRadius(8)
                }
                .padding()
                .background(Color(.controlBackgroundColor))
                .cornerRadius(10)
            }
            .padding()
        }
    }
}

// MARK: - 颜色选项按钮

struct ColorOptionButton: View {
    let option: AccentColorOption
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Circle()
                    .fill(option.color)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .stroke(Color.primary, lineWidth: isSelected ? 3 : 0)
                    )
                    .overlay(
                        Image(systemName: "checkmark")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .bold))
                            .opacity(isSelected ? 1 : 0)
                    )
                
                Text(option.displayName)
                    .font(.caption)
                    .foregroundColor(isSelected ? option.color : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? option.color.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

struct AppearanceSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        AppearanceSettingsView()
    }
}
