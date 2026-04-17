import SwiftUI

struct ResultView: View {
    let session: PracticeSession
    let onRestart: () -> Void
    let onBackHome: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // 成绩标题
            VStack(spacing: 10) {
                Text("🎉")
                    .font(.system(size: 50))
                
                Text("练习完成！")
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }
            .padding(.top, 30)
            
            // 成绩统计
            VStack(spacing: 16) {
                ResultCard(title: "打字速度", value: "\(session.wpm)", unit: "字/分")
                ResultCard(title: "准确率", value: String(format: "%.1f", session.accuracy), unit: "%")
                ResultCard(title: "错误数", value: "\(session.errorCount)", unit: "个")
                ResultCard(title: "用时", value: String(format: "%.1f", session.duration), unit: "秒")
            }
            .padding(.horizontal, 60)
            
            // 评价
            Text(getComment())
                .font(.title3)
                .foregroundStyle(.secondary)
                .padding(.vertical, 10)
            
            // 操作按钮
            HStack(spacing: 20) {
                Button {
                    onBackHome()
                } label: {
                    Text("返回首页")
                        .frame(width: 150)
                        .padding()
                        .background(Color(.controlBackgroundColor))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                
                Button {
                    onRestart()
                } label: {
                    Text("继续练习")
                        .frame(width: 150)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 20)
            .padding(.bottom, 30)
        }
        .frame(width: 600, height: 600)
        .background(Color(.windowBackgroundColor))
    }
    
    private func getComment() -> String {
        switch session.wpm {
        case 0..<30:
            return "慢慢来，熟能生巧！"
        case 30..<60:
            return "不错的开始，继续加油！"
        case 60..<90:
            return "很好！速度稳步提升！"
        case 90..<120:
            return "厉害！打字高手！"
        default:
            return "太棒了！速度惊人！"
        }
    }
}

struct ResultCard: View {
    let title: String
    let value: String
    let unit: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
                .frame(width: 120, alignment: .leading)
            
            Spacer()
            
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 32, weight: .bold))
                Text(unit)
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct ResultView_Previews: PreviewProvider {
    static var previews: some View {
        ResultView(
            session: PracticeSession(
                mode: "随机词汇",
                title: "测试",
                targetText: "示例文本",
                wpm: 85,
                accuracy: 96.5,
                errorCount: 3,
                duration: 45.2
            ),
            onRestart: {},
            onBackHome: {}
        )
    }
}
