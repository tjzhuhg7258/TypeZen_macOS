import SwiftUI
import SwiftData

struct ContributionHeatmap: View {
    let sessions: [PracticeSession]
    
    // 配置
    private let weeksToShow = 20  // 显示最近20周
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("练习热力图")
                .font(.headline)
            
            if sessions.isEmpty {
                EmptyChartView(message: "暂无数据")
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        // 生成周列
                        ForEach(0..<weeksToShow, id: \.self) { weekIndex in
                            VStack(spacing: 4) {
                                // 生成每天的格子 (7天)
                                ForEach(0..<7, id: \.self) { dayIndex in
                                    if let date = dateFor(week: weekIndex, day: dayIndex) {
                                        HeatmapCell(
                                            count: countFor(date: date),
                                            date: date
                                        )
                                    } else {
                                        // 占位符
                                        Color.clear.frame(width: 12, height: 12)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // 图例
                HStack(spacing: 4) {
                    Text("Less")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    ForEach(0..<5) { level in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(colorForLevel(level))
                            .frame(width: 10, height: 10)
                    }
                    
                    Text("More")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    // MARK: - 数据处理
    
    private var dateToCount: [String: Int] {
        var counts: [String: Int] = [:]
        for session in sessions {
            let key = dateKey(session.date)
            counts[key, default: 0] += 1
        }
        return counts
    }
    
    private func dateFor(week: Int, day: Int) -> Date? {
        // 计算基准日期：weeksToShow 周前的周日
        // 注意：这里我们反向计算，week 0 是最左边（最早），week weeksToShow-1 是最右边（最近）
        // 或者更直观：最右边是本周
        
        let today = Date()
        // 找到本周的第一天（通常是周日或周一，取决于系统设置，这里假设周日）
        // GitHub 是周日为第一行
        
        let weekday = calendar.component(.weekday, from: today) // 1=Sun, 2=Mon...
        // 调整到上一个周日
        guard let currentWeekSunday = calendar.date(byAdding: .day, value: -(weekday - 1), to: today) else { return nil }
        
        // 计算 weeksToShow 周前的周日
        let startSunday = calendar.date(byAdding: .weekOfYear, value: -(weeksToShow - 1), to: currentWeekSunday)!
        
        // 计算目标日期
        let targetWeekSunday = calendar.date(byAdding: .weekOfYear, value: week, to: startSunday)!
        let targetDate = calendar.date(byAdding: .day, value: day, to: targetWeekSunday)!
        
        // 如果日期在未来，不显示（或者显示为空）
        if targetDate > today {
            return nil // 或者返回但 count 为 0
        }
        
        return targetDate
    }
    
    private func countFor(date: Date) -> Int {
        return dateToCount[dateKey(date)] ?? 0
    }
    
    private func dateKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    // MARK: - 颜色逻辑
    
    private func colorForLevel(_ level: Int) -> Color {
        switch level {
        case 0: return Color.gray.opacity(0.1)
        case 1: return Color.green.opacity(0.3)
        case 2: return Color.green.opacity(0.5)
        case 3: return Color.green.opacity(0.7)
        default: return Color.green
        }
    }
}

struct HeatmapCell: View {
    let count: Int
    let date: Date
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(colorFor(count: count))
            .frame(width: 12, height: 12)
            .help("\(dateText): \(count) 次练习") // macOS Tooltip
    }
    
    private var dateText: String {
        date.formatted(date: .abbreviated, time: .omitted)
    }
    
    private func colorFor(count: Int) -> Color {
        if count == 0 { return Color.gray.opacity(0.1) }
        if count <= 2 { return Color.green.opacity(0.3) }
        if count <= 5 { return Color.green.opacity(0.5) }
        if count <= 8 { return Color.green.opacity(0.7) }
        return Color.green
    }
}

struct ContributionHeatmap_Previews: PreviewProvider {
    static var previews: some View {
        ContributionHeatmap(sessions: [])
    }
}
