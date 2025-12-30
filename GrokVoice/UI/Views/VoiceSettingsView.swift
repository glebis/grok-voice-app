//
//  VoiceSettingsView.swift
//  GrokVoice
//
//  Settings panel for voice configuration
//

import SwiftUI

struct VoiceSettingsView: View {
    @ObservedObject var viewModel: VoiceViewModel
    @StateObject private var audioManager = AudioDeviceManager.shared
    @State private var liveKitURL: String = VoiceSettings.liveKitURL
    @State private var liveKitToken: String = VoiceSettings.liveKitToken ?? ""
    @State private var selectedVoice: GrokVoice = VoiceSettings.selectedVoice
    @State private var vaultPath: String = VoiceSettings.vaultPath ?? ""
    @State private var pushToTalk: Bool = VoiceSettings.pushToTalk
    @State private var selectedInputUID: String? = VoiceSettings.inputDeviceUID
    @State private var selectedOutputUID: String? = VoiceSettings.outputDeviceUID
    @State private var wakeWordDeviceIndex: Int = VoiceSettings.wakeWordDeviceIndex

    var body: some View {
        VStack(spacing: 4) {
            // Back button
            MenuRow(icon: "chevron.left", label: "Back") {
                viewModel.toggleSettings()
            }

            Divider()
                .background(Color.white.opacity(0.08))
                .padding(.vertical, 4)

            // LiveKit URL
            SettingsTextField(
                icon: "network",
                label: "LiveKit URL",
                text: $liveKitURL,
                placeholder: "ws://localhost:7880"
            )
            .onChange(of: liveKitURL) { _, newValue in
                VoiceSettings.liveKitURL = newValue
            }

            // LiveKit Token
            SettingsTextField(
                icon: "key",
                label: "Token",
                text: $liveKitToken,
                placeholder: "Enter LiveKit token"
            )
            .onChange(of: liveKitToken) { _, newValue in
                VoiceSettings.liveKitToken = newValue.isEmpty ? nil : newValue
            }

            // Voice Selection
            VoicePickerRow(selectedVoice: $selectedVoice)
                .onChange(of: selectedVoice) { _, newValue in
                    VoiceSettings.selectedVoice = newValue
                }

            Divider()
                .background(Color.white.opacity(0.08))
                .padding(.vertical, 4)

            // Microphone Selection
            AudioDevicePickerRow(
                icon: "mic",
                label: "Microphone",
                devices: audioManager.inputDevices,
                selectedUID: $selectedInputUID
            )
            .onChange(of: selectedInputUID) { _, newValue in
                VoiceSettings.inputDeviceUID = newValue
            }

            // Speaker Selection
            AudioDevicePickerRow(
                icon: "speaker.wave.2",
                label: "Speaker",
                devices: audioManager.outputDevices,
                selectedUID: $selectedOutputUID
            )
            .onChange(of: selectedOutputUID) { _, newValue in
                VoiceSettings.outputDeviceUID = newValue
            }

            Divider()
                .background(Color.white.opacity(0.08))
                .padding(.vertical, 4)

            // Wake Word Section
            WakeWordSettingsRow(
                devices: audioManager.inputDevices,
                selectedIndex: $wakeWordDeviceIndex
            )
            .onChange(of: wakeWordDeviceIndex) { _, newValue in
                VoiceSettings.wakeWordDeviceIndex = newValue
            }

            Divider()
                .background(Color.white.opacity(0.08))
                .padding(.vertical, 4)

            // Vault Path
            SettingsTextField(
                icon: "folder",
                label: "Vault Path",
                text: $vaultPath,
                placeholder: "/path/to/vault"
            )
            .onChange(of: vaultPath) { _, newValue in
                VoiceSettings.vaultPath = newValue.isEmpty ? nil : newValue
            }

            Divider()
                .background(Color.white.opacity(0.08))
                .padding(.vertical, 4)

            // Push to Talk toggle
            MenuToggleRow(
                icon: "hand.tap",
                label: "Push to Talk",
                isOn: pushToTalk
            ) {
                pushToTalk.toggle()
                VoiceSettings.pushToTalk = pushToTalk
            }

            if viewModel.phase != .idle {
                Divider()
                    .background(Color.white.opacity(0.08))
                    .padding(.vertical, 4)

                MenuRow(
                    icon: "phone.down.fill",
                    label: "Disconnect",
                    isDestructive: true
                ) {
                    Task { await viewModel.disconnect() }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
    }
}

struct MenuRow: View {
    let icon: String
    let label: String
    var isDestructive: Bool = false
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(isDestructive ? .red : .white.opacity(isHovered ? 1.0 : 0.7))
                    .frame(width: 16)

                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isDestructive ? .red : .white.opacity(isHovered ? 1.0 : 0.7))

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered ? Color.white.opacity(0.08) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

struct MenuToggleRow: View {
    let icon: String
    let label: String
    let isOn: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(isHovered ? 1.0 : 0.7))
                    .frame(width: 16)

                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(isHovered ? 1.0 : 0.7))

                Spacer()

                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 14))
                    .foregroundColor(isOn ? .green : .white.opacity(0.3))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered ? Color.white.opacity(0.08) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

