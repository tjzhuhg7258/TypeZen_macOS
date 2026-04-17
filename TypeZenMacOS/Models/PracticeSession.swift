import Foundation
import SwiftData

@Model
class PracticeSession {
    var id: UUID
    var date: Date
    var mode: String
    var title: String
    var targetText: String
    var userInput: String  // 添加用户输入字段
    var wpm: Int
    var accuracy: Double
    var errorCount: Int
    var duration: TimeInterval
    
    init(mode: String, title: String, targetText: String, wpm: Int = 0, accuracy: Double = 100.0, errorCount: Int = 0, duration: TimeInterval = 0) {
        self.id = UUID()
        self.date = Date()
        self.mode = mode
        self.title = title
        self.targetText = targetText
        self.userInput = ""
        self.wpm = wpm
        self.accuracy = accuracy
        self.errorCount = errorCount
        self.duration = duration
    }
    
    // CloudKit 同步使用的完整初始化器
    init(id: UUID, date: Date, mode: String, title: String, targetText: String, userInput: String, wpm: Int, accuracy: Double, errorCount: Int, duration: TimeInterval) {
        self.id = id
        self.date = date
        self.mode = mode
        self.title = title
        self.targetText = targetText
        self.userInput = userInput
        self.wpm = wpm
        self.accuracy = accuracy
        self.errorCount = errorCount
        self.duration = duration
    }
}

