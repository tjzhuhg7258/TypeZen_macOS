import SwiftUI
import Combine
import SwiftData

struct SettingsView: View {
    @StateObject private var aiManager = AIServiceManager.shared
    @State private var showAPIKeyInput = false
    @State private var selectedService: String = ""
    @State private var apiKeyInput = ""
    
    var body: some View {
        TabView {
            // AI 服务配置标签页
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    AIServicesSection(
                        aiManager: aiManager,
                        showAPIKeyInput: $showAPIKeyInput,
                        selectedService: $selectedService
                    )
                    
                    PracticeSettingsSection()
                    
                    AboutSection()
                }
                .padding()
            }
            .tabItem {
                Label("AI 服务", systemImage: "sparkles")
            }
            
            // 外观设置标签页
            AppearanceSettingsView()
                .tabItem {
                    Label("外观", systemImage: "paintbrush.fill")
                }
            
            // iCloud 同步标签页
            CloudSyncSettingsView()
                .tabItem {
                    Label("iCloud 同步", systemImage: "icloud")
                }
        }
        .frame(minWidth: 600, minHeight: 500)
        .sheet(isPresented: $showAPIKeyInput) {
            APIKeyInputSheet(
                serviceName: selectedService,
                apiKey: $apiKeyInput,
                onSave: {
                    saveAPIKey()
                },
                onCancel: {
                    showAPIKeyInput = false
                    apiKeyInput = ""
                }
            )
        }
    }
    
    private func saveAPIKey() {
        let serviceKey: String
        switch selectedService {
        case "Google Gemini":
            serviceKey = "gemini_api_key"
        case "OpenAI GPT":
            serviceKey = "openai_api_key"
        case "Anthropic Claude":
            serviceKey = "claude_api_key"
        default:
            return
        }
        
        if KeychainManager.shared.save(apiKey: apiKeyInput, for: serviceKey) {
            showAPIKeyInput = false
            apiKeyInput = ""
            // 刷新服务列表
            aiManager.objectWillChange.send()
        }
    }
}

struct AIServicesSection: View {
    @ObservedObject var aiManager: AIServiceManager
    @Binding var showAPIKeyInput: Bool
    @Binding var selectedService: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI 服务配置")
                .font(.headline)
            
            Text("配置 AI 服务以生成练习文本。服务将按照列表顺序依次尝试，失败后自动切换到下一个。")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            ForEach(aiManager.allServices, id: \.name) { item in
                AIServiceRow(
                    serviceName: item.name,
                    service: item.service,
                    isEnabled: aiManager.isServiceEnabled(item.name),
                    onToggle: {
                        aiManager.toggleService(item.name)
                    },
                    onConfigure: {
                        selectedService = item.name
                        showAPIKeyInput = true
                    }
                )
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(10)
    }
}

struct AIServiceRow: View {
    let serviceName: String
    let service: any AIServiceProtocol
    let isEnabled: Bool
    let onToggle: () -> Void
    let onConfigure: () -> Void
    
    var body: some View {
        HStack {
            // 服务名称和状态
            VStack(alignment: .leading, spacing: 4) {
                Text(serviceName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(service.isConfigured ? Color.green : Color.gray)
                        .frame(width: 6, height: 6)
                    
                    Text(service.isConfigured ? "已配置" : "未配置")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // 配置按钮
            Button(service.isConfigured ? "重新配置" : "配置") {
                onConfigure()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            
            // 启用开关
            Toggle("", isOn: Binding(
                get: { isEnabled },
                set: { _ in onToggle() }
            ))
            .toggleStyle(.switch)
            .disabled(!service.isConfigured)
        }
        .padding(.vertical, 8)
    }
}

struct PracticeSettingsSection: View {
    // AI 生成设置
    @AppStorage("practiceDifficulty") private var difficulty = 3
    @AppStorage("practiceWordCount") private var wordCount = 200
    @AppStorage("practiceCustomTopic") private var customTopic = ""
    @AppStorage("practiceSourceURL") private var sourceURL = ""
    
    // 通用设置
    @AppStorage("autoSaveHistory") private var autoSaveHistory = true
    @AppStorage("showInputHighlight") private var showInputHighlight = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("练习与 AI 设置")
                .font(.headline)
            
            // MARK: - AI 生成配置
            VStack(alignment: .leading, spacing: 16) {
                Text("AI 生成配置")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                // 难度设置
                HStack {
                    Text("文章难度")
                    Spacer()
                    Picker("", selection: $difficulty) {
                        Text("1 - 简单").tag(1)
                        Text("2 - 较易").tag(2)
                        Text("3 - 中等").tag(3)
                        Text("4 - 较难").tag(4)
                        Text("5 - 困难").tag(5)
                    }
                    .frame(width: 150)
                }
                
                // 字数设置
                HStack {
                    Text("生成字数: \(wordCount)")
                    Spacer()
                    Slider(value: Binding(
                        get: { Double(wordCount) },
                        set: { wordCount = Int($0) }
                    ), in: 50...1000, step: 50)
                    .frame(width: 200)
                }
                
                // 自定义主题
                HStack {
                    Text("自定义主题")
                    Spacer()
                    TextField("留空则随机 (例如: 科技、美食)", text: $customTopic)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 250)
                }
                
                HStack {
                    Text("参考链接")
                    Spacer()
                    TextField("可选：用于检索并总结后生成", text: $sourceURL)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 250)
                }
            }
            .padding(16)
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(8)
            
            // MARK: - 通用设置
            VStack(alignment: .leading, spacing: 16) {
                Text("界面与交互")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                // 输入高亮显示
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("显示输入进度高亮", isOn: $showInputHighlight)
                    Text("开启后将实时显示输入进度、正确字符（绿色）和错误字符（红色）")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // 自动保存
                Toggle("自动保存练习记录", isOn: $autoSaveHistory)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(10)
    }
}

struct AboutSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("关于")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("应用名称:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("TypeZen")
                        .font(.subheadline)
                }
                
                HStack {
                    Text("版本:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("1.0.1 (Build 2)")
                        .font(.subheadline)
                }
                
                HStack {
                    Text("作者:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("TypeZen Team")
                        .font(.subheadline)
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(10)
    }
}

struct APIKeyInputSheet: View {
    let serviceName: String
    @Binding var apiKey: String
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("配置 \(serviceName)")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("请输入您的 API Key")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            SecureField("API Key", text: $apiKey)
                .textFieldStyle(.roundedBorder)
                .frame(width: 400)
            
            Text(getInstructionText())
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)
            
            HStack(spacing: 12) {
                Button("取消") {
                    onCancel()
                }
                .buttonStyle(.bordered)
                
                Button("保存") {
                    onSave()
                }
                .buttonStyle(.borderedProminent)
                .disabled(apiKey.isEmpty)
            }
        }
        .padding(30)
        .frame(width: 500, height: 300)
    }
    
    private func getInstructionText() -> String {
        switch serviceName {
        case "Google Gemini":
            return "在 Google AI Studio (aistudio.google.com) 中获取 API Key"
        case "OpenAI GPT":
            return "在 OpenAI Platform (platform.openai.com) 中获取 API Key"
        case "Anthropic Claude":
            return "在 Anthropic Console (console.anthropic.com) 中获取 API Key"
        default:
            return ""
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .modelContainer(for: [PracticeSession.self, FavoriteText.self], inMemory: true)
    }
}
