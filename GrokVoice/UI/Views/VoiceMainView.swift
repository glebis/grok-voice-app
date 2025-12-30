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
        VStack(spacing: 16) {
            // Status display
            VoiceStatusView(phase: viewModel.phase)

            // Current transcript (live)
            if !viewModel.currentUtterance.isEmpty {
                Text(viewModel.currentUtterance)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .lineLimit(3)
                    .transition(.opacity)
            }

            // Waveform visualization
            WaveformView(
                isListening: viewModel.phase == .listening,
                isSpeaking: viewModel.phase == .speaking
            )
            .frame(height: 60)

            // Main action button
            VoiceActionButton(
                phase: viewModel.phase,
                onConnect: { Task { await viewModel.connect() } },
                onDisconnect: { Task { await viewModel.disconnect() } },
                onStartListening: { viewModel.startListening() },
                onStopListening: { viewModel.stopListening() }
            )

            // View transcript button
            if !viewModel.transcriptItems.isEmpty {
                Button {
                    viewModel.showTranscript()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "text.bubble")
                        Text("View Transcript (\(viewModel.transcriptItems.count))")
                    }
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 16)
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
        case .connected, .listening, .processing, .speaking:
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
        case .error: return "exclamationmark.triangle"
        }
    }

    private func handleTap() {
        switch phase {
        case .idle, .error:
            onConnect()
        case .connected, .listening, .processing, .speaking:
            // In conversation - tap to disconnect
            onDisconnect()
        default:
            break
        }
    }
}
