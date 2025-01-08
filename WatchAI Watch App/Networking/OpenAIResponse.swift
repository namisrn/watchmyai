//
//  OpenAIResponse.swift
//  WatchAI Watch App
//
//  Created by Rafat Nami, Sasan on 08.01.25.
//

import Foundation

// MARK: - OpenAIResponse Model
struct OpenAIResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}
