import Foundation
import SwiftData

@Model
class FavoriteText {
    var id: UUID
    var title: String
    var content: String
    var category: String  // 分类/主题
    var createdAt: Date
    
    // 标准初始化方法
    init(title: String, content: String, category: String = "自定义") {
        self.id = UUID()
        self.title = title
        self.content = content
        self.category = category
        self.createdAt = Date()
    }
    
    // 便捷初始化方法（用于AI生成的文本，text参数会自动生成title）
    convenience init(text: String, category: String, createdAt: Date = Date()) {
        let dateStr = createdAt.formatted(date: .abbreviated, time: .omitted)
        self.init(
            title: "\(category) - \(dateStr)",
            content: text,
            category: category
        )
        self.createdAt = createdAt
    }
    
    // CloudKit 同步使用的完整初始化器
    init(id: UUID, title: String, content: String, category: String, createdAt: Date) {
        self.id = id
        self.title = title
        self.content = content
        self.category = category
        self.createdAt = createdAt
    }
}
