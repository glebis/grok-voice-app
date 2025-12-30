//
//  VoiceSettings.swift
//  GrokVoice
//
//  UserDefaults-backed settings
//

import Foundation

enum VoiceSettings {
    private static let defaults = UserDefaults.standard

    private enum Keys {
        static let liveKitURL = "liveKitURL"
        static let liveKitToken = "liveKitToken"
        static let selectedVoice = "selectedVoice"
        static let vaultPath = "vaultPath"
        static let pushToTalk = "pushToTalk"
        static let inputDeviceUID = "inputDeviceUID"
        static let outputDeviceUID = "outputDeviceUID"
        static let wakeWordDeviceIndex = "wakeWordDeviceIndex"
    }

    // MARK: - LiveKit Settings

    static var liveKitURL: String {
        get { defaults.string(forKey: Keys.liveKitURL) ?? "ws://localhost:7880" }
        set { defaults.set(newValue, forKey: Keys.liveKitURL) }
    }

    static var liveKitToken: String? {
        get {
            // Try Keychain first, fall back to UserDefaults
            if let token = KeychainService.load(.liveKitToken) {
                return token
            }
            return defaults.string(forKey: Keys.liveKitToken)
        }
        set {
            if let value = newValue {
                // Try to save to Keychain, always save to UserDefaults as backup
                KeychainService.save(value, for: .liveKitToken)
                defaults.set(value, forKey: Keys.liveKitToken)
            } else {
                KeychainService.delete(.liveKitToken)
                defaults.removeObject(forKey: Keys.liveKitToken)
            }
        }
    }

    // MARK: - Voice Settings

    static var selectedVoice: GrokVoice {
        get {
            guard let rawValue = defaults.string(forKey: Keys.selectedVoice),
                  let voice = GrokVoice(rawValue: rawValue) else {
                return .ara
            }
            return voice
        }
        set { defaults.set(newValue.rawValue, forKey: Keys.selectedVoice) }
    }

    // MARK: - Vault Settings

    static var vaultPath: String? {
        get { defaults.string(forKey: Keys.vaultPath) }
        set { defaults.set(newValue, forKey: Keys.vaultPath) }
    }

    // MARK: - Interaction Settings

    static var pushToTalk: Bool {
        get { defaults.bool(forKey: Keys.pushToTalk) }
        set { defaults.set(newValue, forKey: Keys.pushToTalk) }
    }

    // MARK: - Audio Device Settings

    static var inputDeviceUID: String? {
        get { defaults.string(forKey: Keys.inputDeviceUID) }
        set { defaults.set(newValue, forKey: Keys.inputDeviceUID) }
    }

    static var outputDeviceUID: String? {
        get { defaults.string(forKey: Keys.outputDeviceUID) }
        set { defaults.set(newValue, forKey: Keys.outputDeviceUID) }
    }

    // MARK: - Wake Word Settings

    /// Device index for wake word microphone (-1 = system default)
    static var wakeWordDeviceIndex: Int {
        get { defaults.object(forKey: Keys.wakeWordDeviceIndex) as? Int ?? -1 }
        set {
            defaults.set(newValue, forKey: Keys.wakeWordDeviceIndex)
            // Also write to shared config for Python script
            writeWakeWordConfig(deviceIndex: newValue)
        }
    }

    /// Write wake word config to shared JSON file for Python script
    private static func writeWakeWordConfig(deviceIndex: Int) {
        let config: [String: Any] = [
            "device_index": deviceIndex,
            "keyword": "computer"
        ]
        let configPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".grokvoice_wake_word.json")

        if let data = try? JSONSerialization.data(withJSONObject: config, options: .prettyPrinted) {
            try? data.write(to: configPath)
        }
    }
}
