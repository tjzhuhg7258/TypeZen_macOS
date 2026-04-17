import Foundation
import CloudKit
import SwiftData
import Combine
import Security

/// CloudKit 同步服务 - 处理数据云同步
@MainActor
class CloudSyncService: ObservableObject {
    static let shared = CloudSyncService()
    
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: Error?
    @Published var isCloudAvailable = false
    @Published var isCloudKitConfigured = false  // 标记是否配置了 CloudKit
    
    private var container: CKContainer?
    private var privateDatabase: CKDatabase?
    
    // 记录类型
    private let practiceSessionRecordType = "PracticeSession"
    private let favoriteTextRecordType = "FavoriteText"
    
    private init() {
        // 检查是否配置了 CloudKit
        checkCloudKitConfiguration()
        if isCloudKitConfigured {
            checkCloudAvailability()
        }
    }
    
    // 检查 CloudKit 是否在项目中配置
    private func checkCloudKitConfiguration() {
        isCloudKitConfigured = hasCloudKitEntitlement()
        if isCloudKitConfigured {
            _ = ensureCloudKitInitialized()
        } else {
            container = nil
            privateDatabase = nil
            syncError = CloudSyncError.notConfigured
        }
    }

    private func hasCloudKitEntitlement() -> Bool {
        guard let task = SecTaskCreateFromSelf(nil) else {
            return false
        }
        
        let serviceKey = "com.apple.developer.icloud-services" as CFString
        let containerKey = "com.apple.developer.icloud-container-identifiers" as CFString
        
        let services = SecTaskCopyValueForEntitlement(task, serviceKey, nil) as? [String]
        let containers = SecTaskCopyValueForEntitlement(task, containerKey, nil) as? [String]
        
        let hasCloudKitService = services?.contains("CloudKit") == true
        let hasContainer = !(containers?.isEmpty ?? true)
        
        return hasCloudKitService && hasContainer
    }
    
    private func ensureCloudKitInitialized() -> Bool {
        guard isCloudKitConfigured else {
            print("❌ CloudKit 未配置")
            return false
        }
        
        if container == nil {
            // 只在首次需要时初始化
            container = CKContainer.default()
            privateDatabase = container?.privateCloudDatabase
        }
        return container != nil
    }
    
    // MARK: - CloudKit 可用性检查
    
