import Foundation

/// OpenAI GPT 服务
class OpenAIService: AIServiceProtocol {
    var serviceName: String = "OpenAI GPT"
    
    var isConfigured: Bool {
        return KeychainManager.shared.load(for: "openai_api_key") != nil
    }
    
    private let baseURL = "https://api.openai.com/v1/responses"
    private let model = "gpt-4o-mini"
    
    // MARK: - 生成打字练习文本
    func generatePracticeText(mode: String, difficulty: Int, count: Int, topic: String?, sourceMaterial: String?) async throws -> [String] {
        guard let apiKey = KeychainManager.shared.load(for: "openai_api_key") else {
            throw AIServiceError.notConfigured
        }
        
        let prompt = buildPrompt(mode: mode, difficulty: difficulty, count: count, topic: topic, sourceMaterial: sourceMaterial)
        let response = try await callAPI(prompt: prompt, apiKey: apiKey)
        
        return parseResponse(response, mode: mode)
    }
    
    // MARK: - 生成自定义文本
    func generateCustomText(prompt: String) async throws -> String {
        guard let apiKey = KeychainManager.shared.load(for: "openai_api_key") else {
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
            请基于以下网页内容进行总结，生成适合中文打字练习的短文。
            要求：约\(count)字，语句流畅，仅输出正文，不要标题或解释。
            
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
            return "请生成一篇约\(count)字的中文打字练习短文。\(topicClause)难度级别 \(difficulty)/5。要求：语句流畅自然，使用常用汉字和标点，直接输出正文，不要标题和解释。"
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
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let requestBody: [String: Any] = [
            "model": model,
            "input": prompt,
            "temperature": 0.7
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
        let content = extractText(from: json)
        guard !content.isEmpty else {
            return []
        }
        
        // 根据模式解析文本
        if mode == "sentences" {
            return content.components(separatedBy: .newlines)
                .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        } else if mode == "article" || mode == "articles" {
            return [content]
        } else {
            return content.components(separatedBy: .whitespaces)
                .filter { !$0.isEmpty }
        }
    }
    
    private func extractText(from json: [String: Any]) -> String {
        if let outputText = json["output_text"] as? String {
            return outputText.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        guard let output = json["output"] as? [[String: Any]] else {
            return ""
        }
        
        let texts = output.compactMap { item -> String? in
            guard let content = item["content"] as? [[String: Any]] else {
                return nil
            }
            
            let parts = content.compactMap { part -> String? in
                guard let type = part["type"] as? String, type == "output_text" else {
                    return nil
                }
                return part["text"] as? String
            }
            
            let joined = parts.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            return joined.isEmpty ? nil : joined
        }
        
        return texts.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
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
            return .unknownError("OpenAI 请求失败（HTTP \(statusCode)）")
        }
        
        return .unknownError("OpenAI 请求失败（HTTP \(statusCode)）: \(message)")
    }
}
