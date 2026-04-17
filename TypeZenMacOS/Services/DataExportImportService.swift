import Foundation
import SwiftData

/// 数据导出导入服务
class DataExportImportService {
    static let shared = DataExportImportService()
    
    private init() {}
    
    // MARK: - 导出数据
    
    /// 导出所有数据到 JSON 文件
    func exportData(sessions: [PracticeSession], favorites: [FavoriteText]) throws -> URL {
        let exportData = ExportData(
            sessions: sessions.map { SessionExportModel(from: $0) },
            favorites: favorites.map { FavoriteExportModel(from: $0) },
            exportDate: Date(),
            version: "1.0"
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let jsonData = try encoder.encode(exportData)
        
        // 创建临时文件
        let filename = "TypeZen_导出_\(Date().formatted(date: .abbreviated, time: .omitted)).json"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        
        try jsonData.write(to: tempURL)
        
        print("✅ 数据已导出到: \(tempURL.path)")
        return tempURL
    }
    
    // MARK: - 导入数据
    
    /// 从 JSON 文件导入数据
    func importData(from url: URL, modelContext: ModelContext) throws -> (sessionCount: Int, favoriteCount: Int) {
        let jsonData = try Data(contentsOf: url)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let importData = try decoder.decode(ExportData.self, from: jsonData)
        
        var sessionCount = 0
        var favoriteCount = 0
        
        // 获取现有数据的 ID
        let existingSessions = try modelContext.fetch(FetchDescriptor<PracticeSession>())
        let existingFavorites = try modelContext.fetch(FetchDescriptor<FavoriteText>())
        
        let existingSessionIds = Set(existingSessions.map { $0.id })
        let existingFavoriteIds = Set(existingFavorites.map { $0.id })
        
        // 导入练习记录（避免重复）
        for sessionModel in importData.sessions {
            if !existingSessionIds.contains(sessionModel.id) {
                let session = sessionModel.toPracticeSession()
                modelContext.insert(session)
                sessionCount += 1
            }
        }
        
        // 导入收藏文本（避免重复）
        for favoriteModel in importData.favorites {
            if !existingFavoriteIds.contains(favoriteModel.id) {
                let favorite = favoriteModel.toFavoriteText()
                modelContext.insert(favorite)
                favoriteCount += 1
            }
        }
        
        try modelContext.save()
        
        print("✅ 导入完成: \(sessionCount) 条记录, \(favoriteCount) 个收藏")
        return (sessionCount, favoriteCount)
    }
}

// MARK: - 导出数据模型

struct ExportData: Codable {
    let sessions: [SessionExportModel]
    let favorites: [FavoriteExportModel]
    let exportDate: Date
    let version: String
}

struct SessionExportModel: Codable {
    let id: UUID
    let date: Date
    let mode: String
    let title: String
    let targetText: String
    let userInput: String
    let wpm: Int
    let accuracy: Double
    let errorCount: Int
    let duration: TimeInterval
    
    init(from session: PracticeSession) {
        self.id = session.id
        self.date = session.date
        self.mode = session.mode
        self.title = session.title
        self.targetText = session.targetText
        self.userInput = session.userInput
        self.wpm = session.wpm
        self.accuracy = session.accuracy
        self.errorCount = session.errorCount
        self.duration = session.duration
    }
    
    func toPracticeSession() -> PracticeSession {
        // 使用完整的初始化器，包括 id 和 date
        return PracticeSession(id: id, date: date, mode: mode, title: title, targetText: targetText, userInput: userInput, wpm: wpm, accuracy: accuracy, errorCount: errorCount, duration: duration)
    }
}

struct FavoriteExportModel: Codable {
    let id: UUID
    let title: String
    let content: String
    let category: String
    let createdAt: Date
    
    init(from favorite: FavoriteText) {
        self.id = favorite.id
        self.title = favorite.title
        self.content = favorite.content
        self.category = favorite.category
        self.createdAt = favorite.createdAt
    }
    
    func toFavoriteText() -> FavoriteText {
        return FavoriteText(id: id, title: title, content: content, category: category, createdAt: createdAt)
    }
}
