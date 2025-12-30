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
    }

    // MARK: - LiveKit Settings

    static var liveKitURL: String {
        get { defaults.string(forKey: Keys.liveKitURL) ?? "ws://localhost:7880" }
        set { defaults.set(newValue, forKey: Keys.liveKitURL) }
    }

    static var liveKitToken: String? {
        get { defaults.string(forKey: Keys.liveKitToken) }
        set { defaults.set(newValue, forKey: Keys.liveKitToken) }
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
}
