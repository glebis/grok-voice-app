//
//  MorphingBlobView.swift
//  GrokVoice
//
//  Morphing blob animation for voice states
//  Adapted from VoiceVisualizer experiments
//

import SwiftUI
import Noise

struct MorphingBlobView: View {
    let phase: VoicePhase
    var audioLevel: CGFloat = 0
    var size: CGFloat = 60

    // Noise generators for organic motion
    private let noise1 = GradientNoise2D(amplitude: 1.0, frequency: 1.0, seed: 42)
    private let noise2 = GradientNoise2D(amplitude: 1.0, frequency: 2.0, seed: 137)

    private let blobCount = 3
    private let pointCount = 16

    var body: some View {
        TimelineView(.animation(minimumInterval: 1/60)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate

            Canvas { context, canvasSize in
                let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
                let baseRadius = size / 2

                // Draw blobs from back to front
                for blobIndex in (0..<blobCount).reversed() {
                    let layerOffset = CGFloat(blobIndex) * 0.3
                    let radiusScale = 1.0 + CGFloat(blobIndex) * 0.12
                    let opacity = opacityForLayer(blobIndex: blobIndex, time: t)

                    let path = blobPath(
                        center: center,
                        time: t,
                        layerOffset: layerOffset,
                        radiusScale: radiusScale,
                        baseRadius: baseRadius,
                        blobIndex: blobIndex
                    )

                    let fillColor = colorForPhase()
                    context.fill(path, with: .color(fillColor.opacity(opacity * 0.25)))
                    context.stroke(path, with: .color(fillColor.opacity(opacity * 0.7)),
                                   lineWidth: blobIndex == 0 ? 1.5 : 0.8)
                }

                // Inner glow for active states
                if phase.isActive {
                    let glowSize = baseRadius * 0.4
                    let glowRect = CGRect(
                        x: center.x - glowSize,
                        y: center.y - glowSize,
                        width: glowSize * 2,
                        height: glowSize * 2
                    )
                    let glowPulse = 0.3 + CGFloat(sin(t * 3.0)) * 0.1
                    context.fill(
                        Circle().path(in: glowRect),
                        with: .color(colorForPhase().opacity(glowPulse))
                    )
                }
            }
        }
        .frame(width: size * 1.6, height: size * 1.6)  // Extra space for blob variations
    }

    // MARK: - Noise Helpers

    private func sampleNoise(x: CGFloat, y: CGFloat) -> CGFloat {
        CGFloat(noise1.evaluate(Double(x), Double(y)))
    }

    private func sampleNoise2(x: CGFloat, y: CGFloat) -> CGFloat {
        CGFloat(noise2.evaluate(Double(x), Double(y)))
    }

    // MARK: - Blob Path

    private func blobPath(
        center: CGPoint,
        time: Double,
        layerOffset: CGFloat,
        radiusScale: CGFloat,
        baseRadius: CGFloat,
        blobIndex: Int
    ) -> Path {
        let t = CGFloat(time)
        var points: [CGPoint] = []

        for i in 0..<pointCount {
            let baseAngle = (CGFloat(i) / CGFloat(pointCount)) * .pi * 2
            var radius = baseRadius * radiusScale

            // Perlin noise for organic motion
            let noiseX = cos(baseAngle) * 2 + t * 0.5 + layerOffset
            let noiseY = sin(baseAngle) * 2 + t * 0.3
            let perlinValue = sampleNoise(x: noiseX, y: noiseY)
            var radiusOffset: CGFloat = perlinValue * 4

            // State-specific behavior
            switch phase {
            case .idle:
                // Slow breathing
                let breathPhase = t * 0.4
                radiusOffset += sin(breathPhase) * 3 + sin(breathPhase * 0.6) * 2

            case .connecting:
                // Pulsing
                radiusOffset += sin(t * 4) * 5

            case .connected:
                // Gentle pulse
                radiusOffset += sin(t * 2) * 3

            case .listening:
                // Audio reactive
                radiusOffset += audioLevel * 15
                radiusOffset += sin(t * 3 + CGFloat(i) * 0.3) * audioLevel * 8

            case .processing:
                // Thinking waves
                let wave = sin(baseAngle * 2 + t * 2 + layerOffset) * 6
                radiusOffset += wave + sampleNoise(x: baseAngle + t * 0.3, y: layerOffset) * 5

            case .speaking:
                // Speaking pulse
                radiusOffset += sin(t * 6 + CGFloat(i) * 0.5) * 4
                radiusOffset += audioLevel * 10

            case .usingTool(let tool):
                radiusOffset += toolOffset(tool: tool, angle: baseAngle, index: i, time: t, layerOffset: layerOffset)

            case .error:
                // Jittery
                radiusOffset += sampleNoise(x: t * 5, y: CGFloat(i)) * 8
            }

            radius += radiusOffset

            let x = center.x + cos(baseAngle) * radius
            let y = center.y + sin(baseAngle) * radius
            points.append(CGPoint(x: x, y: y))
        }

        return smoothPath(through: points)
    }

    // MARK: - Tool-specific animations

