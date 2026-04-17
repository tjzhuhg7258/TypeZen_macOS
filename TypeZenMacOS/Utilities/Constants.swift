import Foundation
import SwiftUI

enum PracticeMode: String, CaseIterable {
    case words = "随机词汇"
    case idioms = "四字成语"
    case articles = "文章段落"
    case mixed = "综合模式"
    case custom = "自定义文本"
    
    var icon: String {
        switch self {
        case .words: return "character.bubble.fill"
        case .idioms: return "text.badge.checkmark"
        case .articles: return "doc.text.fill"
        case .mixed: return "square.grid.2x2.fill"
        case .custom: return "pencil.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .words: return .blue
        case .idioms: return .purple
        case .articles: return .green
        case .mixed: return .orange
        case .custom: return .pink
        }
    }
    
    var description: String {
        switch self {
        case .words: return "常用词汇练习"
        case .idioms: return "成语典故练习"
        case .articles: return "文章段落练习"
        case .mixed: return "综合模式练习"
        case .custom: return "自定义内容"
        }
    }
}

struct FallbackData {
    static let words = [
        "我们", "生活", "世界", "通过", "发展", "自己", "时候", "虽然", "但是", "因为",
        "所以", "如果", "可能", "开始", "认为", "需要", "感觉", "告诉", "希望", "觉得",
        "一切", "一定", "一直", "一起", "已经", "意思", "引起", "应该", "永远", "完成",
        "科技", "创新", "未来", "智能", "数据", "网络", "连接", "系统", "程序", "设计"
    ]
    
    static let idioms = [
        "半途而废", "不可思议", "各抒己见", "恍然大悟", "津津有味", "精益求精",
        "理所当然", "全力以赴", "实事求是", "随遇而安", "画蛇添足", "守株待兔",
        "掩耳盗铃", "亡羊补牢", "刻舟求剑", "杯弓蛇影", "对牛弹琴", "画龙点睛"
    ]
    
    static let sentences = [
        "海内存知己，天涯若比邻。",
        "三人行，必有我师焉。",
        "学而不思则罔，思而不学则殆。",
        "千里之行，始于足下。",
        "欲穷千里目，更上一层楼。",
        "长风破浪会有时，直挂云帆济沧海。"
    ]
}
