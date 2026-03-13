//
//  GameSceneBattleSupport.swift
//  贪吃蛇
//
//  Created by Codex on 2026/3/8.
//

import Foundation

extension GameScene {
    var battleSetupItemCount: Int {
        FamilyMember.allCases.count + 3
    }

    func applyBattleSetupSelection() {
        let participantCount = FamilyMember.allCases.count
        if battleSetupSelection < participantCount {
            let member = FamilyMember.allCases[battleSetupSelection]
            settings.battleParticipants = battleConfig.toggled(member: member).participants
            persistSettings()
            audioController.playConfirm()
            return
        }

        switch battleSetupSelection - participantCount {
        case 0:
            settings.battleRoundCount = wrappedIndex(settings.battleRoundCount, count: 5) + 1
            persistSettings()
            audioController.playConfirm()
        case 1:
            startBattle()
        case 2:
            cancelBattleFlow()
        default:
            break
        }
    }

    func adjustBattleSetup(step: Int) {
        let participantCount = FamilyMember.allCases.count
        guard battleSetupSelection == participantCount else {
            return
        }
        settings.battleRoundCount = min(max(settings.battleRoundCount + step, 1), 5)
        persistSettings()
    }

    func startBattle() {
        let config = battleConfig
        guard config.isValid else {
            audioController.playNavigate()
            renderCurrent()
            return
        }

        let template = makeBattleRoundTemplate(for: config)
        battleSession = BattleSession(
            originalMember: settings.familyMember,
            config: config,
            currentRound: 1,
            currentParticipantIndex: 0,
            currentTemplate: template,
            results: []
        )
        prepareBattlePreview()
        audioController.playConfirm()
    }

    func prepareBattlePreview() {
        guard let battleSession else {
            return
        }

        selectFamilyMember(battleSession.currentMember, refreshPreview: false)
        let currentPlayMode = playMode(for: battleSession.currentMember)

        engine.restart(
            with: battleSession.currentTemplate.level,
            modifier: battleSession.currentTemplate.modifier,
            mission: battleSession.currentTemplate.mission,
            highScore: highScoreStore.highScore,
            hitPoints: settings.hitPoints(for: battleSession.currentMember),
            isSimpleModeEnabled: currentPlayMode.isSimpleModeEnabled,
            isManualStepModeEnabled: currentPlayMode.isManualStepEnabled,
            dailyChallenge: nil
        )
        engine.applySpeedPreset(settings.speedPreset)
        lastUpdateTime = 0
        timeAccumulator = 0
        boostButtonHeld = false
        boostCooldownRemaining = 0
        hasStartedCurrentRun = false
        mode = .ready
        syncAudioMode()
        renderCurrent()
        renderer.announceBattleTurn(
            memberName: displayName(for: battleSession.currentMember),
            memberSymbol: displaySymbol(for: battleSession.currentMember),
            modeTitle: currentPlayMode.title,
            accentColor: accent(for: battleSession.currentMember).color
        )
    }

    func advanceBattleAfterGameOver() {
        guard var battleSession else {
            return
        }

        battleSession.results.append(
            BattleRoundResult(
                member: battleSession.currentMember,
                round: battleSession.currentRound,
                score: engine.snapshot.score,
                length: engine.snapshot.snake.count,
                levelName: engine.snapshot.level.name,
                missionTitle: engine.snapshot.mission.title,
                missionCompleted: engine.snapshot.missionProgress.isCompleted
            )
        )

        let nextTemplate = makeBattleRoundTemplate(for: battleSession.config)
        if battleSession.advance(nextTemplate: nextTemplate) {
            self.battleSession = battleSession
            prepareBattlePreview()
            return
        }

        self.battleSession = battleSession
        selectFamilyMember(battleSession.originalMember, refreshPreview: false)
        mode = .battleSummary
        syncAudioMode()
    }

    func cancelBattleFlow() {
        if let originalMember = battleSession?.originalMember {
            selectFamilyMember(originalMember, refreshPreview: false)
        }
        battleSession = nil
        preparePreview()
        mode = .mainMenu
        audioController.playConfirm()
        syncAudioMode()
        renderCurrent()
    }

    private func makeBattleRoundTemplate(for config: BattleConfig) -> BattleRoundTemplate {
        let usesSimpleMode = config.participants.allSatisfy { playMode(for: $0).isSimpleModeEnabled }
        let level = levelFactory.randomLevel(isSimpleModeEnabled: usesSimpleMode)
        let modifier = runContentFactory.randomModifier(isSimpleModeEnabled: usesSimpleMode)
        return BattleRoundTemplate(
            level: level,
            modifier: modifier,
            mission: runContentFactory.randomMission(
                for: level,
                modifier: modifier,
                isSimpleModeEnabled: usesSimpleMode,
                unlockedRewards: unlockedRewardIDs
            )
        )
    }
}
