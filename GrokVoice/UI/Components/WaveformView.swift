//
//  WaveformView.swift
//  GrokVoice
//
//  Audio visualization waveform
//

import SwiftUI

struct WaveformView: View {
    let isListening: Bool
    let isSpeaking: Bool

    @State private var animationPhase: CGFloat = 0

    private var isActive: Bool { isListening || isSpeaking }

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 3) {
                ForEach(0..<20, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(barColor)
                        .frame(width: 4, height: barHeight(for: index, in: geometry.size.height))
                        .animation(
                            isActive ? .easeInOut(duration: 0.15) : .easeOut(duration: 0.3),
                            value: animationPhase
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            startAnimation()
        }
        .onChange(of: isActive) { _, _ in
            startAnimation()
        }
    }

    private var barColor: Color {
        if isListening {
            return .blue.opacity(0.7)
        } else if isSpeaking {
            return .purple.opacity(0.7)
        } else {
            return .gray.opacity(0.3)
        }
    }

    private func barHeight(for index: Int, in maxHeight: CGFloat) -> CGFloat {
        guard isActive else { return 4 }

        let baseHeight: CGFloat = 8
        let variation = sin(CGFloat(index) * 0.5 + animationPhase) * 0.5 + 0.5
        return baseHeight + (maxHeight - baseHeight) * variation * 0.8
    }

    private func startAnimation() {
        guard isActive else { return }

        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if !isActive {
                timer.invalidate()
                return
            }
            animationPhase += 0.3
        }
    }
}
