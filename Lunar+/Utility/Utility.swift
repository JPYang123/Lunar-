//  UTILITIES.swift
//  Lunar+
//
//  Created by Jiping Yang on 11/23/25.
//

import SwiftUI
// import Foundation // Explicit import to ensure Calendar refers to Foundation.Calendar where needed

// MARK: - GEMINI API UTILITIES
let apiKey = ""

struct GeminiResponse: Codable {
    struct Candidate: Codable {
        struct Content: Codable {
            struct Part: Codable { let text: String }
            let parts: [Part]
        }
        let content: Content
    }
    let candidates: [Candidate]?
}

func callGemini(prompt: String) async -> String {
    guard !apiKey.isEmpty else { return "Please add your Gemini API Key in the code to receive fortunes." }
    
    let urlString = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-09-2025:generateContent?key=\(apiKey)"
    guard let url = URL(string: urlString) else { return "Invalid URL" }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let json: [String: Any] = [
        "contents": [
            ["parts": [["text": prompt]]]
        ]
    ]
    
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: json)
        let (data, _) = try await URLSession.shared.data(for: request)
        let decoded = try JSONDecoder().decode(GeminiResponse.self, from: data)
        return decoded.candidates?.first?.content.parts.first?.text ?? "The stars are silent."
    } catch {
        print("Gemini Error: \(error)")
        return "The lunar mists obscure the future currently. (Network Error)"
    }
}
