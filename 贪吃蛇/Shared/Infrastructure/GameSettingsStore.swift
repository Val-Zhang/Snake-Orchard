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
        static let manualStepModeEnabled = "snake_orchard.settings.manual_step_mode_enabled"
        static let battleModeEnabled = "snake_orchard.settings.battle_mode_enabled"
        static let battleParticipants = "snake_orchard.settings.battle_participants"
        static let battleRoundCount = "snake_orchard.settings.battle_round_count"
        static let familyMember = "snake_orchard.settings.family_member"
        static let familyNicknames = "snake_orchard.settings.family_nicknames"
        static let familyAvatars = "snake_orchard.settings.family_avatars"
        static let familyAccents = "snake_orchard.settings.family_accents"
        static let familyPlayModes = "snake_orchard.settings.family_play_modes"
        static let familyHitPoints = "snake_orchard.settings.family_hit_points"
        static let visualTheme = "snake_orchard.settings.visual_theme"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var settings: GameSettings {
        get {
            let storedSimpleModeEnabled = defaults.object(forKey: Key.simpleModeEnabled) as? Bool ?? GameSettings.default.simpleModeEnabled
            let storedManualStepModeEnabled = defaults.object(forKey: Key.manualStepModeEnabled) as? Bool ?? GameSettings.default.manualStepModeEnabled
            let currentFamilyMember = FamilyMember(rawValue: defaults.string(forKey: Key.familyMember) ?? "") ?? GameSettings.default.familyMember
            let storedNicknames = defaults.dictionary(forKey: Key.familyNicknames) as? [String: String] ?? [:]
            let familyNicknames: [FamilyMember: String] = Dictionary(uniqueKeysWithValues: FamilyMember.allCases.compactMap { member in
                guard let nickname = storedNicknames[member.rawValue] else {
                    return nil
                }
                return (member, nickname)
            })
            let storedAvatars = defaults.dictionary(forKey: Key.familyAvatars) as? [String: String] ?? [:]
            let familyAvatars: [FamilyMember: FamilyAvatar] = Dictionary(uniqueKeysWithValues: FamilyMember.allCases.compactMap { member in
                guard let rawValue = storedAvatars[member.rawValue],
                      let avatar = FamilyAvatar(rawValue: rawValue) else {
                    return nil
                }
                return (member, avatar)
            })
            let storedAccents = defaults.dictionary(forKey: Key.familyAccents) as? [String: String] ?? [:]
            let familyAccents: [FamilyMember: FamilyAccent] = Dictionary(uniqueKeysWithValues: FamilyMember.allCases.compactMap { member in
                guard let rawValue = storedAccents[member.rawValue],
                      let accent = FamilyAccent(rawValue: rawValue) else {
                    return nil
                }
                return (member, accent)
            })
            let storedPlayModes = defaults.dictionary(forKey: Key.familyPlayModes) as? [String: String] ?? [:]
            var familyPlayModes: [FamilyMember: FamilyPlayMode] = Dictionary(uniqueKeysWithValues: FamilyMember.allCases.compactMap { member in
                guard let rawValue = storedPlayModes[member.rawValue],
                      let playMode = FamilyPlayMode(rawValue: rawValue) else {
                    return nil
                }
                return (member, playMode)
            })
            let storedHitPoints = defaults.dictionary(forKey: Key.familyHitPoints) as? [String: Int] ?? [:]
            let familyHitPoints: [FamilyMember: Int] = Dictionary(uniqueKeysWithValues: FamilyMember.allCases.compactMap { member in
                guard let hitPoints = storedHitPoints[member.rawValue] else {
                    return nil
                }
                return (member, min(max(hitPoints, 1), 9))
            })
            if familyPlayModes.isEmpty {
                let migratedPlayMode = FamilyPlayMode.from(
                    simpleModeEnabled: storedSimpleModeEnabled,
                    manualStepModeEnabled: storedManualStepModeEnabled
                )
                if migratedPlayMode != .standard {
                    familyPlayModes[currentFamilyMember] = migratedPlayMode
                }
            }
            let storedBattleParticipants = defaults.stringArray(forKey: Key.battleParticipants) ?? []
            let battleParticipants = storedBattleParticipants.compactMap(FamilyMember.init(rawValue:))
            return GameSettings(
                soundEnabled: defaults.object(forKey: Key.soundEnabled) as? Bool ?? GameSettings.default.soundEnabled,
                musicEnabled: defaults.object(forKey: Key.musicEnabled) as? Bool ?? GameSettings.default.musicEnabled,
                speedPreset: SpeedPreset(rawValue: defaults.string(forKey: Key.speedPreset) ?? "") ?? GameSettings.default.speedPreset,
                simpleModeEnabled: storedSimpleModeEnabled,
                manualStepModeEnabled: storedManualStepModeEnabled,
                battleModeEnabled: defaults.object(forKey: Key.battleModeEnabled) as? Bool ?? GameSettings.default.battleModeEnabled,
                battleParticipants: battleParticipants.isEmpty ? GameSettings.default.battleParticipants : battleParticipants,
                battleRoundCount: defaults.object(forKey: Key.battleRoundCount) as? Int ?? GameSettings.default.battleRoundCount,
                familyMember: currentFamilyMember,
                familyNicknames: familyNicknames,
                familyAvatars: familyAvatars,
                familyAccents: familyAccents,
                familyPlayModes: familyPlayModes,
                familyHitPoints: familyHitPoints,
                visualTheme: VisualTheme(rawValue: defaults.string(forKey: Key.visualTheme) ?? "") ?? GameSettings.default.visualTheme
            )
        }
        set {
            defaults.set(newValue.soundEnabled, forKey: Key.soundEnabled)
            defaults.set(newValue.musicEnabled, forKey: Key.musicEnabled)
            defaults.set(newValue.speedPreset.rawValue, forKey: Key.speedPreset)
            defaults.set(newValue.simpleModeEnabled, forKey: Key.simpleModeEnabled)
            defaults.set(newValue.manualStepModeEnabled, forKey: Key.manualStepModeEnabled)
            defaults.set(newValue.battleModeEnabled, forKey: Key.battleModeEnabled)
            defaults.set(newValue.battleParticipants.map(\.rawValue), forKey: Key.battleParticipants)
            defaults.set(newValue.battleRoundCount, forKey: Key.battleRoundCount)
            defaults.set(newValue.familyMember.rawValue, forKey: Key.familyMember)
            defaults.set(
                Dictionary(uniqueKeysWithValues: newValue.familyNicknames.map { ($0.key.rawValue, $0.value) }),
                forKey: Key.familyNicknames
            )
            defaults.set(
                Dictionary(uniqueKeysWithValues: newValue.familyAvatars.map { ($0.key.rawValue, $0.value.rawValue) }),
                forKey: Key.familyAvatars
            )
            defaults.set(
                Dictionary(uniqueKeysWithValues: newValue.familyAccents.map { ($0.key.rawValue, $0.value.rawValue) }),
                forKey: Key.familyAccents
            )
            defaults.set(
                Dictionary(uniqueKeysWithValues: newValue.familyPlayModes.map { ($0.key.rawValue, $0.value.rawValue) }),
                forKey: Key.familyPlayModes
            )
            defaults.set(
                Dictionary(uniqueKeysWithValues: newValue.familyHitPoints.map { ($0.key.rawValue, min(max($0.value, 1), 9)) }),
                forKey: Key.familyHitPoints
            )
            defaults.set(newValue.visualTheme.rawValue, forKey: Key.visualTheme)
        }
    }
}
