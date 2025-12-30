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

    // MARK: - LiveKit
    private var room: Room?
    private var cancellables = Set<AnyCancellable>()

    private init() {}

    // MARK: - Connection

    func connect() async throws {
        guard let token = VoiceSettings.liveKitToken, !token.isEmpty else {
            throw LiveKitServiceError.noToken
        }

        let url = VoiceSettings.liveKitURL

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
        connectionState = .connected
    }

    func disconnect() async {
        await room?.disconnect()
        room = nil
        connectionState = .disconnected
        isListening = false
        isSpeaking = false
    }

    func setMicrophoneEnabled(_ enabled: Bool) {
        Task {
            do {
                try await room?.localParticipant.setMicrophone(enabled: enabled)
                isListening = enabled
            } catch {
                print("Failed to set microphone: \(error)")
            }
        }
    }

    func clearTranscript() {
        transcriptHistory.removeAll()
        currentTranscript = ""
    }
}

// MARK: - RoomDelegate

extension LiveKitService: RoomDelegate {
    nonisolated func room(_ room: Room, didUpdateConnectionState connectionState: LiveKit.ConnectionState, from oldConnectionState: LiveKit.ConnectionState) {
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
