//
//  GameSceneInputRouting.swift
//  贪吃蛇
//
//  Created by Codex on 2026/3/8.
//

import AppKit

extension GameScene {
    func handleInputAction(_ action: GameInputAction) {
        switch action {
        case .changeDirection, .primaryAction, .togglePause, .secondaryAction:
            _ = renderer.clearOverlayHover()
            updateCursorStyle(isInteractive: false)
        case .boostPressed, .boostReleased:
            break
        }

        switch action {
        case .changeDirection(let direction):
            handleDirectionAction(direction)
        case .primaryAction:
            handlePrimaryAction()
        case .boostPressed:
            handleBoostPressed()
        case .boostReleased:
            boostButtonHeld = false
        case .togglePause:
            handlePauseAction()
        case .secondaryAction:
            handleSecondaryAction()
        }
    }

    func handleDirectionAction(_ direction: Direction) {
        switch mode {
        case .gameSelection:
            switch direction {
            case .left, .right:
                let delta = direction == .left ? -1 : 1
                if gameSelectionSection == 0 {
                    gameSelectionIndex = wrappedIndex(gameSelectionIndex + delta, count: GameCollectionOption.allCases.count)
                } else {
                    gameSelectionRoleIndex = wrappedIndex(gameSelectionRoleIndex + delta, count: FamilyMember.allCases.count + 1)
                }
            case .up, .down:
                gameSelectionSection = wrappedIndex(gameSelectionSection + (direction == .up ? -1 : 1), count: 2)
            }
            audioController.playNavigate()
            renderCurrent()
        case .snakeModeSelection:
            guard direction == .up || direction == .down else {
                return
            }
            let delta = direction == .up ? -1 : 1
            snakeModeSelection = wrappedIndex(snakeModeSelection + delta, count: SnakeEntryModeOption.allCases.count)
            audioController.playNavigate()
            renderCurrent()
        case .gameConstruction:
            break
        case .playing:
            engine.queueDirection(direction)
            if engine.snapshot.isManualStepModeEnabled {
                let events = engine.advance()
                handle(events: events)
                renderCurrent()
            }
        case .battleSetup:
            switch direction {
            case .up:
                battleSetupSelection = wrappedIndex(battleSetupSelection - 1, count: battleSetupItemCount)
            case .down:
                battleSetupSelection = wrappedIndex(battleSetupSelection + 1, count: battleSetupItemCount)
            case .left:
                adjustBattleSetup(step: -1)
            case .right:
                adjustBattleSetup(step: 1)
            }
            audioController.playNavigate()
            renderCurrent()
        case .mainMenu:
            guard direction == .up || direction == .down else {
                return
            }
            let delta = direction == .up ? -1 : 1
            mainMenuSelection = wrappedIndex(mainMenuSelection + delta, count: MainMenuOption.allCases.count)
            audioController.playNavigate()
            renderCurrent()
        case .familyOverview:
            switch direction {
            case .up:
                familyOverviewSelection = wrappedIndex(familyOverviewSelection - 2, count: FamilyMember.allCases.count)
            case .down:
                familyOverviewSelection = wrappedIndex(familyOverviewSelection + 2, count: FamilyMember.allCases.count)
            case .left:
                familyOverviewSelection = wrappedIndex(familyOverviewSelection - 1, count: FamilyMember.allCases.count)
            case .right:
                familyOverviewSelection = wrappedIndex(familyOverviewSelection + 1, count: FamilyMember.allCases.count)
            }
            audioController.playNavigate()
            renderCurrent()
        case .familyDetail:
            guard let member = familyDetailMember else {
                return
            }
            let itemCount = familyDetailItems(for: member).count
            guard direction == .up || direction == .down else {
                return
            }
            let delta = direction == .up ? -1 : 1
            familyDetailSelection = wrappedIndex(familyDetailSelection + delta, count: itemCount)
            audioController.playNavigate()
            renderCurrent()
        case .achievements:
            switch direction {
            case .up:
                achievementSelection = wrappedIndex(achievementSelection - 3, count: AchievementCatalog.all.count)
            case .down:
                achievementSelection = wrappedIndex(achievementSelection + 3, count: AchievementCatalog.all.count)
            case .left:
                achievementSelection = wrappedIndex(achievementSelection - 1, count: AchievementCatalog.all.count)
            case .right:
                achievementSelection = wrappedIndex(achievementSelection + 1, count: AchievementCatalog.all.count)
            }
            audioController.playNavigate()
            renderCurrent()
        case .leaderboard:
            guard direction == .left || direction == .right || direction == .up || direction == .down else {
                return
            }
            let delta = (direction == .left || direction == .up) ? -1 : 1
            leaderboardScopeSelection = wrappedIndex(leaderboardScopeSelection + delta, count: LeaderboardScope.allCases.count)
            audioController.playNavigate()
            renderCurrent()
        case .battleSummary:
            break
        case .achievementDetail:
            guard direction == .left || direction == .right else {
                return
            }
            achievementSelection = wrappedIndex(
                achievementSelection + (direction == .left ? -1 : 1),
                count: AchievementCatalog.all.count
            )
            audioController.playNavigate()
            renderCurrent()
        case .help:
            break
        case .codex:
            switch direction {
            case .up, .down:
                let delta = direction == .up ? -1 : 1
                codexSectionSelection = wrappedIndex(codexSectionSelection + delta, count: CodexSection.allCases.count)
                clampCodexItemSelection()
            case .left, .right:
                let delta = direction == .left ? -1 : 1
                codexItemSelection = wrappedIndex(codexItemSelection + delta, count: codexEntriesForCurrentSection.count)
            }
            audioController.playNavigate()
            renderCurrent()
        case .codexDetail:
            switch direction {
            case .up, .down:
                let delta = direction == .up ? -1 : 1
                codexSectionSelection = wrappedIndex(codexSectionSelection + delta, count: CodexSection.allCases.count)
                clampCodexItemSelection()
            case .left, .right:
                let delta = direction == .left ? -1 : 1
                codexItemSelection = wrappedIndex(codexItemSelection + delta, count: codexEntriesForCurrentSection.count)
            }
            audioController.playNavigate()
            renderCurrent()
        case .settings:
            switch direction {
            case .up, .down:
                let delta = direction == .up ? -1 : 1
                settingsSelection = wrappedIndex(settingsSelection + delta, count: SettingsOption.allCases.count)
                audioController.playNavigate()
            case .left:
                adjustSelectedSetting(step: -1)
            case .right:
                adjustSelectedSetting(step: 1)
            }
            renderCurrent()
        case .gameOver:
            guard direction == .up || direction == .down else {
                return
            }
            let delta = direction == .up ? -1 : 1
            gameOverSelection = wrappedIndex(gameOverSelection + delta, count: GameOverOption.allCases.count)
            audioController.playNavigate()
            renderCurrent()
        case .ready, .paused:
            break
        }
    }

