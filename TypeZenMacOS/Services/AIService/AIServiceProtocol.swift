import Foundation

/// AI 服务协议 - 定义所有 AI 服务必须实现的接口
protocol AIServiceProtocol {
    /// 服务名称
    var serviceName: String { get }
    
    /// 是否已配置（API Key 已设置）
    var isConfigured: Bool { get }
    
    /// 生成中文打字练习文本
    /// - Parameters:
    ///   - mode: 练习模式 (words/idioms/sentences/custom)
    ///   - difficulty: 难度级别 (1-5)
    ///   - count: 生成数量
    /// - Returns: 生成的文本数组
    func generatePracticeText(mode: String, difficulty: Int, count: Int, sourceMaterial: String?) async throws -> [String]
    
    /// 生成自定义主题文本
    /// - Parameter prompt: 用户提示词
    /// - Returns: 生成的文本
    func generateCustomText(prompt: String) async throws -> String
}

/// AI 服务错误类型
enum AIServiceError: LocalizedError {
    case notConfigured
    case invalidAPIKey
    case networkError
    case rateLimitExceeded
    case invalidResponse
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "AI 服务未配置，请在设置中添加 API Key"
        case .invalidAPIKey:
            return "API Key 无效，请检查后重试"
        case .networkError:
            return "网络连接失败，请检查网络设置"
        case .rateLimitExceeded:
            return "API 调用次数超限，请稍后重试"
        case .invalidResponse:
            return "AI 服务响应格式错误"
        case .unknownError(let message):
            return "未知错误: \(message)"
        }
    }
}
