//
//  ActivationContext.swift
//  GrokVoice
//
//  Context passed via URL scheme for voice activation
//

import Foundation

/// Context provided when activating via URL scheme
struct ActivationContext {
    /// Claude Code session ID to continue
    var sessionId: String?

    /// URL to discuss/analyze
    var url: URL?

    /// Text content to discuss
    var text: String?

    /// File path to discuss
    var filePath: String?

    /// Raw query parameters for extensibility
    var rawParams: [String: String] = [:]

    var isEmpty: Bool {
        sessionId == nil && url == nil && text == nil && filePath == nil
    }

    /// Parse from URL query parameters
    static func from(url: URL) -> ActivationContext {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return ActivationContext()
        }

        var context = ActivationContext()

        for item in components.queryItems ?? [] {
            guard let value = item.value, !value.isEmpty else { continue }

            context.rawParams[item.name] = value

            switch item.name {
            case "session", "session_id":
                context.sessionId = value
            case "url", "link":
                context.url = URL(string: value)
            case "text", "content":
                context.text = value
            case "file", "path":
                context.filePath = value
            default:
                break
            }
        }

        return context
    }

    /// Format as system message for the agent
    func toSystemPrompt() -> String? {
        var parts: [String] = []

        if let sessionId = sessionId {
            parts.append("Continue Claude Code session: \(sessionId)")
        }

        if let url = url {
            parts.append("Discuss this URL: \(url.absoluteString)")
        }

        if let text = text {
            parts.append("Context: \(text)")
        }

        if let filePath = filePath {
            parts.append("Discuss file: \(filePath)")
        }

        return parts.isEmpty ? nil : parts.joined(separator: "\n")
    }
}