    private func toolOffset(tool: ToolStyle, angle: CGFloat, index: Int, time: CGFloat, layerOffset: CGFloat) -> CGFloat {
        let i = CGFloat(index)

        switch tool {
        case .search:
            // Radar pulse
            let pulse = sin(time * 2) * 6
            let scan = (angle + time * 3).truncatingRemainder(dividingBy: .pi * 2) < 0.5 ? 5.0 : 0.0
            return pulse + scan

        case .code:
            // Glitchy
            let step = floor(sin(time * 6 + i * 0.8) * 3) * 4
            let glitch = Int(time * 10) % 7 == 0 ? 8.0 : 0.0
            return step + glitch

        case .file:
            // Grid-like
            let snappedAngle = floor(angle / (.pi / 4)) * (.pi / 4)
            return sin(snappedAngle * 4 + time * 3) * 6

        case .write:
            // Dripping
            let drip = angle > .pi * 0.3 && angle < .pi * 0.7 ? sin(time * 2 + i) * 8 : 0
            return drip + sin(angle) * 4

        case .api, .network:
            // Data flow
            let flow = sin(angle * 3 - time * 4) * 5
            return flow + abs(sin(time * 8 + i * 2)) * 4

        case .compute:
            // Spinning
            let spin = sin(angle + time * 6) * 6
            return spin + abs(sin(time * 10 + i)) * 5

        case .memory:
            // Bubbling up
            let bubble = abs(sin(time * 3 + i * 1.2)) * 6
            return bubble + sampleNoise(x: i + time * 0.5, y: angle) * 4

        case .vision:
            // Eye-like
            let horizontal = cos(angle) * cos(angle) * 8
            let vertical = sin(angle) * sin(angle) * -4
            return horizontal + vertical + sin(time * 4) * 3

        case .connecting:
            // Pulsing nodes
            let nodeCount: CGFloat = 5
            let nearestNode = round(angle / (.pi * 2) * nodeCount) / nodeCount * .pi * 2
            let distToNode = abs(angle - nearestNode)
            let nodeStrength = max(0, 1 - distToNode * 3) * 8
            return nodeStrength * (1 + sin(time * 4)) * 0.5

        case .analyzing:
            // Segmented
            let segmentCount: CGFloat = 6
            let segment = floor(angle / (.pi * 2) * segmentCount)
            let scanPulse = segment == floor((time * 0.5).truncatingRemainder(dividingBy: segmentCount)) ? 8.0 : 0.0
            return scanPulse + sin(time * 3 + segment) * 4

        case .researching:
            // Expanding
            let wave = sin((angle + time * 0.5).truncatingRemainder(dividingBy: .pi * 2) * 3) * 6
            return wave + (1 + sin(time * 1.5)) * 4

        case .synthesizing:
            // Contracting
            let contract = -3 - abs(sin(time * 2)) * 4
            return contract + sin(angle * 2 - time * 3) * 3

        case .summarizing:
            // Shrinking
            let shrinkPhase = (time * 0.3).truncatingRemainder(dividingBy: 1)
            return -6 - shrinkPhase * 8 + sin(angle * 3) * 3 * (1 - shrinkPhase * 0.5)
        }
    }

    // MARK: - Smooth Path

    private func smoothPath(through points: [CGPoint]) -> Path {
        var path = Path()
        guard points.count >= 3 else { return path }

        path.move(to: points[0])

        for i in 0..<points.count {
            let p0 = points[(i - 1 + points.count) % points.count]
            let p1 = points[i]
            let p2 = points[(i + 1) % points.count]
            let p3 = points[(i + 2) % points.count]

            let tension: CGFloat = 0.5

            let cp1 = CGPoint(
                x: p1.x + (p2.x - p0.x) / 6 * tension,
                y: p1.y + (p2.y - p0.y) / 6 * tension
            )

            let cp2 = CGPoint(
                x: p2.x - (p3.x - p1.x) / 6 * tension,
                y: p2.y - (p3.y - p1.y) / 6 * tension
            )

            path.addCurve(to: p2, control1: cp1, control2: cp2)
        }

        path.closeSubpath()
        return path
    }

    // MARK: - Colors & Opacity

    private func colorForPhase() -> Color {
        switch phase {
        case .idle: return .white
        case .connecting: return .cyan.opacity(0.7)
        case .connected: return .cyan
        case .listening: return .cyan
        case .processing: return .purple
        case .speaking: return .green
        case .usingTool(let tool): return tool.color
        case .error: return .red
        }
    }

    private func opacityForLayer(blobIndex: Int, time: Double) -> CGFloat {
        let t = CGFloat(time)
        let base: CGFloat = 0.8 - CGFloat(blobIndex) * 0.15

        switch phase {
        case .processing, .usingTool:
            return base + abs(sin(t * 4 + CGFloat(blobIndex))) * 0.15
        case .listening, .speaking:
            return base + audioLevel * 0.15
        default:
            return base
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 20) {
            MorphingBlobView(phase: .idle)
            MorphingBlobView(phase: .listening, audioLevel: 0.5)
            MorphingBlobView(phase: .processing)
        }
        HStack(spacing: 20) {
            MorphingBlobView(phase: .usingTool(.search))
            MorphingBlobView(phase: .usingTool(.code))
            MorphingBlobView(phase: .usingTool(.file))
        }
    }
    .padding()
    .background(Color.black)
}
