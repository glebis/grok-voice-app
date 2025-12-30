//
//  LiveKitService.swift
//  GrokVoice
//
//  LiveKit Room connection and audio handling
//

import Foundation
import LiveKit
import Combine

@MainActor
class LiveKitService: ObservableObject {
    static let shared = LiveKitService()

    // MARK: - Published State
    @Published var connectionState: LiveKit.ConnectionState = .disconnected
    @Published var currentTranscript: String = ""
    @Published var transcriptHistory: [TranscriptItem] = []
    @Published var isSpeaking: Bool = false
    @Published var isListening: Bool = false
    @Published var currentToolStatus: ToolStatus?
    @Published var localAudioLevel: Float = 0
    @Published var remoteAudioLevel: Float = 0

    // MARK: - LiveKit
    private var room: Room?
    private var cancellables = Set<AnyCancellable>()
    private var audioLevelTimer: Timer?

    private init() {}

    // MARK: - Connection

    func connect() async throws {
        guard let token = VoiceSettings.liveKitToken, !token.isEmpty else {
            print("[LiveKit] No token configured!")
            throw LiveKitServiceError.noToken
        }

        let url = VoiceSettings.liveKitURL
        print("[LiveKit] Connecting to \(url) with token: \(token.prefix(20))...")

        room = Room()
        room?.add(delegate: self)

        let connectOptions = ConnectOptions(
            autoSubscribe: true
        )

        let roomOptions = RoomOptions(
            defaultCameraCaptureOptions: CameraCaptureOptions(),
            defaultAudioCaptureOptions: AudioCaptureOptions(
                echoCancellation: true,
                autoGainControl: true,
                noiseSuppression: true
            )
        )

        try await room?.connect(url: url, token: token, connectOptions: connectOptions, roomOptions: roomOptions)
        print("[LiveKit] Connected successfully!")
        connectionState = .connected

        // Wait a bit for ICE to establish
        try await Task.sleep(nanoseconds: 500_000_000)  // 500ms

        print("[LiveKit] Auto-publishing microphone...")
        let publication = try await room?.localParticipant.setMicrophone(enabled: true)
        print("[LiveKit] Microphone published: \(String(describing: publication?.sid))")
        isListening = true

        // Start audio level polling
        startAudioLevelPolling()
    }

    private func startAudioLevelPolling() {
        audioLevelTimer?.invalidate()
        audioLevelTimer = Timer.scheduledTimer(withTimeInterval: 1.0/30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateAudioLevels()
            }
        }
    }

    private func stopAudioLevelPolling() {
        audioLevelTimer?.invalidate()
        audioLevelTimer = nil
        localAudioLevel = 0
        remoteAudioLevel = 0
    }

    private func updateAudioLevels() {
        guard let room = room else { return }

        // Get local participant's audio level
        localAudioLevel = room.localParticipant.audioLevel

        // Get remote participants' audio levels (max)
        var maxRemoteLevel: Float = 0
        for (_, participant) in room.remoteParticipants {
            maxRemoteLevel = max(maxRemoteLevel, participant.audioLevel)
        }
        remoteAudioLevel = maxRemoteLevel
    }

    func disconnect() async {
        stopAudioLevelPolling()
        await room?.disconnect()
        room = nil
        connectionState = .disconnected
        isListening = false
        isSpeaking = false
    }

    func setMicrophoneEnabled(_ enabled: Bool) {
        print("[LiveKit] setMicrophoneEnabled(\(enabled))")
        Task {
            do {
                let publication = try await room?.localParticipant.setMicrophone(enabled: enabled)
                print("[LiveKit] Microphone set to \(enabled), publication: \(String(describing: publication?.sid)), source: \(String(describing: publication?.source))")
                isListening = enabled
            } catch {
                print("[LiveKit] Failed to set microphone: \(error)")
            }
        }
    }

    func clearTranscript() {
        transcriptHistory.removeAll()
        currentTranscript = ""
    }

    /// Send context message to agent via data channel
    func sendContextMessage(_ context: String) async {
        guard let room = room, connectionState == .connected else {
            print("[LiveKit] Cannot send context - not connected")
            return
        }

        guard let data = context.data(using: .utf8) else { return }

        do {
            try await room.localParticipant.publish(data: data, options: DataPublishOptions(topic: "context"))
            print("[LiveKit] Sent context message: \(context.prefix(100))...")
        } catch {
            print("[LiveKit] Failed to send context: \(error)")
        }
    }
}

// MARK: - RoomDelegate

extension LiveKitService: RoomDelegate {
    nonisolated func room(_ room: Room, didUpdateConnectionState connectionState: LiveKit.ConnectionState, from oldConnectionState: LiveKit.ConnectionState) {
        print("[LiveKit] RoomDelegate: connection state \(oldConnectionState) -> \(connectionState)")
        Task { @MainActor in
            self.connectionState = connectionState
        }
    }

    nonisolated func room(_ room: Room, participant: RemoteParticipant?, didReceiveData data: Data, forTopic topic: String, encryptionType: EncryptionType) {
        Task { @MainActor in
            self.handleDataMessage(data, topic: topic)
        }
    }

    nonisolated func room(_ room: Room, participant: RemoteParticipant, trackPublication: RemoteTrackPublication, didSubscribeTrack track: Track) {
        Task { @MainActor in
            if track is AudioTrack {
                self.isSpeaking = true
            }
        }
    }

    nonisolated func room(_ room: Room, participant: RemoteParticipant, trackPublication: RemoteTrackPublication, didUnsubscribeTrack track: Track) {
        Task { @MainActor in
            if track is AudioTrack {
                self.isSpeaking = false
            }
        }
    }
}

// MARK: - Private

extension LiveKitService {
    private func handleDataMessage(_ data: Data, topic: String?) {
        guard let text = String(data: data, encoding: .utf8) else { return }

        if topic == "transcript" || topic == "partial_transcript" {
            currentTranscript = text
        } else if topic == "final_transcript" || topic == "assistant_response" {
            let item = TranscriptItem(
                role: .assistant,
                text: text
            )
            transcriptHistory.append(item)
            currentTranscript = ""
        } else if topic == "user_transcript" {
            let item = TranscriptItem(
                role: .user,
                text: text
            )
            transcriptHistory.append(item)
        } else if topic == "tool_status" {
            // Parse tool status JSON: {"tool": "Grep", "input": "pattern..."}
            if let jsonData = text.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
               let toolName = json["tool"] as? String {
                let input = json["input"] as? String ?? ""
                currentToolStatus = ToolStatus(toolName: toolName, input: input)
            }
        } else if topic == "tool_done" {
            // Clear tool status when done
            currentToolStatus = nil
        }
    }
}

enum LiveKitServiceError: LocalizedError {
    case noToken
    case connectionFailed

    var errorDescription: String? {
        switch self {
        case .noToken:
            return "No LiveKit token configured"
        case .connectionFailed:
            return "Failed to connect to LiveKit server"
        }
    }
}
