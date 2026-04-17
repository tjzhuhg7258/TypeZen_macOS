import SwiftUI
import SwiftData

struct HomeView: View {
    @Binding var selectedMode: PracticeMode?
    @Binding var customText: String
    @Binding var showPractice: Bool
    
    @Environment(\.modelContext) private var modelContext
    
    @State private var isGenerating = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSaveSuccess = false
    
    // 练习设置 (只读显示)
    @AppStorage("practiceDifficulty") private var difficulty = 3
    @AppStorage("practiceWordCount") private var wordCount = 200
    @AppStorage("practiceCustomTopic") private var customTopic = ""
    @AppStorage("practiceSourceURL") private var sourceURL = ""
    
    // MARK: - 计算属性
    private var difficultyText: String {
        let values = ["简单", "较易", "中等", "较难", "困难"]
        let safeIndex = max(0, min(values.count - 1, difficulty - 1))
        return values[safeIndex]
    }
    
    var body: some View {
        ScrollView {
            // 最外层容器：限定最大宽度，水平居中
            VStack(spacing: 0) {
                // 欢迎语 (顶部留白)
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("下午好，TypeZen")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("准备好开始练习了吗？")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 30)
                .padding(.top, 30)
                .padding(.bottom, 20)
                
                // 主要内容区域：两列布局
                HStack(alignment: .top, spacing: 20) {
                    
                    // 左侧：快速开始
                    VStack(spacing: 20) {
                        sectionHeader(title: "快速模式", icon: "bolt.fill", color: .orange)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                            ForEach(PracticeMode.allCases.filter { $0 != .custom }, id: \.self) { mode in
                                ModernModeCard(mode: mode) {
                                    selectedMode = mode
                                    showPractice = true
                                }
                            }
                        }
                        
                        // 占位 Spacer 确保对齐
                        Spacer(minLength: 0)
                    }
                    .padding(20)
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.03), radius: 8, y: 2)
                    .frame(maxWidth: .infinity)
                    
                    // 右侧：AI 与 自定义
                    VStack(spacing: 20) {
                        // AI 生成卡片
                        VStack(alignment: .leading, spacing: 16) {
                            sectionHeader(title: "AI 生成", icon: "sparkles", color: .purple)
                            
                            // 设置摘要
                            HStack(spacing: 8) {
                                SettingBadge(text: difficultyText, color: .purple)
                                SettingBadge(text: "\(wordCount)字", color: .blue)
                                if !customTopic.isEmpty {
                                    SettingBadge(text: customTopic, color: .green)
                                }
                                if !sourceURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    SettingBadge(text: "链接", color: .teal)
                                }
                                Spacer()
                                Text("去设置修改")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            
                            TextField("可选：输入参考链接（将检索并总结后生成）", text: $sourceURL)
                                .textFieldStyle(.roundedBorder)
                            
                            HStack(spacing: 12) {
                                Button {
                                    Task {
                                        await generateAIText()
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: isGenerating ? "hourglass" : "sparkles")
                                        Text(isGenerating ? "生成中..." : "生成文本")
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.regular)
                                .disabled(isGenerating)
                                
                                Button {
                                    saveToFavorites()
                                } label: {
                                    Image(systemName: "star")
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.regular)
                                .tint(.orange)
                                .disabled(customText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                .help("收藏当前文本")
                            }
                        }
                        .padding(20)
                        .background(Color(.controlBackgroundColor))
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.03), radius: 8, y: 2)
                        
                        // 自定义文本卡片
                        VStack(alignment: .leading, spacing: 16) {
                            sectionHeader(title: "自定义", icon: "doc.text.fill", color: .blue)
                            
                            TextEditor(text: $customText)
                                .font(.body)
                                .padding(8)
                                .background(Color(.textBackgroundColor))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                                .frame(minHeight: 120) // 给一个合适的固定高度或最小高度
                            
                            HStack {
                                Spacer()
                                Button {
                                    if !customText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        selectedMode = .custom
                                        showPractice = true
                                    }
                                } label: {
                                    Text("开始练习")
                                    Image(systemName: "arrow.right")
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.regular)
                                .disabled(customText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            }
                        }
                        .padding(20)
                        .background(Color(.controlBackgroundColor))
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.03), radius: 8, y: 2)
                        .frame(maxWidth: .infinity, maxHeight: .infinity) // 填充剩余空间
                    }
                    .frame(maxWidth: .infinity)
                    
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 30)
            }
            .frame(maxWidth: 1200) // 限制最大宽度，防止大屏过宽
            .frame(maxWidth: .infinity) // 居中
        }
        .background(Color(.windowBackgroundColor))
        .alert("生成失败", isPresented: $showError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .overlay(alignment: .top) {
            if showSaveSuccess {
                saveSuccessToast
            }
        }
    }
    
    // MARK: - 组件方法
    
    private func sectionHeader(title: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
        }
    }
    
    private var saveSuccessToast: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text("已收藏")
                .fontWeight(.medium)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(radius: 4)
        .padding(.top, 40)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    // MARK: - 逻辑方法
    
    private func generateAIText() async {
        isGenerating = true
        defer { isGenerating = false }
        do {
            let result = try await AIServiceManager.shared.generatePracticeText(
                mode: "articles",
                difficulty: difficulty,
                count: wordCount,
                topic: customTopic,
                sourceURL: sourceURL
            )
            customText = result.joined(separator: " ")
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func saveToFavorites() {
        guard !customText.isEmpty else { return }
        let favorite = FavoriteText(
            text: customText,
            category: customTopic.isEmpty ? "AI生成" : customTopic,
            createdAt: Date()
        )
        modelContext.insert(favorite)
        try? modelContext.save()
        
        withAnimation { showSaveSuccess = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showSaveSuccess = false }
        }
    }
}

// MARK: - 子视图组件

struct ModernModeCard: View {
    let mode: PracticeMode
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: mode.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(mode.color)
                
                Text(mode.rawValue)
                    .font(.subheadline) // 更小的字体
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(mode.description)
                    .font(.caption2) // 更小的说明
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(Color(.textBackgroundColor))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .onHover { isHovered in
            if isHovered { NSCursor.pointingHand.push() } else { NSCursor.pop() }
        }
    }
}

struct SettingBadge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .cornerRadius(6)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(selectedMode: .constant(nil), customText: .constant(""), showPractice: .constant(false))
            .modelContainer(for: [PracticeSession.self, FavoriteText.self], inMemory: true)
    }
}
