import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PracticeSession.date, order: .reverse) private var sessions: [PracticeSession]
    
    @State private var showAchievements = false

    init() {}
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("练习历史")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button {
                    showAchievements = true
                } label: {
                    Label("成就", systemImage: "trophy.fill")
                }
                .buttonStyle(.bordered)
                
                if !sessions.isEmpty {
                    Button("清空历史") {
                        clearHistory()
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.red)
                }
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            
            if sessions.isEmpty {
                // 空状态
                VStack(spacing: 20) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 60))
                        .foregroundStyle(.secondary)
                    
                    Text("还没有练习记录")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // 历史记录列表
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(sessions) { session in
                            HistoryCard(session: session)
                        }
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showAchievements) {
            AchievementsView()
                .frame(minWidth: 600, minHeight: 500)
        }
    }
    
    private func clearHistory() {
        for session in sessions {
            modelContext.delete(session)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("❌ 清空历史失败: \(error.localizedDescription)")
        }
    }
}

struct HistoryCard: View {
    let session: PracticeSession
    
    var body: some View {
        HStack(spacing: 16) {
            // 日期和模式
            VStack(alignment: .leading, spacing: 4) {
                Text(session.mode)
                    .font(.headline)
                
                Text(session.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(session.date, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 140, alignment: .leading)
            
            Divider()
            
            // 统计数据
            HStack(spacing: 30) {
                StatColumn(label: "WPM", value: "\(session.wpm)")
                StatColumn(label: "准确率", value: String(format: "%.1f%%", session.accuracy))
                StatColumn(label: "错误", value: "\(session.errorCount)")
                StatColumn(label: "用时", value: String(format: "%.0f秒", session.duration))
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(10)
    }
}

struct StatColumn: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView()
            .modelContainer(for: [PracticeSession.self, FavoriteText.self], inMemory: true)
    }
}
