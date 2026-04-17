import Foundation

/// Anthropic Claude AI 服务
class ClaudeService: AIServiceProtocol {
    var serviceName: String = "Anthropic Claude"
    private let model = "claude-3-5-haiku-latest"
    
    var isConfigured: Bool {
        return KeychainManager.shared.load(for: "claude_api_key") != nil
    }
    
    private let baseURL = "https://api.anthropic.com/v1/messages"
    
    // MARK: - 生成打字练习文本
    func generatePracticeText(mode: String, difficulty: Int, count: Int, topic: String?, sourceMaterial: String?) async throws -> [String] {
        guard let apiKey = KeychainManager.shared.load(for: "claude_api_key") else {
            throw AIServiceError.notConfigured
        }
        
        let prompt = buildPrompt(mode: mode, difficulty: difficulty, count: count, topic: topic, sourceMaterial: sourceMaterial)
        let response = try await callAPI(prompt: prompt, apiKey: apiKey)
        
        return parseResponse(response, mode: mode)
    }
    
    // MARK: - 生成自定义文本
    func generateCustomText(prompt: String) async throws -> String {
        guard let apiKey = KeychainManager.shared.load(for: "claude_api_key") else {
            throw AIServiceError.notConfigured
        }
        
        let fullPrompt = "请生成适合中文打字练习的文本，主题：\(prompt)。要求：100-200字，使用常用汉字，句子通顺。直接输出文本内容，不要解释。"
        let response = try await callAPI(prompt: fullPrompt, apiKey: apiKey)
        
        return extractText(from: response)
    }
    
    // MARK: - Private Methods
    
    private func buildPrompt(mode: String, difficulty: Int, count: Int, topic: String?, sourceMaterial: String?) -> String {
        if let sourceMaterial, !sourceMaterial.isEmpty {
            return """
            你将获得网页正文，请提炼核心内容并生成中文打字练习短文。
            要求：约\(count)字、逻辑清晰、语句自然、仅输出正文。
            
            网页内容：
            \(sourceMaterial)
            """
        }

        let trimmedTopic = topic?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let topicClause = trimmedTopic.isEmpty ? "" : "主题围绕\(trimmedTopic)。"
        
        switch mode {
        case "words":
            return "请生成 \(count) 个适合中文打字练习的常用词汇，难度级别 \(difficulty)/5。词汇要求：2-4字，使用常用汉字。直接输出词汇列表，用空格分隔，不要编号和解释。"
        case "idioms":
            return "请生成 \(count) 个常用的四字成语，难度级别 \(difficulty)/5。直接输出成语列表，用空格分隔，不要编号和解释。"
        case "sentences":
            return "请生成 \(count) 条适合打字练习的中文句子，难度级别 \(difficulty)/5。要求：每句10-30字，使用常用汉字，内容积极向上。直接输出句子，每句一行。"
        case "article", "articles":
            return "请生成一篇约\(count)字的中文打字练习短文。\(topicClause)难度级别 \(difficulty)/5。要求：语言自然、结构完整、使用常用汉字与标点，仅输出正文。"
        default:
            return "请生成适合中文打字练习的文本内容"
        }
    }
    
    private func callAPI(prompt: String, apiKey: String) async throws -> [String: Any] {
        guard let url = URL(string: baseURL) else {
            throw AIServiceError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.timeoutInterval = 30
        
        let requestBody: [String: Any] = [
            "model": model,
            "max_tokens": 1024,
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.networkError
        }
        
        if httpResponse.statusCode == 429 {
            throw AIServiceError.rateLimitExceeded
        }
        
        guard httpResponse.statusCode == 200 else {
            throw mapErrorResponse(data: data, statusCode: httpResponse.statusCode)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AIServiceError.invalidResponse
        }
        
        return json
    }
    
    private func parseResponse(_ json: [String: Any], mode: String) -> [String] {
        let text = extractText(from: json)
        guard !text.isEmpty else {
            return []
        }
        
        // 根据模式解析文本
        if mode == "sentences" {
            return text.components(separatedBy: .newlines)
                .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        } else if mode == "article" || mode == "articles" {
            return [text]
        } else {
            return text.components(separatedBy: .whitespaces)
                .filter { !$0.isEmpty }
        }
    }
    
    private func extractText(from json: [String: Any]) -> String {
        guard let content = json["content"] as? [[String: Any]] else {
            return ""
        }

        let text = content.compactMap { block -> String? in
            guard let type = block["type"] as? String, type == "text" else {
                return nil
            }
            return block["text"] as? String
        }
        .joined(separator: "\n")
        .trimmingCharacters(in: .whitespacesAndNewlines)

        return text
    }

    private func mapErrorResponse(data: Data, statusCode: Int) -> AIServiceError {
        if statusCode == 401 || statusCode == 403 {
            return .invalidAPIKey
        }

        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let error = json["error"] as? [String: Any],
            let message = error["message"] as? String
        else {
            return .unknownError("Anthropic 请求失败（HTTP \(statusCode)）")
        }

        return .unknownError("Anthropic 请求失败（HTTP \(statusCode)）: \(message)")
    }
}