    func handlePrimaryAction() {
        switch mode {
        case .gameSelection:
            if gameSelectionSection == 0 {
                applyGameSelection()
            } else {
                applyGameSelectionRole()
            }
        case .snakeModeSelection:
            applySnakeModeSelection()
        case .gameConstruction:
            mode = .gameSelection
            audioController.playConfirm()
            syncAudioMode()
        case .mainMenu:
            applyMainMenuSelection()
        case .battleSetup:
            applyBattleSetupSelection()
        case .familyOverview:
            if characterSelectionFlow == .launchSnake {
                applyCharacterSelectionLaunch()
            } else {
                openFamilyDetail(for: FamilyMember.allCases[wrappedIndex(familyOverviewSelection, count: FamilyMember.allCases.count)])
            }
        case .familyDetail:
            applyFamilyDetailSelection()
        case .achievements:
            mode = .achievementDetail
            audioController.playConfirm()
            syncAudioMode()
        case .leaderboard:
            mode = .mainMenu
            audioController.playConfirm()
            syncAudioMode()
        case .battleSummary:
            battleSession = nil
            mode = .mainMenu
            audioController.playConfirm()
            syncAudioMode()
        case .achievementDetail, .help:
            mode = .mainMenu
            audioController.playConfirm()
            syncAudioMode()
        case .codex:
            mode = .codexDetail
            audioController.playConfirm()
            syncAudioMode()
        case .codexDetail:
            mode = .codex
            audioController.playConfirm()
            syncAudioMode()
        case .settings:
            applySettingsPrimaryAction()
        case .ready:
            beginCurrentRun()
            syncAudioMode()
        case .paused:
            mode = .playing
            audioController.playPause()
            syncAudioMode()
        case .gameOver:
            applyGameOverSelection()
        case .playing:
            break
        }
        renderCurrent()
    }

