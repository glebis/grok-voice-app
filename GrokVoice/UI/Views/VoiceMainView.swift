//
//  VoiceMainView.swift
//  GrokVoice
//
//  Main voice control view with action button and status
//

import SwiftUI

struct VoiceMainView: View {
    @ObservedObject var viewModel: VoiceViewModel

    var body: some View {
        ZStack {
            // Tappable morphing blob - tap to connect/disconnect
            GeometryReader { geo in
                let blobSize = min(geo.size.width, geo.size.height) * 0.3
                MorphingBlobView(
                    phase: viewModel.phase,
                    audioLevel: viewModel.audioLevel,
                    size: blobSize
                )
                .frame(width: geo.size.width, height: geo.size.height)
                .contentShape(Circle().scale(1.2))
                .onTapGesture {
                    handleBlobTap()
                }
            }

            // Content overlay (non-interactive except specific elements)
            VStack(spacing: 12) {
                // Status + tool status row
                HStack {
                    VoiceStatusView(phase: viewModel.phase)
                    Spacer()
                    if let toolStatus = viewModel.currentToolStatus {
                        ToolStatusBadge(status: toolStatus)
                    }
                }
                .padding(.horizontal, 16)

                Spacer()

                // Live transcript area
                LiveTranscriptView(
                    items: viewModel.transcriptItems.suffix(3),
                    currentUtterance: viewModel.currentUtterance,
                    isUserSpeaking: viewModel.phase == .listening
                )
                .frame(height: 80)
                .allowsHitTesting(false)

                Spacer()

                // View transcript button
                if !viewModel.transcriptItems.isEmpty {
                    Button {
                        viewModel.showTranscript()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "text.bubble")
                            Text("Transcript (\(viewModel.transcriptItems.count))")
                        }
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 12)
        }
    }

    private func handleBlobTap() {
        switch viewModel.phase {
        case .idle, .error:
            Task { await viewModel.connect() }
        case .connected, .listening, .processing, .speaking, .usingTool:
            Task { await viewModel.disconnect() }
        case .connecting:
            break  // Don't interrupt connecting
        }
    }
}

/// Compact live transcript showing recent messages
struct LiveTranscriptView: View {
    let items: ArraySlice<TranscriptItem>
    let currentUtterance: String
    let isUserSpeaking: Bool

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(items)) { item in
                    TranscriptRow(item: item)
                }

                // Current utterance (typing indicator)
                if !currentUtterance.isEmpty {
                    TranscriptRow(
                        item: TranscriptItem(
                            role: isUserSpeaking ? .user : .assistant,
                            text: currentUtterance
                        ),
                        isLive: true
                    )
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

/// Single transcript row with icon and colored text
struct TranscriptRow: View {
    let item: TranscriptItem
    var isLive: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            if let icon = item.icon {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(item.color.opacity(0.7))
                    .frame(width: 14)
            }

            Text(item.text)
                .font(item.font)
                .foregroundColor(item.color.opacity(isLive ? 0.6 : 0.9))
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            if isLive {
                Circle()
                    .fill(item.color)
                    .frame(width: 4, height: 4)
                    .opacity(0.8)
            }
        }
    }
}

/// Tool status badge showing current Claude Code operation
struct ToolStatusBadge: View {
    let status: ToolStatus

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "hammer.fill")
                .font(.system(size: 9))
            Text(status.toolName)
                .font(.system(size: 10, weight: .medium))
        }
        .foregroundColor(.orange)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Color.orange.opacity(0.15))
        .cornerRadius(8)
    }
}

struct VoiceStatusView: View {
    let phase: VoicePhase

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            Text(phase.statusText)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
    }

    private var statusColor: Color {
        switch phase {
        case .idle, .error: return .gray
        case .connecting: return .orange
        case .connected: return .green
        case .listening: return .blue
        case .processing: return .orange
        case .speaking: return .purple
        case .usingTool(let tool): return tool.color
        }
    }
}

struct VoiceActionButton: View {
    let phase: VoicePhase
    let onConnect: () -> Void
    let onDisconnect: () -> Void
    let onStartListening: () -> Void
    let onStopListening: () -> Void

    @State private var isPressed = false

    private var isInConversation: Bool {
        switch phase {
        case .connected, .listening, .processing, .speaking, .usingTool:
            return true
        default:
            return false
        }
    }

    var body: some View {
        Button {
            handleTap()
        } label: {
            Circle()
                .fill(buttonColor)
                .frame(width: 64, height: 64)
                .overlay(
                    Group {
                        if phase == .connecting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: buttonIcon)
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                )
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .disabled(phase == .connecting)
    }

    private var buttonColor: Color {
        switch phase {
        case .idle: return .blue
        case .connecting: return .orange
        case .connected, .listening: return .green
        case .processing: return .orange
        case .speaking: return .purple
        case .usingTool(let tool): return tool.color
        case .error: return .gray
        }
    }

    private var buttonIcon: String {
        switch phase {
        case .idle: return "phone.fill"
        case .connecting: return "ellipsis"
        case .connected, .listening: return "phone.down.fill"
        case .processing: return "phone.down.fill"
        case .speaking: return "phone.down.fill"
        case .usingTool: return "phone.down.fill"
        case .error: return "exclamationmark.triangle"
        }
    }

    private func handleTap() {
        switch phase {
        case .idle, .error:
            onConnect()
        case .connected, .listening, .processing, .speaking, .usingTool:
            // In conversation - tap to disconnect
            onDisconnect()
        default:
            break
        }
    }
}
