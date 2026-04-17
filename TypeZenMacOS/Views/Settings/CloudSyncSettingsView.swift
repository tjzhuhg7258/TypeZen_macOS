import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct CloudSyncSettingsView: View {
    @StateObject private var syncService = CloudSyncService.shared
    @Environment(\.modelContext) private var modelContext
    
    @State private var showSyncAlert = false
    @State private var syncAlertMessage = ""
    @State private var isSyncing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 标题
            Text("iCloud 同步")
                .font(.title2)
                .fontWeight(.bold)
            
            // iCloud 状态
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(syncService.isCloudKitConfigured ? (syncService.isCloudAvailable ? Color.green : Color.orange) : Color.red)
                        .frame(width: 12, height: 12)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        if !syncService.isCloudKitConfigured {
                            Text("CloudKit 未配置")
                                .font(.headline)
                            Text("需要在 Xcode 中添加 iCloud Capability")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else if syncService.isCloudAvailable {
                            Text("iCloud 已连接")
                                .font(.headline)
                        } else {
                            Text("iCloud 未连接")
                                .font(.headline)
                            Text("请在系统设置中登录 iCloud 账户")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Button("检查状态") {
                        syncService.checkCloudAvailability()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(!syncService.isCloudKitConfigured)
                }
                
                // 配置说明
                if !syncService.isCloudKitConfigured {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("配置步骤：")
                            .font(.caption)
                            .fontWeight(.semibold)
                        
                        Text("1. 在 Xcode 中选择项目 Target\n2. 选择 Signing & Capabilities 标签\n3. 点击 + Capability 按钮\n4. 选择 iCloud\n5. 勾选 CloudKit")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 4)
                }
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            .cornerRadius(8)
            
            // 最后同步时间
            if let lastSync = syncService.lastSyncDate {
                HStack {
                    Image(systemName: "clock")
                        .foregroundStyle(.secondary)
                    Text("上次同步: \(lastSync.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // 同步按钮
            VStack(spacing: 12) {
                Button {
                    performSync()
                } label: {
                    HStack {
                        if isSyncing {
                            ProgressView()
                                .scaleEffect(0.8)
                                .padding(.trailing, 4)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath.icloud")
                        }
                        Text(isSyncing ? "同步中..." : "立即同步")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(syncService.isCloudAvailable ? Color.accentColor : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(!syncService.isCloudAvailable || isSyncing)
                
                Text("将本地数据与 iCloud 同步，确保数据在所有设备上保持一致")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Divider()
            
            // 同步设置
            VStack(alignment: .leading, spacing: 12) {
                Text("同步设置")
                    .font(.headline)
                
                Toggle("自动同步", isOn: .constant(false))
                    .disabled(true)  // 暂时禁用自动同步
                
                Text("自动同步功能即将推出")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Divider()
            
            // 数据管理
            VStack(alignment: .leading, spacing: 12) {
                Text("数据管理")
                    .font(.headline)
                
                HStack(spacing: 12) {
                    Button {
                        exportData()
                    } label: {
                        Label("导出数据", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.bordered)
                    
                    Button {
                        importData()
                    } label: {
                        Label("导入数据", systemImage: "square.and.arrow.down")
                    }
                    .buttonStyle(.bordered)
                }
                
                Text("将练习记录和收藏导出为 JSON 文件，或从文件导入数据")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .alert("同步结果", isPresented: $showSyncAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(syncAlertMessage)
        }
        .fileExporter(
            isPresented: $showExportPicker,
            document: exportDocument,
            contentType: .json,
            defaultFilename: exportFilename
        ) { result in
            handleExportResult(result)
        }
        .fileImporter(
            isPresented: $showImportPicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleImportResult(result)
        }
    }
    
    // MARK: - 私有状态
    
    @State private var showExportPicker = false
    @State private var showImportPicker = false
    @State private var exportDocument: JSONDocument?
    @State private var exportFilename = "TypeZen_导出.json"
    
    // MARK: - 导出导入方法
    
    private func exportData() {
        Task {
            do {
                // 获取所有数据
                let sessions = try modelContext.fetch(FetchDescriptor<PracticeSession>())
                let favorites = try modelContext.fetch(FetchDescriptor<FavoriteText>())
                
                // 导出
                let url = try DataExportImportService.shared.exportData(sessions: sessions, favorites: favorites)
                let data = try Data(contentsOf: url)
                
                await MainActor.run {
                    exportDocument = JSONDocument(data: data)
                    exportFilename = url.lastPathComponent
                    showExportPicker = true
                }
            } catch {
                await MainActor.run {
                    syncAlertMessage = "导出失败: \(error.localizedDescription)"
                    showSyncAlert = true
                }
            }
        }
    }
    
    private func importData() {
        showImportPicker = true
    }
    
    private func handleExportResult(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            syncAlertMessage = "数据已成功导出到:\n\(url.path)"
            showSyncAlert = true
        case .failure(let error):
            syncAlertMessage = "导出失败: \(error.localizedDescription)"
            showSyncAlert = true
        }
    }
    
    private func handleImportResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            let hasAccess = url.startAccessingSecurityScopedResource()
            
            Task {
                defer {
                    if hasAccess {
                        url.stopAccessingSecurityScopedResource()
                    }
                }
                
                do {
                    let (sessionCount, favoriteCount) = try DataExportImportService.shared.importData(from: url, modelContext: modelContext)
                    
                    await MainActor.run {
                        syncAlertMessage = "导入成功！\n导入了 \(sessionCount) 条练习记录和 \(favoriteCount) 个收藏"
                        showSyncAlert = true
                    }
                } catch {
                    await MainActor.run {
                        syncAlertMessage = "导入失败: \(error.localizedDescription)"
                        showSyncAlert = true
                    }
                }
            }
        case .failure(let error):
            syncAlertMessage = "导入失败: \(error.localizedDescription)"
            showSyncAlert = true
        }
    }
    
    private func performSync() {
        isSyncing = true
        
        Task {
            do {
                try await syncService.performFullSync(modelContext: modelContext)
                
                await MainActor.run {
                    syncAlertMessage = "同步成功！数据已更新。"
                    showSyncAlert = true
                    isSyncing = false
                }
            } catch {
                await MainActor.run {
                    syncAlertMessage = "同步失败: \(error.localizedDescription)"
                    showSyncAlert = true
                    isSyncing = false
                }
            }
        }
    }
}

struct CloudSyncSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        CloudSyncSettingsView()
            .modelContainer(for: [PracticeSession.self, FavoriteText.self], inMemory: true)
    }
}
