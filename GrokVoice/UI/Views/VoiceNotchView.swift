//
//  VoiceNotchView.swift
//  GrokVoice
//
//  Main voice UI in notch style
//

import SwiftUI

struct VoiceNotchView: View {
    @ObservedObject var viewModel: VoiceViewModel
    @State private var isVisible: Bool = false

    private var expansionWidth: CGFloat {
        switch viewModel.phase {
        case .listening, .speaking:
            return 40
        case .processing:
            return 20
        default:
            return 0
        }
    }

    private var currentWidth: CGFloat {
        if viewModel.status == .opened {
            return viewModel.openedSize.width
        } else {
            return viewModel.closedNotchSize.width + expansionWidth
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                notchLayout
                    .frame(width: currentWidth)
                    .padding(.horizontal, viewModel.status == .opened ? 12 : 0)
                    .padding([.horizontal, .bottom], viewModel.status == .opened ? 12 : 0)
                    .background(.black)
                    .clipShape(currentNotchShape)
                    .shadow(color: viewModel.status == .opened ? .black.opacity(0.7) : .clear, radius: 6)
                    .animation(.spring(response: 0.42, dampingFraction: 0.8), value: viewModel.status)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.phase)
                    .contentShape(Rectangle())
            }
        }
        .opacity(isVisible ? 1 : 0)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .preferredColorScheme(.dark)
        .onAppear {
            isVisible = true
        }
    }

    @ViewBuilder
    private var notchLayout: some View {
        VStack(alignment: .center, spacing: 0) {
            headerRow
                .frame(height: max(24, viewModel.closedNotchSize.height))

            if viewModel.status == .opened {
                contentView
                    .frame(width: viewModel.openedSize.width - 24)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8, anchor: .top).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
    }

    @ViewBuilder
    private var headerRow: some View {
        HStack(spacing: 8) {
            if viewModel.phase.isActive {
                VoiceActivityIndicator(phase: viewModel.phase)
                    .frame(width: 24, height: 24)
            }

            Spacer()

            if viewModel.status == .opened {
                Button {
                    viewModel.toggleSettings()
                } label: {
                    Image(systemName: viewModel.contentType == .settings ? "xmark" : "gear")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                }
                .buttonStyle(.plain)
            }

            if viewModel.phase.isActive {
                WaveformMini(isActive: viewModel.phase == .speaking || viewModel.phase == .listening)
                    .frame(width: 24, height: 24)
            }
        }
        .padding(.horizontal, 8)
        .frame(height: viewModel.closedNotchSize.height)
    }

    @ViewBuilder
    private var contentView: some View {
        switch viewModel.contentType {
        case .main:
            VoiceMainView(viewModel: viewModel)
        case .settings:
            VoiceSettingsView(viewModel: viewModel)
        case .transcript:
            TranscriptView(viewModel: viewModel)
        }
    }

    private var currentNotchShape: NotchShape {
        NotchShape(
            topCornerRadius: viewModel.status == .opened ? 19 : 6,
            bottomCornerRadius: viewModel.status == .opened ? 24 : 14
        )
    }
}

struct VoiceActivityIndicator: View {
    let phase: VoicePhase

    var body: some View {
        Circle()
            .fill(indicatorColor)
            .frame(width: 8, height: 8)
            .shadow(color: indicatorColor.opacity(0.5), radius: 4)
    }

    private var indicatorColor: Color {
        switch phase {
        case .listening: return .blue
        case .processing: return .orange
        case .speaking: return .purple
        default: return .gray
        }
    }
}

struct WaveformMini: View {
    let isActive: Bool
    @State private var animating = false

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 2, height: isActive ? (animating ? heights[index] : 4) : 4)
                    .animation(
                        isActive ? .easeInOut(duration: 0.3).repeatForever().delay(Double(index) * 0.1) : .default,
                        value: animating
                    )
            }
        }
        .onAppear {
            if isActive { animating = true }
        }
        .onChange(of: isActive) { _, newValue in
            animating = newValue
        }
    }

    private let heights: [CGFloat] = [8, 12, 6]
}
