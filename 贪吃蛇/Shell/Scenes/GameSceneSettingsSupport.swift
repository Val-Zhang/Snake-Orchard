//
//  GameSceneSettingsSupport.swift
//  贪吃蛇
//
//  Created by Codex on 2026/3/8.
//

import AppKit
import SpriteKit

extension GameScene {
    func applySettingsPrimaryAction() {
        switch SettingsOption.allCases[settingsSelection] {
        case .sound:
            settings.soundEnabled.toggle()
            persistSettings()
            audioController.playConfirm()
        case .music:
            settings.musicEnabled.toggle()
            persistSettings()
            audioController.playConfirm()
        case .simpleMode:
            toggleSimpleMode()
            audioController.playConfirm()
        case .manualStepMode:
            toggleManualStepMode()
            audioController.playConfirm()
        case .speed:
            adjustSpeedPreset(step: 1)
        case .familyMember:
            renameFamilyMember(settings.familyMember)
        case .characterDefinition:
            openFamilyDetail(for: settings.familyMember)
        case .familyAvatar:
            adjustFamilyAvatar(step: 1)
        case .familyAccent:
            adjustFamilyAccent(step: 1)
        case .familyReset:
            resetCurrentFamilyMemberAppearance()
        case .theme:
            adjustTheme(step: 1)
        case .back:
            audioController.playConfirm()
            mode = .mainMenu
            syncAudioMode()
        }
        renderCurrent()
    }

    func adjustSelectedSetting(step: Int) {
        switch SettingsOption.allCases[settingsSelection] {
        case .sound:
            settings.soundEnabled.toggle()
            persistSettings()
            audioController.playNavigate()
        case .music:
            settings.musicEnabled.toggle()
            persistSettings()
            audioController.playNavigate()
        case .simpleMode:
            toggleSimpleMode()
            audioController.playNavigate()
        case .manualStepMode:
            toggleManualStepMode()
            audioController.playNavigate()
        case .speed:
            adjustSpeedPreset(step: step)
        case .familyMember:
            adjustFamilyMember(step: step)
        case .characterDefinition:
            break
        case .familyAvatar:
            adjustFamilyAvatar(step: step)
        case .familyAccent:
            adjustFamilyAccent(step: step)
        case .familyReset:
            break
        case .theme:
            adjustTheme(step: step)
        case .back:
            break
        }
    }

    func displayName(for member: FamilyMember) -> String {
        settings.displayName(for: member)
    }

    func displaySymbol(for member: FamilyMember) -> String {
        settings.avatar(for: member).symbol
    }

    func accent(for member: FamilyMember) -> FamilyAccent {
        settings.accent(for: member)
    }

    func playMode(for member: FamilyMember) -> FamilyPlayMode {
        settings.playMode(for: member)
    }

    func normalized(_ settings: GameSettings) -> GameSettings {
        var normalizedSettings = settings
        normalizedSettings.battleRoundCount = min(max(normalizedSettings.battleRoundCount, 1), 5)
        let normalizedParticipants = FamilyMember.allCases.filter { normalizedSettings.battleParticipants.contains($0) }
        normalizedSettings.battleParticipants = normalizedParticipants.isEmpty
            ? [BattleConfig.defaultConfig.participants[0]]
            : normalizedParticipants
        normalizedSettings.familyNicknames = Dictionary(
            uniqueKeysWithValues: FamilyMember.allCases.compactMap { member in
                let nickname = sanitizedNickname(normalizedSettings.familyNicknames[member] ?? "")
                guard !nickname.isEmpty, nickname != member.title else {
                    return nil
                }
                return (member, nickname)
            }
        )
        normalizedSettings.familyAvatars = Dictionary(
            uniqueKeysWithValues: FamilyMember.allCases.compactMap { member in
                guard let avatar = normalizedSettings.familyAvatars[member] else {
                    return nil
                }
                return (member, avatar)
            }
        )
        normalizedSettings.familyAccents = Dictionary(
            uniqueKeysWithValues: FamilyMember.allCases.compactMap { member in
                guard let accent = normalizedSettings.familyAccents[member] else {
                    return nil
                }
                return (member, accent)
            }
        )
        normalizedSettings.familyPlayModes = Dictionary(
            uniqueKeysWithValues: FamilyMember.allCases.compactMap { member in
                guard let playMode = normalizedSettings.familyPlayModes[member],
                      playMode != .standard else {
                    return nil
                }
                return (member, playMode)
            }
        )
        let currentPlayMode = normalizedSettings.playMode(for: normalizedSettings.familyMember)
        normalizedSettings.simpleModeEnabled = currentPlayMode.isSimpleModeEnabled
        normalizedSettings.manualStepModeEnabled = currentPlayMode.isManualStepEnabled
        if normalizedSettings.simpleModeEnabled, normalizedSettings.speedPreset == .turbo {
            normalizedSettings.speedPreset = .relaxed
        }
        if !unlockedThemes.contains(normalizedSettings.visualTheme) {
            normalizedSettings.visualTheme = .orchard
        }
        return normalizedSettings
    }

    func sanitizedNickname(_ nickname: String) -> String {
        let trimmed = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        return String(trimmed.prefix(10))
    }

    private func adjustSpeedPreset(step: Int) {
        let presets: [SpeedPreset] = settings.simpleModeEnabled ? [.relaxed, .standard] : SpeedPreset.allCases
        guard let currentIndex = presets.firstIndex(of: settings.speedPreset) else {
            settings.speedPreset = presets[0]
            persistSettings()
            audioController.playNavigate()
            return
        }
        settings.speedPreset = presets[wrappedIndex(currentIndex + step, count: presets.count)]
        persistSettings()
        audioController.playNavigate()
    }

