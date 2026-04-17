import Foundation

/// 成就系统
class AchievementSystem {
    static let shared = AchievementSystem()
    
    private init() {}
    
    // MARK: - 成就定义
    
    func getAllAchievements() -> [Achievement] {
        return [
            // 速度成就
            Achievement(
                id: "speed_50",
                title: "初级打字员",
                description: "达到 50 WPM",
                icon: "🎯",
                category: .speed,
                requirement: 50,
                isUnlocked: false
            ),
            Achievement(
                id: "speed_80",
                title: "中级打字员",
                description: "达到 80 WPM",
                icon: "⚡️",
                category: .speed,
                requirement: 80,
                isUnlocked: false
            ),
            Achievement(
                id: "speed_100",
                title: "高级打字员",
                description: "达到 100 WPM",
                icon: "🚀",
                category: .speed,
                requirement: 100,
                isUnlocked: false
            ),
            Achievement(
                id: "speed_120",
                title: "打字大师",
                description: "达到 120 WPM",
                icon: "👑",
                category: .speed,
                requirement: 120,
                isUnlocked: false
            ),
            
            // 准确率成就
            Achievement(
                id: "accuracy_95",
                title: "精准射手",
                description: "准确率达到 95%",
                icon: "🎯",
                category: .accuracy,
                requirement: 95,
                isUnlocked: false
            ),
            Achievement(
                id: "accuracy_98",
                title: "完美主义者",
                description: "准确率达到 98%",
                icon: "💎",
                category: .accuracy,
                requirement: 98,
                isUnlocked: false
            ),
            Achievement(
                id: "accuracy_99",
                title: "神枪手",
                description: "准确率达到 99%",
                icon: "🏆",
                category: .accuracy,
                requirement: 99,
                isUnlocked: false
            ),
            
            // 练习量成就
            Achievement(
                id: "practice_10",
                title: "初学者",
                description: "完成 10 次练习",
                icon: "📝",
                category: .practice,
                requirement: 10,
                isUnlocked: false
            ),
            Achievement(
                id: "practice_50",
                title: "勤奋练习",
                description: "完成 50 次练习",
                icon: "📚",
                category: .practice,
                requirement: 50,
                isUnlocked: false
            ),
            Achievement(
                id: "practice_100",
                title: "百炼成钢",
                description: "完成 100 次练习",
                icon: "💪",
                category: .practice,
                requirement: 100,
                isUnlocked: false
            ),
            Achievement(
                id: "practice_500",
                title: "练习狂人",
                description: "完成 500 次练习",
                icon: "🔥",
                category: .practice,
                requirement: 500,
                isUnlocked: false
            ),
            
            // 连续练习成就
            Achievement(
                id: "streak_3",
                title: "三天打卡",
                description: "连续练习 3 天",
                icon: "📅",
                category: .streak,
                requirement: 3,
                isUnlocked: false
            ),
            Achievement(
                id: "streak_7",
                title: "一周坚持",
                description: "连续练习 7 天",
                icon: "🌟",
                category: .streak,
                requirement: 7,
                isUnlocked: false
            ),
            Achievement(
                id: "streak_30",
                title: "月度冠军",
                description: "连续练习 30 天",
                icon: "🏅",
                category: .streak,
                requirement: 30,
                isUnlocked: false
            ),
            
            // 时长成就
            Achievement(
                id: "duration_1h",
                title: "一小时修炼",
                description: "累计练习 1 小时",
                icon: "⏱️",
                category: .duration,
                requirement: 60,
                isUnlocked: false
            ),
            Achievement(
                id: "duration_10h",
                title: "十小时苦练",
                description: "累计练习 10 小时",
                icon: "⏳",
                category: .duration,
                requirement: 600,
                isUnlocked: false
            ),
            Achievement(
                id: "duration_100h",
                title: "百小时大师",
                description: "累计练习 100 小时",
                icon: "🎓",
                category: .duration,
                requirement: 6000,
                isUnlocked: false
            )
        ]
    }
    
    // MARK: - 检查成就
    
    func checkAchievements(sessions: [PracticeSession]) -> [Achievement] {
        var achievements = getAllAchievements()
        
        guard !sessions.isEmpty else {
            return achievements
        }
        
        // 检查速度成就
        let maxWPM = sessions.map { $0.wpm }.max() ?? 0
        for i in 0..<achievements.count {
            if achievements[i].category == .speed {
                achievements[i].isUnlocked = maxWPM >= achievements[i].requirement
            }
        }
        
        // 检查准确率成就
        let maxAccuracy = sessions.map { $0.accuracy }.max() ?? 0
        for i in 0..<achievements.count {
            if achievements[i].category == .accuracy {
                achievements[i].isUnlocked = maxAccuracy >= Double(achievements[i].requirement)
            }
        }
        
        // 检查练习量成就
        let practiceCount = sessions.count
        for i in 0..<achievements.count {
            if achievements[i].category == .practice {
                achievements[i].isUnlocked = practiceCount >= achievements[i].requirement
            }
        }
        
        // 检查连续练习成就
        let streak = calculateStreak(sessions: sessions)
        for i in 0..<achievements.count {
            if achievements[i].category == .streak {
                achievements[i].isUnlocked = streak >= achievements[i].requirement
            }
        }
        
        // 检查时长成就
        let totalMinutes = sessions.reduce(0.0) { $0 + $1.duration } / 60
        for i in 0..<achievements.count {
            if achievements[i].category == .duration {
                achievements[i].isUnlocked = Int(totalMinutes) >= achievements[i].requirement
            }
        }
        
        return achievements
    }
    
    // MARK: - 计算连续天数
    
    private func calculateStreak(sessions: [PracticeSession]) -> Int {
        let calendar = Calendar.current
        let sortedDates = sessions.map { calendar.startOfDay(for: $0.date) }
            .sorted(by: >)
        
        guard let mostRecent = sortedDates.first else {
            return 0
        }
        
        let today = calendar.startOfDay(for: Date())
        
        // 如果最近一次练习不是今天或昨天，连续天数为 0
        if mostRecent < calendar.date(byAdding: .day, value: -1, to: today)! {
            return 0
        }
        
        var streak = 0
        var currentDate = today
        
        for date in sortedDates {
            if date == currentDate {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
            } else if date < currentDate {
                break
            }
        }
        
        return streak
    }
}

// MARK: - 成就模型

struct Achievement: Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let category: AchievementCategory
    let requirement: Int
    var isUnlocked: Bool
    
    var progress: Double {
        // 这里简化处理，实际应该根据当前数据计算进度
        return isUnlocked ? 1.0 : 0.0
    }
}

enum AchievementCategory: String, CaseIterable {
    case speed = "速度"
    case accuracy = "准确率"
    case practice = "练习量"
    case streak = "连续练习"
    case duration = "练习时长"
}