struct SettingsTextField: View {
    let icon: String
    let label: String
    @Binding var text: String
    let placeholder: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 16)

            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.7))

            Spacer()

            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.9))
                .frame(maxWidth: 160)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.1))
                .cornerRadius(4)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}

struct VoicePickerRow: View {
    @Binding var selectedVoice: GrokVoice
    @State private var isExpanded = false
    @State private var isHovered = false

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "person.wave.2")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(isHovered ? 1.0 : 0.7))
                        .frame(width: 16)

                    Text("Voice")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(isHovered ? 1.0 : 0.7))

                    Spacer()

                    Text(selectedVoice.displayName)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))

                    Image(systemName: "chevron.right")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.3))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isHovered ? Color.white.opacity(0.08) : Color.clear)
                )
            }
            .buttonStyle(.plain)
            .onHover { isHovered = $0 }

            if isExpanded {
                VStack(spacing: 2) {
                    ForEach(GrokVoice.allCases, id: \.self) { voice in
                        VoiceOptionRow(
                            voice: voice,
                            isSelected: selectedVoice == voice
                        ) {
                            selectedVoice = voice
                            withAnimation {
                                isExpanded = false
                            }
                        }
                    }
                }
                .padding(.leading, 28)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

struct VoiceOptionRow: View {
    let voice: GrokVoice
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(voice.displayName)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? Color.white.opacity(0.05) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

struct AudioDevicePickerRow: View {
    let icon: String
    let label: String
    let devices: [AudioDevice]
    @Binding var selectedUID: String?

    @State private var isExpanded = false
    @State private var isHovered = false

    private var selectedDevice: AudioDevice? {
        devices.first { $0.uid == selectedUID }
    }

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(isHovered ? 1.0 : 0.7))
                        .frame(width: 16)

                    Text(label)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(isHovered ? 1.0 : 0.7))

                    Spacer()

                    Text(selectedDevice?.name ?? "System Default")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                        .lineLimit(1)
                        .frame(maxWidth: 120, alignment: .trailing)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.3))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isHovered ? Color.white.opacity(0.08) : Color.clear)
                )
            }
            .buttonStyle(.plain)
            .onHover { isHovered = $0 }

            if isExpanded {
                VStack(spacing: 2) {
                    // System Default option
                    AudioDeviceOptionRow(
                        name: "System Default",
                        isSelected: selectedUID == nil
                    ) {
                        selectedUID = nil
                        withAnimation { isExpanded = false }
                    }

                    ForEach(devices) { device in
                        AudioDeviceOptionRow(
                            name: device.name,
                            isSelected: device.uid == selectedUID
                        ) {
                            selectedUID = device.uid
                            withAnimation { isExpanded = false }
                        }
                    }
                }
                .padding(.leading, 28)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

struct AudioDeviceOptionRow: View {
    let name: String
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(name)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? Color.white.opacity(0.05) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Wake Word Settings

struct WakeWordSettingsRow: View {
    let devices: [AudioDevice]
    @Binding var selectedIndex: Int

    @State private var isExpanded = false
    @State private var isHovered = false

    private var selectedDeviceName: String {
        if selectedIndex < 0 {
            return "System Default"
        }
        // Map index to device name (devices are ordered by index from pvrecorder)
        if selectedIndex < devices.count {
            return devices[selectedIndex].name
        }
        return "Device \(selectedIndex)"
    }

    var body: some View {
        VStack(spacing: 4) {
            // Wake word indicator
            HStack(spacing: 10) {
                Image(systemName: "waveform.badge.mic")
                    .font(.system(size: 12))
                    .foregroundColor(.orange)
                    .frame(width: 16)

                Text("Wake Word")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))

                Spacer()

                Text("\"Computer\"")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.15))
                    .cornerRadius(4)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            // Microphone picker
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "mic.badge.xmark")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(isHovered ? 1.0 : 0.5))
                        .frame(width: 16)

                    Text("Wake Mic")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(isHovered ? 0.8 : 0.5))

                    Spacer()

                    Text(selectedDeviceName)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                        .lineLimit(1)
                        .frame(maxWidth: 120, alignment: .trailing)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.3))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isHovered ? Color.white.opacity(0.05) : Color.clear)
                )
            }
            .buttonStyle(.plain)
            .onHover { isHovered = $0 }

            if isExpanded {
                VStack(spacing: 2) {
                    // System Default option
                    WakeWordDeviceOptionRow(
                        name: "System Default",
                        isSelected: selectedIndex < 0
                    ) {
                        withAnimation {
                            selectedIndex = -1
                            isExpanded = false
                        }
                    }

                    ForEach(0..<devices.count, id: \.self) { index in
                        WakeWordDeviceOptionRow(
                            name: devices[index].name,
                            isSelected: index == selectedIndex
                        ) {
                            withAnimation {
                                selectedIndex = index
                                isExpanded = false
                            }
                        }
                    }
                }
                .padding(.leading, 28)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

struct WakeWordDeviceOptionRow: View {
    let name: String
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(name)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.orange)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? Color.white.opacity(0.05) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
