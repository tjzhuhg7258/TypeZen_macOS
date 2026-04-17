import SwiftUI
import AppKit
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    @State private var selectedTab = 0
    @State private var selectedMode: PracticeMode?
    @State private var customText = ""
    @State private var showPractice = false
    
    var body: some View {
        NavigationSplitView {
            // 侧边栏
            List(selection: $selectedTab) {
                Label("首页", systemImage: "house.fill")
                    .tag(0)
                
                Label("历史记录", systemImage: "clock.arrow.circlepath")
                    .tag(1)
                
                Label("统计", systemImage: "chart.bar.fill")
                    .tag(2)
                
                Label("收藏", systemImage: "star.fill")
                    .tag(3)
                
                Divider()
                
                Label("设置", systemImage: "gearshape.fill")
                    .tag(4)
            }
            .navigationSplitViewColumnWidth(200)
        } detail: {
            // 主内容区域
            Group {
                switch selectedTab {
                case 0:
                    HomeView(
                        selectedMode: $selectedMode,
                        customText: $customText,
                        showPractice: $showPractice
                    )
                case 1:
                    HistoryView()
                case 2:
                    StatisticsView()
                case 3:
                    FavoritesView(onStartPractice: { text in
                        customText = text
                        selectedMode = .custom
                        showPractice = true
                    })
                case 4:
                    SettingsView()
                default:
                    Text("未知页面")
                }
            }
        }
        .onChange(of: showPractice) { _, newValue in
            if newValue, let mode = selectedMode {
                // 传递 modelContainer 以支持数据保存
                PracticeWindowManager.shared.openPracticeWindow(
                    mode: mode,
                    customText: customText,
                    modelContainer: modelContext.container
                )
                // 重置状态
                showPractice = false
                selectedMode = nil
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .modelContainer(for: [PracticeSession.self, FavoriteText.self], inMemory: true)
    }
}
