import SwiftUI
import SwiftData
import AppKit

struct PracticeView: View {
    let mode: PracticeMode
    let customText: String
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var targetText = ""
    @State private var userInput = ""
    @State private var startTime: Date?
    @State private var errorCount = 0
    @State private var showResult = false
    @State private var currentSession: PracticeSession?
    @State private var hasFinishedCurrentRound = false
    @State private var isPaused = false
    @State private var accumulatedTime: TimeInterval = 0
    
    // 设置：是否显示输入高亮
    @AppStorage("showInputHighlight") private var showInputHighlight = true
    @AppStorage("autoSaveHistory") private var autoSaveHistory = true
    
    var body: some View {
        VStack(spacing: 30) {
            // 顶部工具栏
            HStack {
                Button("← 返回") {
                    dismiss()
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text(mode.rawValue)
                    .font(.headline)
                
                Spacer()
                
                Button(isPaused ? "▶ 继续" : "⏸ 暂停") {
                    togglePause()
                }
                .buttonStyle(.plain)
                .disabled(startTime == nil && accumulatedTime == 0 || hasFinishedCurrentRound)

                Button("重新开始") {
                    resetPractice()
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
            
            Spacer()
            
            // 目标文本区域（带进度高亮）
            VStack(spacing: 16) {
                HStack {
                    Text("请输入以下文本：")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    // 进度条
                    HStack(spacing: 8) {
                        let progress = min(Double(userInput.count), Double(targetText.count))
                        let total = Double(max(targetText.count, 1))
                        ProgressView(value: progress, total: total)
                            .frame(width: 120)
                        Text("\(userInput.count)/\(targetText.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
                .frame(maxWidth: 800)
                
                SyncedTargetTextView(
                    targetText: targetText,
                    userInput: userInput,
                    showInputHighlight: showInputHighlight,
                    fontSize: 24
                )
                .frame(maxWidth: 800, minHeight: 150, maxHeight: 260)
                .background(Color(.controlBackgroundColor))
                .cornerRadius(12)
            }
            
            // 用户输入区域
            VStack(spacing: 16) {
                TypingTextEditor(
                    text: $userInput,
                    fontSize: 22,
                    isEditable: !isPaused && !hasFinishedCurrentRound,
                    onTextChange: handleInputChange
                )
                    .frame(height: 220)
                    .padding(16)
                    .background(Color(.textBackgroundColor))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(getInputColor(), lineWidth: 2)
                    )
                    .frame(maxWidth: 800)
                    .overlay {
                        if isPaused {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                                .overlay {
                                    Text("已暂停")
                                        .font(.title2)
                                        .foregroundStyle(.secondary)
                                }
                        }
                    }

                // 实时统计
                HStack(spacing: 40) {
                    StatItem(label: "WPM", value: "\(calculateWPM())")
                    StatItem(label: "准确率", value: String(format: "%.1f%%", calculateAccuracy()))
                    StatItem(label: "错误数", value: "\(errorCount)")
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
        .onAppear {
            generateTargetText()
        }
        .sheet(isPresented: $showResult) {
            if let session = currentSession {
                ResultView(session: session, onRestart: {
                    showResult = false
                    resetPractice()
                }, onBackHome: {
                    showResult = false
                    dismiss()
                })
            }
        }
    }
    
    private func generateTargetText() {
        switch mode {
        case .words:
            targetText = FallbackData.words.shuffled().prefix(10).joined(separator: " ")
        case .idioms:
            targetText = FallbackData.idioms.shuffled().prefix(5).joined(separator: " ")
        case .articles:
            targetText = FallbackData.sentences.randomElement() ?? ""
        case .mixed:
            // 综合模式：混合词汇、成语和句子
            let mixedText = FallbackData.words.shuffled().prefix(3).joined(separator: " ") + " " +
                           FallbackData.idioms.shuffled().prefix(2).joined(separator: " ")
            targetText = mixedText
        case .custom:
            targetText = customText
        }
    }
    
    private func togglePause() {
        if isPaused {
            startTime = Date()
            isPaused = false
        } else {
            if let start = startTime {
                accumulatedTime += Date().timeIntervalSince(start)
            }
            startTime = nil
            isPaused = true
        }
    }

    private func handleInputChange(_ newValue: String) {
        guard !hasFinishedCurrentRound && !isPaused else { return }
        
        if startTime == nil && !newValue.isEmpty {
            startTime = Date()
        }
        
        // 计算错误数（实时更新）
        let minLength = min(newValue.count, targetText.count)
        var errors = 0
        for i in 0..<minLength {
            let userChar = newValue[newValue.index(newValue.startIndex, offsetBy: i)]
            let targetChar = targetText[targetText.index(targetText.startIndex, offsetBy: i)]
            if userChar != targetChar {
                errors += 1
            }
        }
        errorCount = errors
        
        // 检查是否完成：当输入长度达到目标长度时结束（不管是否有错误）
        if newValue.count >= targetText.count {
            hasFinishedCurrentRound = true
            // 避免在 TextEditor 布局周期内立刻弹窗导致布局递归警告
            DispatchQueue.main.async {
                finishPractice()
            }
        }
    }
    
    private func calculateWPM() -> Int {
        let currentSegment = startTime.map { Date().timeIntervalSince($0) } ?? 0
        let elapsed = accumulatedTime + currentSegment
        guard elapsed > 0 else { return 0 }

        let minutes = elapsed / 60.0
        return Int(Double(userInput.count) / minutes)
    }
    
    private func calculateAccuracy() -> Double {
        guard !targetText.isEmpty else { return 100.0 }
        let correctChars = targetText.count - errorCount
        return Double(correctChars) / Double(targetText.count) * 100.0
    }
    
    private func getInputColor() -> Color {
        if userInput.isEmpty {
            return Color.gray.opacity(0.3)
        }
        return calculateAccuracy() >= 95 ? .green : .orange
    }
    
    private func finishPractice() {
        let currentSegment = startTime.map { Date().timeIntervalSince($0) } ?? 0
        let duration = accumulatedTime + currentSegment
        
        let session = PracticeSession(
            mode: mode.rawValue,
            title: mode.rawValue,
            targetText: targetText,
            wpm: calculateWPM(),
            accuracy: calculateAccuracy(),
            errorCount: errorCount,
            duration: duration
        )
        
        // 保存用户输入
        session.userInput = userInput
        
        if autoSaveHistory {
            modelContext.insert(session)
            
            do {
                try modelContext.save()
                print("✅ 练习记录已保存: WPM=\(session.wpm), 准确率=\(String(format: "%.1f", session.accuracy))%")
            } catch {
                print("❌ 保存练习记录失败: \(error.localizedDescription)")
            }
        } else {
            print("ℹ️ 自动保存已关闭，本次练习结果未写入历史记录")
        }
        
        currentSession = session
        showResult = true
    }
    
    private func resetPractice() {
        userInput = ""
        startTime = nil
        errorCount = 0
        hasFinishedCurrentRound = false
        isPaused = false
        accumulatedTime = 0
        generateTargetText()
    }
}

private enum PracticeTextRenderer {
    static func makeAttributedString(targetText: String, userInput: String, showInputHighlight: Bool) -> AttributedString {
        guard showInputHighlight else {
            return AttributedString(targetText)
        }
        
        var attributedString = AttributedString(targetText)
        let targetChars = Array(targetText)
        let userChars = Array(userInput)
        var currentIndex = attributedString.startIndex
        
        for i in 0..<targetChars.count {
            guard currentIndex < attributedString.endIndex else { break }
            
            let nextIndex = attributedString.characters.index(after: currentIndex)
            let range = currentIndex..<nextIndex
            
            if i < userChars.count {
                if userChars[i] == targetChars[i] {
                    attributedString[range].foregroundColor = .green
                    attributedString[range].inlinePresentationIntent = .stronglyEmphasized
                } else {
                    attributedString[range].foregroundColor = .red
                    attributedString[range].underlineStyle = .single
                    attributedString[range].underlineColor = .red
                    attributedString[range].inlinePresentationIntent = .stronglyEmphasized
                }
            } else if i == userChars.count {
                attributedString[range].foregroundColor = .systemBlue
                attributedString[range].underlineStyle = .single
                attributedString[range].underlineColor = .systemBlue
                attributedString[range].inlinePresentationIntent = .stronglyEmphasized
            } else {
                attributedString[range].foregroundColor = .secondary
            }
            
            currentIndex = nextIndex
        }
        
        return attributedString
    }
}

/// 高亮显示文本视图 - 显示输入进度和错误
struct HighlightedTextView: View {
    let targetText: String
    let userInput: String
    
    var body: some View {
        Text(PracticeTextRenderer.makeAttributedString(
            targetText: targetText,
            userInput: userInput,
            showInputHighlight: true
        ))
            .lineSpacing(8)
    }
}

struct SyncedTargetTextView: NSViewRepresentable {
    let targetText: String
    let userInput: String
    let showInputHighlight: Bool
    let fontSize: CGFloat
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        
        let textView = NSTextView()
        textView.isEditable = false
        textView.isSelectable = false
        textView.isRichText = true
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.minSize = .zero
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainerInset = NSSize(width: 20, height: 20)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.lineBreakMode = .byWordWrapping
        textView.textContainer?.lineFragmentPadding = 0
        
        scrollView.documentView = textView
        configureLayout(for: textView, in: scrollView)
        update(textView: textView, in: scrollView)
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        configureLayout(for: textView, in: nsView)
        update(textView: textView, in: nsView)
    }
    
    private func configureLayout(for textView: NSTextView, in scrollView: NSScrollView) {
        let contentWidth = scrollView.contentSize.width
        textView.frame = NSRect(origin: .zero, size: NSSize(width: contentWidth, height: textView.frame.height))
        textView.textContainer?.containerSize = NSSize(width: contentWidth, height: CGFloat.greatestFiniteMagnitude)
    }
    
    private func update(textView: NSTextView, in scrollView: NSScrollView) {
        let attributedString = makeNSAttributedString()
        
        if textView.textStorage?.attributedSubstring(
            from: NSRange(location: 0, length: textView.textStorage?.length ?? 0)
        ) != attributedString {
            textView.textStorage?.setAttributedString(attributedString)
        }
        
        if
            let layoutManager = textView.layoutManager,
            let textContainer = textView.textContainer
        {
            layoutManager.ensureLayout(for: textContainer)
            let usedRect = layoutManager.usedRect(for: textContainer)
            let contentHeight = ceil(usedRect.height + textView.textContainerInset.height * 2)
            textView.frame.size = NSSize(
                width: scrollView.contentSize.width,
                height: max(contentHeight, scrollView.contentSize.height)
            )
        }
        
        guard !targetText.isEmpty else { return }
        
        let targetLocation = min(userInput.count, targetText.count - 1)
        let targetRange = NSRange(location: targetLocation, length: 1)
        guard
            let layoutManager = textView.layoutManager,
            let textContainer = textView.textContainer
        else {
            textView.scrollRangeToVisible(targetRange)
            return
        }
        
        layoutManager.ensureLayout(for: textContainer)
        let glyphRange = layoutManager.glyphRange(forCharacterRange: targetRange, actualCharacterRange: nil)
        let glyphRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
        
        let clipView = scrollView.contentView
        let visibleRect = clipView.documentVisibleRect
        let topThreshold = visibleRect.minY + visibleRect.height * 0.25
        let bottomThreshold = visibleRect.maxY - visibleRect.height * 0.25
        var desiredY = visibleRect.minY
        
        if glyphRect.minY < topThreshold {
            desiredY = max(glyphRect.minY - visibleRect.height * 0.2, 0)
        } else if glyphRect.maxY > bottomThreshold {
            desiredY = max(glyphRect.maxY - visibleRect.height * 0.8, 0)
        }
        
        let maxOffsetY = max(textView.frame.height - visibleRect.height, 0)
        let clampedY = min(max(desiredY, 0), maxOffsetY)
        
        if abs(clampedY - visibleRect.minY) > 1 {
            clipView.scroll(to: NSPoint(x: 0, y: clampedY))
            scrollView.reflectScrolledClipView(clipView)
        }
    }
    
    private func makeNSAttributedString() -> NSMutableAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 8
        
        let attributedString = NSMutableAttributedString(
            string: targetText,
            attributes: [
                .font: NSFont.systemFont(ofSize: fontSize, weight: .medium),
                .foregroundColor: NSColor.labelColor,
                .paragraphStyle: paragraphStyle
            ]
        )
        
        guard showInputHighlight, !targetText.isEmpty else {
            return attributedString
        }
        
        let targetChars = Array(targetText)
        let userChars = Array(userInput)
        
        for i in 0..<targetChars.count {
            let range = NSRange(location: i, length: 1)
            
            if i < userChars.count {
                if userChars[i] == targetChars[i] {
                    attributedString.addAttributes([
                        .foregroundColor: NSColor.systemGreen,
                        .font: NSFont.systemFont(ofSize: fontSize, weight: .semibold)
                    ], range: range)
                } else {
                    attributedString.addAttributes([
                        .foregroundColor: NSColor.systemRed,
                        .underlineStyle: NSUnderlineStyle.single.rawValue,
                        .underlineColor: NSColor.systemRed,
                        .font: NSFont.systemFont(ofSize: fontSize, weight: .bold)
                    ], range: range)
                }
            } else if i == userChars.count {
                attributedString.addAttributes([
                    .foregroundColor: NSColor.systemBlue,
                    .underlineStyle: NSUnderlineStyle.single.rawValue,
                    .underlineColor: NSColor.systemBlue,
                    .font: NSFont.systemFont(ofSize: fontSize, weight: .bold)
                ], range: range)
            } else {
                attributedString.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: range)
            }
        }
        
        return attributedString
    }
}

struct StatItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 28, weight: .bold))
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct TypingTextEditor: NSViewRepresentable {
    @Binding var text: String
    let fontSize: CGFloat
    let isEditable: Bool
    let onTextChange: (String) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        
        let textView = NSTextView()
        textView.delegate = context.coordinator
        textView.isEditable = isEditable
        textView.isRichText = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.font = .systemFont(ofSize: fontSize)
        textView.textColor = .labelColor
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.string = text
        textView.textContainerInset = NSSize(width: 0, height: 8)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.lineBreakMode = .byWordWrapping
        
        scrollView.documentView = textView
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        textView.isEditable = isEditable
        if textView.string != text {
            textView.string = text
            textView.scrollRangeToVisible(NSRange(location: text.count, length: 0))
        }
    }
    
    final class Coordinator: NSObject, NSTextViewDelegate {
        let parent: TypingTextEditor
        
        init(_ parent: TypingTextEditor) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            let newText = textView.string
            parent.text = newText
            parent.onTextChange(newText)
            textView.scrollRangeToVisible(textView.selectedRange())
        }
    }
}

#Preview {
    PracticeView(mode: .words, customText: "")
}
