//
//  VoiceViewModel.swift
//  GrokVoice
//
//  Main state machine for voice interaction
//

import SwiftUI
import Combine
import AppKit
import LiveKit

@MainActor
class VoiceViewModel: ObservableObject {
    // MARK: - Published State
    @Published var phase: VoicePhase = .idle
    @Published var status: NotchStatus = .closed
    @Published var contentType: VoiceContentType = .main
    @Published var isHovering: Bool = false

    // MARK: - Transcript
    @Published var transcriptItems: [TranscriptItem] = []
    @Published var currentUtterance: String = ""

    // MARK: - Claude Code Status
    @Published var currentToolStatus: ToolStatus?

    // MARK: - Audio Level (for visualizer)
    @Published var audioLevel: CGFloat = 0

    // MARK: - Activation Context (from URL scheme)
    @Published var activationContext: ActivationContext?

    // MARK: - Geometry
    let geometry: NotchGeometry
    let hasPhysicalNotch: Bool

    // MARK: - Dependencies
    private let liveKitService: LiveKitService
    private var cancellables = Set<AnyCancellable>()
    private var globalMouseMonitor: Any?
    private var localMouseMonitor: Any?

    var openedSize: CGSize {
        switch contentType {
        case .main:
            return CGSize(width: 400, height: 340)
        case .settings:
            return CGSize(width: 400, height: 400)
        case .transcript:
            return CGSize(width: 480, height: 500)
        }
    }

    var closedNotchSize: CGSize {
        CGSize(
            width: geometry.deviceNotchRect.width,
            height: geometry.deviceNotchRect.height
        )
    }

    init(deviceNotchRect: CGRect, screenRect: CGRect, windowHeight: CGFloat, hasPhysicalNotch: Bool) {
        self.geometry = NotchGeometry(
            deviceNotchRect: deviceNotchRect,
            screenRect: screenRect,
            windowHeight: windowHeight
        )
        self.hasPhysicalNotch = hasPhysicalNotch
        self.liveKitService = LiveKitService.shared

        setupBindings()
        setupMouseMonitors()
    }

    deinit {
        if let monitor = globalMouseMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = localMouseMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    // MARK: - Setup

    private func setupBindings() {
        liveKitService.$connectionState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleConnectionStateChange(state)
            }
            .store(in: &cancellables)

        liveKitService.$currentTranscript
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentUtterance)

        liveKitService.$transcriptHistory
            .receive(on: DispatchQueue.main)
            .assign(to: &$transcriptItems)

        liveKitService.$isSpeaking
            .receive(on: DispatchQueue.main)
            .sink { [weak self] speaking in
                if speaking {
                    self?.phase = .speaking
                } else if self?.phase == .speaking {
                    self?.phase = .connected
                }
            }
            .store(in: &cancellables)

