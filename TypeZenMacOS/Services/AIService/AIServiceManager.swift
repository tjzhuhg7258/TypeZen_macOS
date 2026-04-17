import Foundation
import Combine

/// AI 服务管理器 - 管理多个 AI 服务的优先级和回退机制
class AIServiceManager: ObservableObject {
    static let shared = AIServiceManager()
    
    // 使用具体类型而不是协议类型
    private var geminiService = GeminiService()
    private var openAIService = OpenAIService()
    private var claudeService = ClaudeService()
    
    @Published var enabledServices: [String] = []  // 存储已启用服务的名称
    
    private init() {
        // 从 UserDefaults 加载启用的服务列表
        loadEnabledServices()
    }
    
    // MARK: - 获取所有服务
    var allServices: [(name: String, service: any AIServiceProtocol)] {
        return [
            ("Google Gemini", geminiService),
            ("OpenAI GPT", openAIService),
            ("Anthropic Claude", claudeService)
        ]
    }
    
    // MARK: - 生成打字练习文本（带回退机制）
    func generatePracticeText(mode: String, difficulty: Int = 3, count: Int = 10, sourceURL: String? = nil) async throws -> [String] {
        let normalizedMode = normalizeMode(mode)
        let sourceMaterial = try await fetchSourceMaterialIfNeeded(sourceURL)
        
        // 按优先级尝试每个已配置的服务
        let configuredServices = allServices.filter { 
            $0.service.isConfigured && isServiceEnabled($0.name)
        }
        
        if configuredServices.isEmpty {
            // 如果没有配置 AI 服务，返回内置词库
            return getFallbackText(mode: normalizedMode, count: count)
        }
        
        for (name, service) in configuredServices {
            do {
                let result = try await service.generatePracticeText(
                    mode: normalizedMode,
                    difficulty: difficulty,
                    count: count,
                    sourceMaterial: sourceMaterial
                )
                if !result.isEmpty {
                    return result
                }
            } catch {
                // 记录错误并继续尝试下一个服务
                print("[\(name)] 生成失败: \(error.localizedDescription)")
                continue
            }
        }
        
        // 所有 AI 服务都失败，回退到内置词库
        print("所有 AI 服务都失败，使用内置词库")
        return getFallbackText(mode: normalizedMode, count: count)
    }
    
    // MARK: - 生成自定义文本（带回退机制）
    func generateCustomText(prompt: String) async throws -> String {
        let configuredServices = allServices.filter { 
            $0.service.isConfigured && isServiceEnabled($0.name)
        }
        
        guard !configuredServices.isEmpty else {
            throw AIServiceError.notConfigured
        }
        
        var lastError: Error?
        
        for (name, service) in configuredServices {
            do {
                let result = try await service.generateCustomText(prompt: prompt)
                if !result.isEmpty {
                    return result
                }
            } catch {
                lastError = error
                print("[\(name)] 生成失败: \(error.localizedDescription)")
                continue
            }
        }
        
        // 所有服务都失败
        throw lastError ?? AIServiceError.unknownError("所有 AI 服务都失败")
    }
    
    // MARK: - 服务管理
    
    func isServiceEnabled(_ serviceName: String) -> Bool {
        return enabledServices.contains(serviceName)
    }
    
    func toggleService(_ serviceName: String) {
        if let index = enabledServices.firstIndex(of: serviceName) {
            enabledServices.remove(at: index)
        } else {
            enabledServices.append(serviceName)
        }
        saveEnabledServices()
    }
    
    private func loadEnabledServices() {
        if let saved = UserDefaults.standard.stringArray(forKey: "enabledAIServices") {
            enabledServices = saved
        } else {
            // 默认启用所有服务
            enabledServices = allServices.map { $0.name }
        }
    }
    
    private func saveEnabledServices() {
        UserDefaults.standard.set(enabledServices, forKey: "enabledAIServices")
    }
    
    // MARK: - 内置词库回退
    
    private func normalizeMode(_ mode: String) -> String {
        switch mode.lowercased() {
        case "article", "articles":
            return "sentences"
        default:
            return mode
        }
    }
    
    private func getFallbackText(mode: String, count: Int) -> [String] {
        switch mode {
        case "words":
            return Array(FallbackData.words.shuffled().prefix(count))
        case "idioms":
            return Array(FallbackData.idioms.shuffled().prefix(count))
        case "sentences":
            return Array(FallbackData.sentences.shuffled().prefix(count))
        default:
            return Array(FallbackData.words.shuffled().prefix(count))
        }
    }
    
    private func fetchSourceMaterialIfNeeded(_ sourceURL: String?) async throws -> String? {
        guard let raw = sourceURL?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return nil
        }
        
        guard let url = URL(string: raw), let scheme = url.scheme?.lowercased(), ["http", "https"].contains(scheme) else {
            throw AIServiceError.unknownError("链接格式无效，请输入 http/https 链接")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 20
        request.setValue(
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) TypeZen/1.0",
            forHTTPHeaderField: "User-Agent"
        )
        
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw AIServiceError.unknownError("无法访问链接内容：\(error.localizedDescription)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw AIServiceError.unknownError("链接访问失败，请检查链接是否可访问")
        }
        
        guard let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .unicode) else {
            throw AIServiceError.unknownError("链接内容解析失败")
        }
        
        let plain = htmlToPlainText(html)
        guard plain.count >= 50 else {
            throw AIServiceError.unknownError("链接内容过短，无法用于生成练习文本")
        }
        
        return String(plain.prefix(6000))
    }
    
    private func htmlToPlainText(_ html: String) -> String {
        var text = html
        let patterns = [
            "(?is)<script[^>]*>.*?</script>",
            "(?is)<style[^>]*>.*?</style>",
            "(?is)<noscript[^>]*>.*?</noscript>",
            "(?is)<[^>]+>"
        ]
        
        for pattern in patterns {
            text = text.replacingOccurrences(of: pattern, with: " ", options: .regularExpression)
        }
        
        let entities: [String: String] = [
            "&nbsp;": " ",
            "&amp;": "&",
            "&lt;": "<",
            "&gt;": ">",
            "&quot;": "\"",
            "&#39;": "'"
        ]
        for (entity, value) in entities {
            text = text.replacingOccurrences(of: entity, with: value)
        }
        
        text = text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
