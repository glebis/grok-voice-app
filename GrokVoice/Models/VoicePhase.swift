//
//  VoicePhase.swift
//  GrokVoice
//
//  Voice interaction state machine
//

import Foundation
import SwiftUI

enum VoicePhase: Equatable {
    case idle
    case connecting
    case connected
    case listening
    case processing
    case speaking
    case usingTool(ToolStyle)
    case error(String)

    var isActive: Bool {
        switch self {
        case .listening, .processing, .speaking, .usingTool:
            return true
        default:
            return false
        }
    }

    var statusText: String {
        switch self {
        case .idle: return "Tap to start"
        case .connecting: return "Connecting..."
        case .connected: return "Connected"
        case .listening: return "Listening..."
        case .processing: return "Thinking..."
        case .speaking: return "Speaking..."
        case .usingTool(let tool): return tool.statusText
        case .error(let msg): return "Error: \(msg)"
        }
    }
}

// Tool styles for visualizer animations
enum ToolStyle: String, CaseIterable, Equatable {
    case search = "search"
    case code = "code"
    case api = "api"
    case file = "file"
    case compute = "compute"
    case memory = "memory"
    case network = "network"
    case vision = "vision"
    case write = "write"
    case connecting = "connecting"
    case analyzing = "analyzing"
    case researching = "researching"
    case synthesizing = "synthesizing"
    case summarizing = "summarizing"

    var displayName: String {
        switch self {
        case .search: return "Search"
        case .code: return "Code"
        case .api: return "API"
        case .file: return "File"
        case .compute: return "Compute"
        case .memory: return "Memory"
        case .network: return "Network"
        case .vision: return "Vision"
        case .write: return "Write"
        case .connecting: return "Connect"
        case .analyzing: return "Analyze"
        case .researching: return "Research"
        case .synthesizing: return "Synth"
        case .summarizing: return "Summary"
        }
    }

    var statusText: String {
        switch self {
        case .search: return "Searching..."
        case .code: return "Writing code..."
        case .api: return "Calling API..."
        case .file: return "Reading files..."
        case .compute: return "Computing..."
        case .memory: return "Remembering..."
        case .network: return "Connecting..."
        case .vision: return "Analyzing..."
        case .write: return "Writing..."
        case .connecting: return "Connecting..."
        case .analyzing: return "Analyzing..."
        case .researching: return "Researching..."
        case .synthesizing: return "Synthesizing..."
        case .summarizing: return "Summarizing..."
        }
    }

    var color: Color {
        switch self {
        case .search: return .orange
        case .code: return .green
        case .api: return Color(hue: 0.08, saturation: 0.9, brightness: 1)
        case .file: return .yellow
        case .compute: return Color(hue: 0.05, saturation: 1, brightness: 1)
        case .memory: return .blue
        case .network: return .cyan
        case .vision: return .red
        case .write: return Color(hue: 0.12, saturation: 0.8, brightness: 1)
        case .connecting: return .mint
        case .analyzing: return .teal
        case .researching: return .indigo
        case .synthesizing: return .pink
        case .summarizing: return .orange
        }
    }

    /// Map from Claude Code tool names to ToolStyle
    static func from(toolName: String) -> ToolStyle {
        let name = toolName.lowercased()
        if name.contains("search") || name.contains("grep") || name.contains("glob") {
            return .search
        } else if name.contains("read") || name.contains("file") {
            return .file
        } else if name.contains("write") || name.contains("edit") {
            return .write
        } else if name.contains("bash") || name.contains("code") {
            return .code
        } else if name.contains("web") || name.contains("fetch") || name.contains("api") {
            return .api
        } else if name.contains("task") || name.contains("agent") {
            return .researching
        } else {
            return .compute
        }
    }
}

enum NotchStatus: Equatable {
    case closed
    case opened
    case popping
}

enum VoiceContentType: Equatable {
    case main
    case settings
    case transcript
}

enum GrokVoice: String, CaseIterable, Codable {
    // Classic voices
    case sal = "Sal"
    case rex = "Rex"
    case eve = "Eve"
    case leo = "Leo"
    // Expressive voice
    case ara = "Ara"
    // Companion personas
    case mika = "Mika"
    case valentin = "Valentin"

    var displayName: String { rawValue }
}
