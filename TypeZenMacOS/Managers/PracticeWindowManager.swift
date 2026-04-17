import SwiftUI
import SwiftData

/// 练习窗口管理器
@MainActor
class PracticeWindowManager {
    static let shared = PracticeWindowManager()
    
    private var window: NSWindow?
    
    private init() {}
    
    func openPracticeWindow(mode: PracticeMode, customText: String, modelContainer: ModelContainer) {
        // 如果窗口已存在，关闭它
        window?.close()
        
        // 创建带有 modelContainer 的内容视图
        let contentView = PracticeView(mode: mode, customText: customText)
            .modelContainer(modelContainer)
        
        let hostingController = NSHostingController(rootView: contentView)
        
        let newWindow = NSWindow(contentViewController: hostingController)
        newWindow.title = "TypeZen - \(mode.rawValue)"
        newWindow.setContentSize(NSSize(width: 1000, height: 800))
        newWindow.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        newWindow.minSize = NSSize(width: 900, height: 700)
        newWindow.center()
        newWindow.makeKeyAndOrderFront(nil)
        
        self.window = newWindow
    }
}
