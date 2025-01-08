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
    
    init(content: String, sender: String) {
        self.content = content
        self.sender = sender
    }
}
