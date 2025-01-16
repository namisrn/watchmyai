//
//  Chat.swift
//  WatchAI
//
//  Created by Rafat Nami, Sasan on 08.01.25.
//

import Foundation
import SwiftData

@Model
class Chat: Identifiable {
    var content: String
    var sender: String
    var createdAt: Date  
    
    init(content: String, sender: String, createdAt: Date = Date()) {
        self.content = content
        self.sender = sender
        self.createdAt = createdAt
    }
}