    private func toggleSimpleMode() {
        let nextMode: FamilyPlayMode = settings.playMode(for: settings.familyMember).isSimpleModeEnabled ? .standard : .simple
        applyCurrentFamilyPlayMode(nextMode)
    }

    private func toggleManualStepMode() {
        let currentPlayMode = settings.playMode(for: settings.familyMember)
        guard currentPlayMode.isSimpleModeEnabled else {
            return
        }
        let nextMode: FamilyPlayMode = currentPlayMode == .simpleManual ? .simple : .simpleManual
        applyCurrentFamilyPlayMode(nextMode)
    }

    private func adjustTheme(step: Int) {
        let themes = unlockedThemes
        guard !themes.isEmpty else {
            return
        }
        let previousTheme = settings.visualTheme
        guard let currentIndex = themes.firstIndex(of: settings.visualTheme) else {
            settings.visualTheme = themes[0]
            persistSettings()
            audioController.playNavigate()
            renderCurrent()
            renderer.previewThemeTransition(to: settings.visualTheme)
            return
        }
        settings.visualTheme = themes[wrappedIndex(currentIndex + step, count: themes.count)]
        guard settings.visualTheme != previousTheme else {
            return
        }
        persistSettings()
        audioController.playNavigate()
        renderCurrent()
        renderer.previewThemeTransition(to: settings.visualTheme)
    }

    private func adjustFamilyMember(step: Int) {
        let members = FamilyMember.allCases
        guard let currentIndex = members.firstIndex(of: settings.familyMember) else {
            selectFamilyMember(members[0])
            audioController.playNavigate()
            renderCurrent()
            return
        }
        selectFamilyMember(members[wrappedIndex(currentIndex + step, count: members.count)])
        audioController.playNavigate()
        renderCurrent()
    }

    private func adjustFamilyAvatar(step: Int) {
        let avatars = FamilyAvatar.allCases
        let member = settings.familyMember
        let currentAvatar = settings.avatar(for: member)
        guard let currentIndex = avatars.firstIndex(of: currentAvatar) else {
            settings.familyAvatars[member] = avatars[0]
            persistSettings()
            audioController.playNavigate()
            renderCurrent()
            return
        }
        settings.familyAvatars[member] = avatars[wrappedIndex(currentIndex + step, count: avatars.count)]
        persistSettings()
        audioController.playNavigate()
        renderCurrent()
    }

    private func adjustFamilyAccent(step: Int) {
        let accents = FamilyAccent.allCases
        let member = settings.familyMember
        let currentAccent = settings.accent(for: member)
        guard let currentIndex = accents.firstIndex(of: currentAccent) else {
            settings.familyAccents[member] = accents[0]
            persistSettings()
            audioController.playNavigate()
            renderCurrent()
            return
        }
        settings.familyAccents[member] = accents[wrappedIndex(currentIndex + step, count: accents.count)]
        persistSettings()
        audioController.playNavigate()
        renderCurrent()
    }

    func renameFamilyMember(_ member: FamilyMember) {
        let alert = NSAlert()
        alert.messageText = "编辑家庭成员昵称"
        alert.informativeText = "给 \(displaySymbol(for: member)) \(member.title) 设置一个昵称。留空会恢复默认名称。"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "保存")
        alert.addButton(withTitle: "取消")

        let inputField = NSTextField(frame: NSRect(x: 0, y: 0, width: 240, height: 24))
        inputField.placeholderString = member.title
        inputField.stringValue = displayName(for: member)
        alert.accessoryView = inputField

        let response: NSApplication.ModalResponse
        if let window = view?.window {
            response = alert.runModal()
            window.makeFirstResponder(nil)
        } else {
            response = alert.runModal()
        }

        guard response == .alertFirstButtonReturn else {
            return
        }

        let trimmed = sanitizedNickname(inputField.stringValue)
        if trimmed == member.title {
            settings.familyNicknames.removeValue(forKey: member)
        } else {
            settings.familyNicknames[member] = trimmed
        }
        persistSettings()
        audioController.playConfirm()
        renderCurrent()
    }

    func resetCurrentFamilyMemberAppearance() {
        let member = settings.familyMember
        let alert = NSAlert()
        alert.messageText = "恢复当前家庭成员默认外观"
        alert.informativeText = "会把 \(displaySymbol(for: member)) \(displayName(for: member)) 的昵称、头像和颜色恢复成默认值。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "恢复")
        alert.addButton(withTitle: "取消")

        guard alert.runModal() == .alertFirstButtonReturn else {
            return
        }

        settings.familyNicknames.removeValue(forKey: member)
        settings.familyAvatars.removeValue(forKey: member)
        settings.familyAccents.removeValue(forKey: member)
        persistSettings()
        audioController.playConfirm()
        renderCurrent()
    }

    func selectFamilyMember(_ member: FamilyMember, refreshPreview: Bool = true) {
        settings.familyMember = member
        let playMode = settings.playMode(for: member)
        settings.simpleModeEnabled = playMode.isSimpleModeEnabled
        settings.manualStepModeEnabled = playMode.isManualStepEnabled
        persistSettings()
        if refreshPreview, battleSession == nil, mode != .playing, mode != .paused, mode != .gameOver {
            preparePreview()
        }
    }

    private func applyCurrentFamilyPlayMode(_ playMode: FamilyPlayMode) {
        if playMode == .standard {
            settings.familyPlayModes.removeValue(forKey: settings.familyMember)
        } else {
            settings.familyPlayModes[settings.familyMember] = playMode
        }
        settings.simpleModeEnabled = playMode.isSimpleModeEnabled
        settings.manualStepModeEnabled = playMode.isManualStepEnabled
        persistSettings()
        if battleSession == nil, mode != .playing, mode != .paused, mode != .gameOver {
            preparePreview()
        }
    }
}
