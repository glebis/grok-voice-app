//
//  TranscriptItem.swift
//  GrokVoice
//
//  Transcript message model
//

import Foundation
import SwiftUI

struct TranscriptItem: Identifiable, Equatable {
    let id: String
    let role: TranscriptRole
    let text: String
    let timestamp: Date

    enum TranscriptRole: String, Codable {
        case user
        case assistant
        case toolStatus  // Claude Code tool status
    }

    init(id: String = UUID().uuidString, role: TranscriptRole, text: String, timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.text = text
        self.timestamp = timestamp
    }

    var color: Color {
        switch role {
        case .user: return .cyan
        case .assistant: return .white
        case .toolStatus: return .orange
        }
    }

    var icon: String? {
        switch role {
        case .user: return "person.fill"
        case .assistant: return "sparkles"
        case .toolStatus: return "hammer.fill"
        }
    }

    var font: Font {
        switch role {
        case .user:
            // EB Garamond for user - falls back to system serif if not installed
            return .custom("EBGaramond-Regular", size: 13, relativeTo: .body)
        case .assistant:
            // Monospace for agent
            return .system(size: 12, design: .monospaced)
        case .toolStatus:
            return .system(size: 11, weight: .medium)
        }
    }
}

/// Claude Code tool status for real-time display
struct ToolStatus: Equatable {
    let toolName: String
    let input: String
    let timestamp: Date

    init(toolName: String, input: String = "", timestamp: Date = Date()) {
        self.toolName = toolName
        self.input = input
        self.timestamp = timestamp
    }

    var displayText: String {
        if input.isEmpty {
            return toolName
        }
        let truncated = input.prefix(40)
        return "\(toolName): \(truncated)\(input.count > 40 ? "..." : "")"
    }
}