        liveKitService.$currentToolStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] toolStatus in
                guard let self = self else { return }
                self.currentToolStatus = toolStatus
                if let status = toolStatus {
                    // Map tool name to ToolStyle and update phase
                    let toolStyle = ToolStyle.from(toolName: status.toolName)
                    self.phase = .usingTool(toolStyle)
                } else if case .usingTool = self.phase {
                    // Tool done - return to processing/connected
                    self.phase = .processing
                }
            }
            .store(in: &cancellables)

        // Audio level - use local when listening, remote when speaking
        Publishers.CombineLatest3(
            liveKitService.$localAudioLevel,
            liveKitService.$remoteAudioLevel,
            $phase
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] local, remote, phase in
            guard let self = self else { return }
            switch phase {
            case .listening:
                self.audioLevel = CGFloat(local)
            case .speaking:
                self.audioLevel = CGFloat(remote)
            default:
                self.audioLevel = max(CGFloat(local), CGFloat(remote))
            }
        }
        .store(in: &cancellables)
    }

    private func handleConnectionStateChange(_ state: LiveKit.ConnectionState) {
        print("[VoiceVM] Connection state changed to: \(state), current phase: \(phase)")
        switch state {
        case .disconnected:
            print("[VoiceVM] Disconnected - setting phase to idle")
            phase = .idle
        case .connecting:
            phase = .connecting
        case .reconnecting:
            phase = .connecting
        case .connected:
            if phase == .connecting {
                phase = .connected
            }
        @unknown default:
            break
        }
    }

    private func setupMouseMonitors() {
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .leftMouseDown]) { [weak self] event in
            Task { @MainActor in
                self?.handleMouseEvent(event)
            }
        }

        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved, .leftMouseDown]) { [weak self] event in
            Task { @MainActor in
                self?.handleMouseEvent(event)
            }
            return event
        }
    }

    private func handleMouseEvent(_ event: NSEvent) {
        let mouseLocation = NSEvent.mouseLocation

        switch status {
        case .closed:
            let inNotch = geometry.isPointInNotch(mouseLocation)
            if event.type == .leftMouseDown && inNotch {
                notchOpen()
            }
        case .opened:
            if event.type == .leftMouseDown {
                let inPanel = geometry.isPointInOpenedPanel(mouseLocation, size: openedSize)
                if !inPanel {
                    notchClose()
                }
            }
        case .popping:
            break
        }
    }

    // MARK: - Actions

    func notchOpen() {
        withAnimation(.spring(response: 0.42, dampingFraction: 0.8)) {
            status = .opened
        }
    }

    func notchClose() {
        contentType = .main
        withAnimation(.spring(response: 0.42, dampingFraction: 0.8)) {
            status = .closed
        }
    }

    func performBootAnimation() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            status = .popping
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                self?.status = .closed
            }
        }
    }

    func connect() async {
        await connect(with: nil)
    }

    func connect(with context: ActivationContext?) async {
        // Allow connecting from idle or any error state
        switch phase {
        case .idle, .error:
            break
        default:
            print("[VoiceVM] connect() called but phase is \(phase), returning")
            return
        }
        print("[VoiceVM] Starting connection...")
        phase = .connecting

        // Store context for use after connection
        if let context = context, !context.isEmpty {
            self.activationContext = context
        }

        do {
            try await liveKitService.connect()
            print("[VoiceVM] Connected and mic enabled")
            phase = .listening
            print("[VoiceVM] Now listening, phase = \(phase)")

            // Send context to agent if present
            if let context = activationContext, !context.isEmpty {
                await sendContextToAgent(context)
            }
        } catch {
            print("[VoiceVM] Connection error: \(error)")
            phase = .error(error.localizedDescription)
        }
    }

    func setActivationContext(_ context: ActivationContext) {
        self.activationContext = context
        print("[VoiceVM] Context set: session=\(context.sessionId ?? "none")")

        // If already connected, send context immediately
        if phase != .idle && phase != .connecting {
            Task {
                await sendContextToAgent(context)
            }
        }
    }

    private func sendContextToAgent(_ context: ActivationContext) async {
        guard let prompt = context.toSystemPrompt() else { return }
        print("[VoiceVM] Sending context to agent: \(prompt)")
        await liveKitService.sendContextMessage(prompt)
    }

    func disconnect() async {
        print("[VoiceVM] disconnect() called - stack trace follows")
        Thread.callStackSymbols.prefix(10).forEach { print($0) }
        await liveKitService.disconnect()
        phase = .idle
    }

    func startListening() {
        guard phase == .connected else { return }
        phase = .listening
        liveKitService.setMicrophoneEnabled(true)
    }

    func stopListening() {
        guard phase == .listening else { return }
        phase = .processing
        liveKitService.setMicrophoneEnabled(false)
    }

    func toggleSettings() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            contentType = contentType == .settings ? .main : .settings
        }
    }

    func showTranscript() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            contentType = .transcript
        }
    }

    func clearTranscript() {
        liveKitService.clearTranscript()
    }
}