    func handleOverlayItemClick(_ index: Int) {
        switch mode {
        case .gameSelection:
            if GameCollectionOption.allCases.indices.contains(index) {
                gameSelectionSection = 0
                gameSelectionIndex = index
                applyGameSelection()
            } else {
                let roleIndex = index - GameCollectionOption.allCases.count
                guard roleIndex >= 0, roleIndex <= FamilyMember.allCases.count else {
                    return
                }
                gameSelectionSection = 1
                gameSelectionRoleIndex = roleIndex
                applyGameSelectionRole()
            }
        case .snakeModeSelection:
            guard SnakeEntryModeOption.allCases.indices.contains(index) else {
                return
            }
            snakeModeSelection = index
            applySnakeModeSelection()
        case .gameConstruction:
            mode = .gameSelection
            audioController.playConfirm()
            syncAudioMode()
        case .mainMenu:
            guard MainMenuOption.allCases.indices.contains(index) else {
                return
            }
            mainMenuSelection = index
            applyMainMenuSelection()
        case .battleSetup:
            guard (0 ..< battleSetupItemCount).contains(index) else {
                return
            }
            battleSetupSelection = index
            applyBattleSetupSelection()
        case .familyOverview:
            guard FamilyMember.allCases.indices.contains(index) else {
                return
            }
            familyOverviewSelection = index
            if characterSelectionFlow == .launchSnake {
                applyCharacterSelectionLaunch()
            } else {
                openFamilyDetail(for: FamilyMember.allCases[index])
            }
        case .familyDetail:
            guard let member = familyDetailMember else {
                return
            }
            let items = familyDetailItems(for: member)
            guard items.indices.contains(index) else {
                return
            }
            familyDetailSelection = index
            applyFamilyDetailSelection()
        case .achievements:
            guard AchievementCatalog.all.indices.contains(index) else {
                return
            }
            achievementSelection = index
            mode = .achievementDetail
            audioController.playConfirm()
            syncAudioMode()
        case .leaderboard:
            let scope = LeaderboardScope.allCases[leaderboardScopeSelection]
            guard scope == .family,
                  familyLeaderboardEntries.indices.contains(index) else {
                return
            }
            let member = familyLeaderboardEntries[index].member
            settings.familyMember = member
            renameFamilyMember(member)
            return
        case .settings:
            guard SettingsOption.allCases.indices.contains(index) else {
                return
            }
            settingsSelection = index
            applySettingsPrimaryAction()
        case .gameOver:
            guard GameOverOption.allCases.indices.contains(index) else {
                return
            }
            gameOverSelection = index
            applyGameOverSelection()
        case .codex:
            guard codexEntriesForCurrentSection.indices.contains(index) else {
                return
            }
            codexItemSelection = index
            mode = .codexDetail
            audioController.playConfirm()
            syncAudioMode()
        case .battleSummary, .achievementDetail, .help, .codexDetail, .ready, .playing, .paused:
            return
        }
        renderCurrent()
    }

