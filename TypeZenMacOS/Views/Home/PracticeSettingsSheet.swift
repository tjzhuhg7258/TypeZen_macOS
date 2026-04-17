import SwiftUI

struct PracticeSettingsSheet: View {
    @Binding var difficulty: Int
    @Binding var wordCount: Int
    @Binding var customTopic: String  // 新增：自定义主题
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            // 标题
            Text("练习设置")
                .font(.title2)
                .fontWeight(.bold)
            
            Form {
                // 难度设置
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("难度级别")
                            .font(.headline)
                        
                        Picker("难度", selection: $difficulty) {
                            Text("简单").tag(1)
                            Text("中等").tag(2)
                            Text("困难").tag(3)
                        }
                        .pickerStyle(.segmented)
                        
                        Text(difficultyDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Label("难度", systemImage: "chart.bar.fill")
                }
                
                // 字数设置
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("字数")
                                .font(.headline)
                            Spacer()
                            Text("\(wordCount) 字")
                                .font(.headline)
                                .foregroundStyle(.blue)
                        }
                        
                        Slider(value: Binding(
                            get: { Double(wordCount) },
                            set: { wordCount = Int($0) }
                        ), in: 50...500, step: 10)
                        
                        HStack {
                            Text("50").font(.caption).foregroundStyle(.secondary)
                            Spacer()
                            Text("500").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Label("字数", systemImage: "textformat.size")
                }
                
                // 主题设置
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("自定义主题")
                            .font(.headline)
                        
                        TextField("留空则随机选择主题", text: $customTopic)
                            .textFieldStyle(.roundedBorder)
                        
                        Text("示例：旅游、科技、美食、历史等")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Label("主题", systemImage: "lightbulb.fill")
                }
            }
            .formStyle(.grouped)
            
            // 按钮
            HStack(spacing: 12) {
                Button("取消") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("确定") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.top)
        }
        .padding(24)
        .frame(width: 500, height: 550)
    }
    
    private var difficultyDescription: String {
        switch difficulty {
        case 1:
            return "使用日常常用词汇，适合初学者"
        case 2:
            return "词汇丰富，适合有一定基础的用户"
        case 3:
            return "包含成语和专业词汇，适合高级用户"
        default:
            return ""
        }
    }
}

struct PracticeSettingsSheet_Previews: PreviewProvider {
    static var previews: some View {
        PracticeSettingsSheet(
            difficulty: .constant(2),
            wordCount: .constant(150),
            customTopic: .constant("")
        )
    }
}
