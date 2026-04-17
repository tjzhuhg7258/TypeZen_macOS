import Foundation

/// Google Gemini AI 服务
class GeminiService: AIServiceProtocol {
    var serviceName: String = "Google Gemini"
    private let model = "gemini-2.5-flash"
    
    var isConfigured: Bool {
        return KeychainManager.shared.load(for: "gemini_api_key") != nil
    }
    
    // 使用 Gemini 2.5 Flash 稳定版本
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"
    
    // MARK: - 生成打字练习文本
    func generatePracticeText(mode: String, difficulty: Int, count: Int, sourceMaterial: String?) async throws -> [String] {
        guard let apiKey = KeychainManager.shared.load(for: "gemini_api_key") else {
            throw AIServiceError.notConfigured
        }

        let prompt = buildPrompt(mode: mode, difficulty: difficulty, count: count, sourceMaterial: sourceMaterial)
        let response = try await callAPI(prompt: prompt, apiKey: apiKey)
        return parseResponse(response, mode: mode)
    }
    
    // MARK: - 生成自定义文本
    func generateCustomText(prompt: String) async throws -> String {
        guard let apiKey = KeychainManager.shared.load(for: "gemini_api_key") else {
            throw AIServiceError.notConfigured
        }
        
        let fullPrompt = "请生成适合中文打字练习的文本，主题：\(prompt)。要求：100-200字，使用常用汉字，句子通顺。直接输出文本内容，不要解释。"
        let response = try await callAPI(prompt: fullPrompt, apiKey: apiKey)
        
        return extractText(from: response)
    }
    
    // MARK: - Private Methods
    
    private func buildPrompt(mode: String, difficulty: Int, count: Int, sourceMaterial: String?) -> String {
        if let sourceMaterial, !sourceMaterial.isEmpty {
            return """
            你将收到一段网页内容。请先提炼核心信息，再生成适合中文打字练习的短文。
            
            要求：
            1. 仅基于给定内容总结，不要编造事实
            2. 生成约\(count)字中文短文（允许±20字）
            3. 语句通顺，适合打字练习
            4. 使用常见中文标点，不要输出标题、编号或解释
            5. 不要包含网址、HTML标签、英文代码片段
            
            网页内容：
            \(sourceMaterial)
            """
        }
        
        // 检查是否有自定义主题
        let customTopic = UserDefaults.standard.string(forKey: "practiceCustomTopic") ?? ""
        
        // 如果有自定义主题，使用它；否则随机选择
        let selectedTopic: String
        if !customTopic.isEmpty {
            selectedTopic = customTopic
        } else {
            // 不同难度对应的主题
            let topics = [
                1: ["日常生活", "学习工作", "健康饮食", "运动健身", "旅游出行"],
                2: ["科技发展", "环保节能", "人际交往", "时间管理", "文化艺术"],
                3: ["哲学思考", "社会现象", "历史文化", "科学探索", "未来展望"]
            ]
            let selectedTopics = topics[difficulty] ?? topics[2]!
            selectedTopic = selectedTopics.randomElement()!
        }
        
        // 根据字数确定段落数
        let paragraphCount = max(1, count / 100)
        
        let difficultyDesc = [
            1: "简单常用，适合初学者",
            2: "中等难度，词汇丰富",
            3: "较高难度，包含成语和专业词汇"
        ][difficulty] ?? "中等难度"
        
        return """
        请围绕主题"\(selectedTopic)"生成一篇约\(count)字的中文短文，用于打字练习。
        
        要求：
        1. 文章要有明确的主题和逻辑结构
        2. 分为\(paragraphCount)个自然段，段落间用空行分隔
        3. 使用标点符号（。，！？、：；""''）
        4. 难度级别：\(difficultyDesc)
        5. 语言流畅自然，适合朗读
        6. 不要包含特殊字符、英文、数字
        7. 直接输出文章内容，不要标题和解释
        
        字数控制在\(count-20)到\(count+20)字之间。
        """
    }
    
    private func callAPI(prompt: String, apiKey: String) async throws -> [String: Any] {
        guard let url = URL(string: baseURL) else {
            throw AIServiceError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        request.timeoutInterval = 30
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.7
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        do {
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
        } catch is URLError {
            throw AIServiceError.networkError
        } catch let error as AIServiceError {
            throw error
        } catch {
            throw AIServiceError.unknownError(error.localizedDescription)
        }
    }
    
    private func parseResponse(_ json: [String: Any], mode: String) -> [String] {
        let text = extractText(from: json)
        guard !text.isEmpty else {
            return []
        }
        
        // 返回完整文本作为单个元素（用于主题文章）
        let cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleanedText.isEmpty ? [] : [cleanedText]
    }
    
    private func extractText(from json: [String: Any]) -> String {
        guard let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]] else {
            return ""
        }

        return parts.compactMap { $0["text"] as? String }
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
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
            return .unknownError("Gemini 请求失败（HTTP \(statusCode)）")
        }

        return .unknownError("Gemini 请求失败（HTTP \(statusCode)）: \(message)")
    }
}