    func handleOverlayBlankClick(at location: CGPoint) {
        guard renderer.overlayContains(location) else {
            return
        }

        switch mode {
        case .battleSummary:
            handleSecondaryAction()
        case .achievementDetail:
            if let step = renderer.overlayDetailNavigationStep(at: location) {
                achievementSelection = wrappedIndex(achievementSelection + step, count: AchievementCatalog.all.count)
                audioController.playNavigate()
                renderCurrent()
                return
            }
            handleSecondaryAction()
        case .codexDetail:
            if let step = renderer.overlayDetailNavigationStep(at: location) {
                codexItemSelection = wrappedIndex(codexItemSelection + step, count: codexEntriesForCurrentSection.count)
                audioController.playNavigate()
                renderCurrent()
                return
            }
            handleSecondaryAction()
        case .gameSelection, .gameConstruction, .snakeModeSelection, .battleSetup, .leaderboard, .familyOverview, .familyDetail, .achievements, .codex, .help, .settings, .gameOver, .ready:
            break
        case .mainMenu, .playing, .paused:
            break
        }
    }

    func handleOverlayTabClick(_ index: Int) {
        switch mode {
        case .leaderboard:
            guard LeaderboardScope.allCases.indices.contains(index) else {
                return
            }
            leaderboardScopeSelection = index
            audioController.playNavigate()
            renderCurrent()
        case .codex, .codexDetail:
            guard CodexSection.allCases.indices.contains(index) else {
                return
            }
            codexSectionSelection = index
            clampCodexItemSelection()
            audioController.playNavigate()
            renderCurrent()
        case .gameSelection, .gameConstruction, .snakeModeSelection, .mainMenu, .battleSetup, .battleSummary, .familyOverview, .familyDetail, .achievements, .achievementDetail, .help, .settings, .ready, .playing, .paused, .gameOver:
            break
        }
    }

    func handlePauseAction() {
        switch mode {
        case .gameSelection, .gameConstruction, .snakeModeSelection:
            break
        case .playing:
            mode = .paused
            boostButtonHeld = false
            audioController.playPause()
            syncAudioMode()
        case .paused:
            mode = .playing
            audioController.playPause()
            syncAudioMode()
        case .mainMenu, .battleSetup, .battleSummary, .familyOverview, .familyDetail, .achievements, .achievementDetail, .leaderboard, .codex, .codexDetail, .help, .settings, .ready, .gameOver:
            break
        }
        renderCurrent()
    }

    func handleSecondaryAction() {
        switch mode {
        case .gameConstruction:
            mode = .gameSelection
            audioController.playConfirm()
            syncAudioMode()
        case .gameSelection:
            guard confirmExitApplication() else {
                renderCurrent()
                return
            }
            NSApplication.shared.terminate(nil)
        case .snakeModeSelection:
            mode = .gameSelection
            audioController.playConfirm()
            syncAudioMode()
        case .playing:
            mode = .paused
            boostButtonHeld = false
            audioController.playPause()
            syncAudioMode()
        case .paused, .ready:
            if battleSession != nil, !hasStartedCurrentRun {
                cancelBattleFlow()
                return
            }
            mode = .mainMenu
            syncAudioMode()
        case .gameOver:
            preparePreview()
            mode = .mainMenu
            syncAudioMode()
        case .battleSetup:
            cancelBattleFlow()
            return
        case .battleSummary:
            battleSession = nil
            mode = .mainMenu
            audioController.playConfirm()
            syncAudioMode()
        case .familyDetail:
            mode = .familyOverview
            audioController.playConfirm()
            syncAudioMode()
        case .achievementDetail:
            mode = .achievements
            audioController.playConfirm()
            syncAudioMode()
        case .codexDetail:
            mode = .codex
            audioController.playConfirm()
            syncAudioMode()
        case .leaderboard, .settings, .achievements, .codex, .help:
            mode = .mainMenu
            audioController.playConfirm()
            syncAudioMode()
        case .familyOverview:
            if characterSelectionFlow == .launchSnake {
                characterSelectionFlow = .manageProfiles
                mode = .gameSelection
            } else {
                mode = .mainMenu
            }
            audioController.playConfirm()
            syncAudioMode()
        case .mainMenu:
            guard confirmReturnToHome() else {
                renderCurrent()
                return
            }
            mode = .gameSelection
            audioController.playConfirm()
            syncAudioMode()
        }
        renderCurrent()
    }
}