    func checkCloudAvailability() {
        guard isCloudKitConfigured else {
            isCloudAvailable = false
            syncError = CloudSyncError.notConfigured
            print("❌ CloudKit 未在 Xcode 中配置")
            return
        }
        
        guard ensureCloudKitInitialized(), let container = container else {
            isCloudAvailable = false
            syncError = CloudSyncError.cloudNotAvailable
            print("❌ CloudKit 容器未初始化")
            return
        }
        
        container.accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let error = error {
                    self.syncError = error
                    self.isCloudAvailable = false
                    // 无 CloudKit entitlement 时，会在这里失败；同时反映为“未配置”以匹配 UI 文案
                    self.isCloudKitConfigured = false
                    print("❌ CloudKit 状态检查失败: \(error.localizedDescription)")
                    return
                }
                
                switch status {
                case .available:
                    self.isCloudAvailable = true
                    print("✅ iCloud 可用")
                case .noAccount:
                    self.isCloudAvailable = false
                    print("❌ 未登录 iCloud 账户")
                case .restricted:
                    self.isCloudAvailable = false
                    print("❌ iCloud 受限")
                case .couldNotDetermine:
                    self.isCloudAvailable = false
                    print("❌ 无法确定 iCloud 状态")
                case .temporarilyUnavailable:
                    self.isCloudAvailable = false
                    print("⚠️ iCloud 暂时不可用")
                @unknown default:
                    self.isCloudAvailable = false
                }
            }
        }
    }
    
    // MARK: - 上传练习记录
    
    func uploadPracticeSession(_ session: PracticeSession) async throws {
        guard isCloudAvailable, let privateDatabase = privateDatabase else {
            throw CloudSyncError.cloudNotAvailable
        }
        
        let record = CKRecord(recordType: practiceSessionRecordType)
        record["sessionId"] = session.id.uuidString
        record["date"] = session.date
        record["mode"] = session.mode
        record["title"] = session.title  // 添加 title 字段
        record["targetText"] = session.targetText
        record["userInput"] = session.userInput
        record["wpm"] = session.wpm
        record["accuracy"] = session.accuracy
        record["errorCount"] = session.errorCount
        record["duration"] = session.duration
        
        try await privateDatabase.save(record)
        print("✅ 上传练习记录成功: \(session.id)")
    }
    
    // MARK: - 上传收藏文本
    
    func uploadFavoriteText(_ favorite: FavoriteText) async throws {
        guard isCloudAvailable, let privateDatabase = privateDatabase else {
            throw CloudSyncError.cloudNotAvailable
        }
        
        let record = CKRecord(recordType: favoriteTextRecordType)
        record["favoriteId"] = favorite.id.uuidString
        record["title"] = favorite.title
        record["content"] = favorite.content
        record["category"] = favorite.category
        record["createdAt"] = favorite.createdAt
        
        try await privateDatabase.save(record)
        print("✅ 上传收藏文本成功: \(favorite.id)")
    }
    
    // MARK: - 下载所有数据
    
    func downloadAllData() async throws -> (sessions: [PracticeSession], favorites: [FavoriteText]) {
        guard isCloudAvailable, let privateDatabase = privateDatabase else {
            throw CloudSyncError.cloudNotAvailable
        }
        
        isSyncing = true
        defer { isSyncing = false }
        
        // 下载练习记录
        let sessionQuery = CKQuery(recordType: practiceSessionRecordType, predicate: NSPredicate(value: true))
        sessionQuery.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        
        let sessionRecords = try await privateDatabase.records(matching: sessionQuery)
        let sessions = sessionRecords.matchResults.compactMap { _, result -> PracticeSession? in
            guard let record = try? result.get() else { return nil }
            return parsePracticeSession(from: record)
        }
        
        // 下载收藏文本
        let favoriteQuery = CKQuery(recordType: favoriteTextRecordType, predicate: NSPredicate(value: true))
        favoriteQuery.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        let favoriteRecords = try await privateDatabase.records(matching: favoriteQuery)
        let favorites = favoriteRecords.matchResults.compactMap { _, result -> FavoriteText? in
            guard let record = try? result.get() else { return nil }
            return parseFavoriteText(from: record)
        }
        
        lastSyncDate = Date()
        return (sessions, favorites)
    }
    
    // MARK: - 完整同步
    
    func performFullSync(modelContext: ModelContext) async throws {
        guard isCloudAvailable else {
            throw CloudSyncError.cloudNotAvailable
        }
        
        isSyncing = true
        defer { isSyncing = false }
        
        // 1. 下载云端数据
        let cloudData = try await downloadAllData()
        
        // 2. 获取本地数据
        let localSessions = try modelContext.fetch(FetchDescriptor<PracticeSession>())
        let localFavorites = try modelContext.fetch(FetchDescriptor<FavoriteText>())
        
        // 3. 合并数据（简单策略：云端优先）
        // 添加云端有但本地没有的记录
        for cloudSession in cloudData.sessions {
            if !localSessions.contains(where: { $0.id == cloudSession.id }) {
                modelContext.insert(cloudSession)
            }
        }
        
        for cloudFavorite in cloudData.favorites {
            if !localFavorites.contains(where: { $0.id == cloudFavorite.id }) {
                modelContext.insert(cloudFavorite)
            }
        }
        
        // 4. 上传本地有但云端没有的记录
        let cloudSessionIds = Set(cloudData.sessions.map { $0.id })
        let cloudFavoriteIds = Set(cloudData.favorites.map { $0.id })
        
        for localSession in localSessions {
            if !cloudSessionIds.contains(localSession.id) {
                try await uploadPracticeSession(localSession)
            }
        }
        
        for localFavorite in localFavorites {
            if !cloudFavoriteIds.contains(localFavorite.id) {
                try await uploadFavoriteText(localFavorite)
            }
        }
        
        try modelContext.save()
        lastSyncDate = Date()
        print("✅ 完整同步完成")
    }
    
    // MARK: - 删除云端记录
    
    func deletePracticeSession(id: UUID) async throws {
        guard isCloudAvailable, let privateDatabase = privateDatabase else {
            throw CloudSyncError.cloudNotAvailable
        }
        
        let query = CKQuery(
            recordType: practiceSessionRecordType,
            predicate: NSPredicate(format: "sessionId == %@", id.uuidString)
        )
        
        let records = try await privateDatabase.records(matching: query)
        for (recordID, _) in records.matchResults {
            try await privateDatabase.deleteRecord(withID: recordID)
        }
    }
    
    func deleteFavoriteText(id: UUID) async throws {
        guard isCloudAvailable, let privateDatabase = privateDatabase else {
            throw CloudSyncError.cloudNotAvailable
        }
        
        let query = CKQuery(
            recordType: favoriteTextRecordType,
            predicate: NSPredicate(format: "favoriteId == %@", id.uuidString)
        )
        
        let records = try await privateDatabase.records(matching: query)
        for (recordID, _) in records.matchResults {
            try await privateDatabase.deleteRecord(withID: recordID)
        }
    }
    
    // MARK: - 解析方法
    
    private func parsePracticeSession(from record: CKRecord) -> PracticeSession? {
        guard let sessionId = record["sessionId"] as? String,
              let id = UUID(uuidString: sessionId),
              let date = record["date"] as? Date,
              let mode = record["mode"] as? String,
              let targetText = record["targetText"] as? String,
              let userInput = record["userInput"] as? String,
              let wpm = record["wpm"] as? Int,
              let accuracy = record["accuracy"] as? Double,
              let errorCount = record["errorCount"] as? Int,
              let duration = record["duration"] as? TimeInterval else {
            return nil
        }
        
        let title = record["title"] as? String ?? mode // 兼容旧数据
        
        return PracticeSession(
            id: id,
            date: date,
            mode: mode,
            title: title,
            targetText: targetText,
            userInput: userInput,
            wpm: wpm,
            accuracy: accuracy,
            errorCount: errorCount,
            duration: duration
        )
    }
    
    private func parseFavoriteText(from record: CKRecord) -> FavoriteText? {
        guard let favoriteId = record["favoriteId"] as? String,
              let id = UUID(uuidString: favoriteId),
              let title = record["title"] as? String,
              let content = record["content"] as? String,
              let createdAt = record["createdAt"] as? Date else {
            return nil
        }
        
        // category 是后添加的，可能为空
        let category = record["category"] as? String ?? "自定义"
        
        return FavoriteText(
            id: id,
            title: title,
            content: content,
            category: category,
            createdAt: createdAt
        )
    }
}

// MARK: - 错误定义

enum CloudSyncError: LocalizedError {
    case notConfigured
    case cloudNotAvailable
    case syncFailed(String)
    case uploadFailed
    case downloadFailed
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "iCloud 未配置。请在 Xcode 中添加 iCloud Capability：\n1. 选择项目 Target\n2. 点击 Signing & Capabilities\n3. 点击 + Capability\n4. 选择 iCloud\n5. 勾选 CloudKit"
        case .cloudNotAvailable:
            return "iCloud 不可用。请确保已登录 iCloud 账户并启用了 iCloud Drive。"
        case .syncFailed(let message):
            return "同步失败: \(message)"
        case .uploadFailed:
            return "上传数据失败，请稍后重试"
        case .downloadFailed:
            return "下载数据失败，请检查网络连接"
        }
    }
}
