//
//  TranscriptItem.swift
//  GrokVoice
//
//  Transcript message model
//

import Foundation

struct TranscriptItem: Identifiable, Equatable {
    let id: String
    let role: TranscriptRole
    let text: String
    let timestamp: Date

    enum TranscriptRole: String, Codable {
        case user
        case assistant
    }

    init(id: String = UUID().uuidString, role: TranscriptRole, text: String, timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.text = text
        self.timestamp = timestamp
    }
}
