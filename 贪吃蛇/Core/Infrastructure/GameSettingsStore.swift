//
//  GameSettingsStore.swift
//  贪吃蛇
//
//  Created by zhangwang on 2026/3/7.
//

import Foundation

final class GameSettingsStore {
    private enum Key {
        static let soundEnabled = "snake_orchard.settings.sound_enabled"
        static let musicEnabled = "snake_orchard.settings.music_enabled"
        static let speedPreset = "snake_orchard.settings.speed_preset"
        static let simpleModeEnabled = "snake_orchard.settings.simple_mode_enabled"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var settings: GameSettings {
        get {
            GameSettings(
                soundEnabled: defaults.object(forKey: Key.soundEnabled) as? Bool ?? GameSettings.default.soundEnabled,
                musicEnabled: defaults.object(forKey: Key.musicEnabled) as? Bool ?? GameSettings.default.musicEnabled,
                speedPreset: SpeedPreset(rawValue: defaults.string(forKey: Key.speedPreset) ?? "") ?? GameSettings.default.speedPreset,
                simpleModeEnabled: defaults.object(forKey: Key.simpleModeEnabled) as? Bool ?? GameSettings.default.simpleModeEnabled
            )
        }
        set {
            defaults.set(newValue.soundEnabled, forKey: Key.soundEnabled)
            defaults.set(newValue.musicEnabled, forKey: Key.musicEnabled)
            defaults.set(newValue.speedPreset.rawValue, forKey: Key.speedPreset)
            defaults.set(newValue.simpleModeEnabled, forKey: Key.simpleModeEnabled)
        }
    }
}
