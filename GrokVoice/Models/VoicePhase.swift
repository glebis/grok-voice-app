//
//  VoicePhase.swift
//  GrokVoice
//
//  Voice interaction state machine
//

import Foundation

enum VoicePhase: Equatable {
    case idle
    case connecting
    case connected
    case listening
    case processing
    case speaking
    case error(String)

    var isActive: Bool {
        switch self {
        case .listening, .processing, .speaking:
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
        case .error(let msg): return "Error: \(msg)"
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
    case ara = "Ara"
    case eve = "Eve"
    case leo = "Leo"

    var displayName: String { rawValue }
}
