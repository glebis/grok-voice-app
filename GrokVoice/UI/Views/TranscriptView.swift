//
//  TranscriptView.swift
//  GrokVoice
//
//  Conversation transcript display
//

import SwiftUI

struct TranscriptView: View {
    @ObservedObject var viewModel: VoiceViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button {
                    viewModel.contentType = .main
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 10, weight: .medium))
                        Text("Back")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.6))
                }
                .buttonStyle(.plain)

                Spacer()

                Text("Transcript")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))

                Spacer()

                Button {
                    viewModel.clearTranscript()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            Divider()
                .background(Color.white.opacity(0.1))

            // Transcript list
            if viewModel.transcriptItems.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "text.bubble")
                        .font(.system(size: 32))
                        .foregroundColor(.white.opacity(0.2))

                    Text("No conversation yet")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(viewModel.transcriptItems) { item in
                                TranscriptItemView(item: item)
                                    .id(item.id)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    }
                    .onChange(of: viewModel.transcriptItems.count) { _, _ in
                        if let lastItem = viewModel.transcriptItems.last {
                            withAnimation {
                                proxy.scrollTo(lastItem.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct TranscriptItemView: View {
    let item: TranscriptItem

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Avatar
            Circle()
                .fill(item.role == .user ? Color.blue : Color.purple)
                .frame(width: 24, height: 24)
                .overlay(
                    Image(systemName: item.role == .user ? "person.fill" : "waveform")
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                // Role and time
                HStack {
                    Text(item.role == .user ? "You" : "Assistant")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))

                    Text(timeString(from: item.timestamp))
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.3))
                }

                // Message
                Text(item.text)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.9))
                    .textSelection(.enabled)
            }

            Spacer()
        }
        .padding(.vertical, 6)
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
