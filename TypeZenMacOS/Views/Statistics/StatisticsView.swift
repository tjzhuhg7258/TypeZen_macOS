import SwiftUI
import SwiftData
import Charts

struct StatisticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PracticeSession.date, order: .reverse) private var sessions: [PracticeSession]
    
    @State private var selectedTimeRange: TimeRange = .week
    @State private var showDetailStats = false

    init() {}
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 标题和时间范围选择
                HStack {
                    Text("统计分析")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Picker("时间范围", selection: $selectedTimeRange) {
                        Text("最近7天").tag(TimeRange.week)
                        Text("最近30天").tag(TimeRange.month)
                        Text("全部").tag(TimeRange.all)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 280)
                }
                .padding(.horizontal)
                
                // 总览卡片
                OverviewCards(sessions: filteredSessions)
                    .padding(.horizontal)
                
                // WPM 趋势图表
                WPMTrendChart(sessions: filteredSessions)
                    .padding(.horizontal)
                
                // 准确率趋势图表
                AccuracyTrendChart(sessions: filteredSessions)
                    .padding(.horizontal)
                
                // 练习热力图
                ContributionHeatmap(sessions: sessions)
                    .padding(.horizontal)
                
                // 模式分布
                ModeDistributionChart(sessions: filteredSessions)
                    .padding(.horizontal)
                
                // 详细统计
                DetailedStatistics(sessions: filteredSessions)
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
    }
    
    private var filteredSessions: [PracticeSession] {
        let now = Date()
        
        switch selectedTimeRange {
        case .week:
            let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now)!
            return sessions.filter { $0.date >= weekAgo }
        case .month:
            let monthAgo = Calendar.current.date(byAdding: .day, value: -30, to: now)!
            return sessions.filter { $0.date >= monthAgo }
        case .all:
            return sessions
        }
    }
}

// MARK: - 时间范围枚举

enum TimeRange {
    case week, month, all
}

// MARK: - 总览卡片

struct OverviewCards: View {
    let sessions: [PracticeSession]
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            StatCard(
                title: "总练习次数",
                value: "\(sessions.count)",
                icon: "chart.bar.fill",
                color: .blue
            )
            
            StatCard(
                title: "平均速度",
                value: "\(averageWPM) WPM",
                icon: "speedometer",
                color: .green
            )
            
            StatCard(
                title: "平均准确率",
                value: String(format: "%.1f%%", averageAccuracy),
                icon: "target",
                color: .orange
            )
            
            StatCard(
                title: "总练习时长",
                value: totalDurationString,
                icon: "clock.fill",
                color: .purple
            )
        }
    }
    
    private var averageWPM: Int {
        guard !sessions.isEmpty else { return 0 }
        let total = sessions.reduce(0) { $0 + $1.wpm }
        return total / sessions.count
    }
    
    private var averageAccuracy: Double {
        guard !sessions.isEmpty else { return 0 }
        let total = sessions.reduce(0.0) { $0 + $1.accuracy }
        return total / Double(sessions.count)
    }
    
    private var totalDurationString: String {
        let total = sessions.reduce(0.0) { $0 + $1.duration }
        let hours = Int(total) / 3600
        let minutes = (Int(total) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - 统计卡片

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - WPM 趋势图表

struct WPMTrendChart: View {
    let sessions: [PracticeSession]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("速度趋势")
                .font(.headline)
            
            if sessions.isEmpty {
                EmptyChartView(message: "暂无数据")
            } else {
                Chart(chartData) { item in
                    LineMark(
                        x: .value("日期", item.date),
                        y: .value("WPM", item.wpm)
                    )
                    .foregroundStyle(.blue)
                    .interpolationMethod(.catmullRom)
                    
                    PointMark(
                        x: .value("日期", item.date),
                        y: .value("WPM", item.wpm)
                    )
                    .foregroundStyle(.blue)
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private var chartData: [ChartDataPoint] {
        sessions.map { ChartDataPoint(date: $0.date, wpm: $0.wpm, accuracy: $0.accuracy) }
    }
}

// MARK: - 准确率趋势图表

struct AccuracyTrendChart: View {
    let sessions: [PracticeSession]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("准确率趋势")
                .font(.headline)
            
            if sessions.isEmpty {
                EmptyChartView(message: "暂无数据")
            } else {
                Chart(chartData) { item in
                    LineMark(
                        x: .value("日期", item.date),
                        y: .value("准确率", item.accuracy)
                    )
                    .foregroundStyle(.green)
                    .interpolationMethod(.catmullRom)
                    
                    PointMark(
                        x: .value("日期", item.date),
                        y: .value("准确率", item.accuracy)
                    )
                    .foregroundStyle(.green)
                }
                .frame(height: 200)
                .chartYScale(domain: 0...100)
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private var chartData: [ChartDataPoint] {
        sessions.map { ChartDataPoint(date: $0.date, wpm: $0.wpm, accuracy: $0.accuracy) }
    }
}

// MARK: - 模式分布图表

struct ModeDistributionChart: View {
    let sessions: [PracticeSession]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("练习模式分布")
                .font(.headline)
            
            if sessions.isEmpty {
                EmptyChartView(message: "暂无数据")
            } else {
                Chart(modeData) { item in
                    BarMark(
                        x: .value("模式", item.mode),
                        y: .value("次数", item.count)
                    )
                    .foregroundStyle(by: .value("模式", item.mode))
                }
                .frame(height: 200)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private var modeData: [ModeCount] {
        let grouped = Dictionary(grouping: sessions, by: { $0.mode })
        return grouped.map { ModeCount(mode: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }
}

// MARK: - 详细统计

struct DetailedStatistics: View {
    let sessions: [PracticeSession]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("详细统计")
                .font(.headline)
            
            if sessions.isEmpty {
                Text("暂无数据")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                VStack(spacing: 8) {
                    DetailRow(label: "最高速度", value: "\(maxWPM) WPM")
                    DetailRow(label: "最低速度", value: "\(minWPM) WPM")
                    DetailRow(label: "最高准确率", value: String(format: "%.1f%%", maxAccuracy))
                    DetailRow(label: "最低准确率", value: String(format: "%.1f%%", minAccuracy))
                    DetailRow(label: "总字数", value: "\(totalCharacters)")
                    DetailRow(label: "总错误数", value: "\(totalErrors)")
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private var maxWPM: Int {
        sessions.map { $0.wpm }.max() ?? 0
    }
    
    private var minWPM: Int {
        sessions.map { $0.wpm }.min() ?? 0
    }
    
    private var maxAccuracy: Double {
        sessions.map { $0.accuracy }.max() ?? 0
    }
    
    private var minAccuracy: Double {
        sessions.map { $0.accuracy }.min() ?? 0
    }
    
    private var totalCharacters: Int {
        sessions.reduce(0) { $0 + $1.targetText.count }
    }
    
    private var totalErrors: Int {
        sessions.reduce(0) { $0 + $1.errorCount }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 空图表视图

struct EmptyChartView: View {
    let message: String
    
    var body: some View {
        Text(message)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .frame(height: 200)
    }
}

// MARK: - 数据模型

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let wpm: Int
    let accuracy: Double
}

struct ModeCount: Identifiable {
    let id = UUID()
    let mode: String
    let count: Int
}

struct StatisticsView_Previews: PreviewProvider {
    static var previews: some View {
        StatisticsView()
            .modelContainer(for: [PracticeSession.self, FavoriteText.self], inMemory: true)
    }
}
