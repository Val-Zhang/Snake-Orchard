//
//  GameScene.swift
//  贪吃蛇
//
//  Created by zhangwang on 2026/3/6.
//

import AppKit
import SpriteKit

final class GameScene: SKScene {
    static let leaderboardDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter
    }()

    let levelFactory = LevelFactory()
    let runContentFactory = RunContentFactory()
    private let inputController = GameInputController()
    private let gameControllerInputManager = GameControllerInputManager()
    let renderer = GameRenderer()
    let highScoreStore = HighScoreStore()
    private let achievementStore = AchievementStore()
    private let codexStore = CollectionCodexStore()
    private let dailyChallengeStore = DailyChallengeStore()
    let settingsStore = GameSettingsStore()
    private let rewardUnlockStore = RewardUnlockStore()
    private let runHistoryStore = RunHistoryStore()
    let audioController = GameAudioController()

    var engine = SnakeGameEngine(
        level: LevelDefinition(name: "初始化", columns: 20, rows: 14, tickDuration: 0.18, obstacles: [], dynamicMechanic: nil, hasCollapsingTiles: false)
    )
    var lastUpdateTime: TimeInterval = 0
    var timeAccumulator: TimeInterval = 0
    private var sceneReady = false
    var mode: SceneMode = .gameSelection
    var settings = GameSettings.default
    var gameSelectionIndex = 0
    var gameSelectionSection = 0
    var gameSelectionRoleIndex = 0
    var snakeModeSelection = 0
    var mainMenuSelection = 0
    var battleSetupSelection = 0
    var settingsSelection = 0
    var gameOverSelection = 0
    var achievementSelection = 0
    var familyOverviewSelection = 0
    var familyDetailSelection = 0
    var familyDetailMember: FamilyMember?
    var leaderboardScopeSelection = 0
    var codexSectionSelection = 0
    var codexItemSelection = 0
    var boostButtonHeld = false
    var boostCooldownRemaining: TimeInterval = 0
    private var isPointingCursorActive = false
    var hasStartedCurrentRun = false
    var lastRunPlacement: RunLeaderboardPlacement?
    var lastPersonalBestMember: FamilyMember?
    var battleSession: BattleSession?
    var characterSelectionFlow: CharacterSelectionFlow = .manageProfiles

    override func didMove(to view: SKView) {
        guard !sceneReady else {
            return
        }

        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        settings = normalized(settingsStore.settings)
        settingsStore.settings = settings
        audioController.apply(settings: settings)
        engine.applySpeedPreset(settings.speedPreset)
        gameControllerInputManager.start()
        renderer.attach(to: self)
        sceneReady = true
        syncRewardUnlocks(playEffects: false)
        preparePreview()
        gameSelectionRoleIndex = FamilyMember.allCases.firstIndex(of: settings.familyMember) ?? 0
        mode = .gameSelection
        syncAudioMode()
        renderCurrent()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        guard sceneReady else {
            return
        }
        renderCurrent()
    }

    override func willMove(from view: SKView) {
        super.willMove(from: view)
        gameControllerInputManager.stop()
        audioController.stopAll()
        updateCursorStyle(isInteractive: false)
    }

    override func keyDown(with event: NSEvent) {
        guard let action = inputController.action(for: event, isPlaying: mode == .playing) else {
            return
        }
        handleInputAction(action)
    }

    override func keyUp(with event: NSEvent) {
        guard let action = inputController.keyUpAction(for: event, isPlaying: mode == .playing) else {
            return
        }
        handleInputAction(action)
    }

    override func mouseMoved(with event: NSEvent) {
        guard sceneReady else {
            return
        }
        let location = event.location(in: self)
        let isInteractive = renderer.overlayItemIndex(at: location) != nil || renderer.overlayTabIndex(at: location) != nil
        updateCursorStyle(isInteractive: isInteractive)
        if renderer.updateOverlayHover(at: location) {
            renderCurrent()
        }
    }

    override func mouseDown(with event: NSEvent) {
        guard sceneReady else {
            return
        }
        let location = event.location(in: self)
        if let tabIndex = renderer.overlayTabIndex(at: location) {
            handleOverlayTabClick(tabIndex)
            return
        }
        if let index = renderer.overlayItemIndex(at: location) {
            handleOverlayItemClick(index)
            return
        }
        handleOverlayBlankClick(at: location)
    }

    override func update(_ currentTime: TimeInterval) {
        gameControllerInputManager.drainActions().forEach(handleInputAction)

        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        }

        let delta = currentTime - lastUpdateTime
        lastUpdateTime = currentTime

        let clampedDelta = min(delta, 0.25)

        guard mode == .playing, !engine.isGameOver else {
            return
        }

        boostCooldownRemaining = max(0, boostCooldownRemaining - clampedDelta)
        if engine.snapshot.isManualStepModeEnabled {
            if boostButtonHeld {
                boostButtonHeld = false
            }
            return
        }

        var needsRender = false
        if boostButtonHeld, tryActivateBoost() {
            needsRender = true
        }

        timeAccumulator += clampedDelta
        var advanced = false
        var stepCount = 0
        let maxStepsPerFrame = 3

        while timeAccumulator >= engine.tickDuration, stepCount < maxStepsPerFrame {
            timeAccumulator -= engine.tickDuration
            let events = engine.advance()
            handle(events: events)
            advanced = true
            stepCount += 1

            if mode != .playing || engine.isGameOver {
                break
            }
        }

        if stepCount == maxStepsPerFrame {
            timeAccumulator = 0
        }

        if advanced || needsRender {
            renderCurrent()
        }
    }

    func preparePreview() {
        preparePreview(challenge: nil)
    }

    func preparePreview(challenge: DailyChallengeDefinition?) {
        let level: LevelDefinition
        let modifier: RunModifier
        let mission: MissionDefinition

        if let challenge {
            level = challenge.level
            modifier = challenge.modifier
            mission = challenge.mission
        } else {
            level = levelFactory.randomLevel(isSimpleModeEnabled: settings.simpleModeEnabled)
            modifier = runContentFactory.randomModifier(isSimpleModeEnabled: settings.simpleModeEnabled)
            mission = runContentFactory.randomMission(
                for: level,
                modifier: modifier,
                isSimpleModeEnabled: settings.simpleModeEnabled,
                unlockedRewards: unlockedRewardIDs
            )
        }

        engine.restart(
            with: level,
            modifier: modifier,
            mission: mission,
            highScore: highScoreStore.highScore,
            hitPoints: settings.hitPoints(for: settings.familyMember),
            isSimpleModeEnabled: challenge == nil ? settings.simpleModeEnabled : false,
            isManualStepModeEnabled: challenge == nil ? (settings.simpleModeEnabled && settings.manualStepModeEnabled) : false,
            dailyChallenge: challenge
        )
        engine.applySpeedPreset(settings.speedPreset)
        lastUpdateTime = 0
        timeAccumulator = 0
        boostButtonHeld = false
        boostCooldownRemaining = 0
        hasStartedCurrentRun = false
    }

    func handle(events: [GameEvent]) {
        for event in events {
            switch event {
            case .ateFruit(let fruit, _, _):
                audioController.playFruit(effect: fruit.effect)
                renderer.play(event)
            case .codexDiscovered:
                audioController.playConfirm()
                renderer.play(event)
            case .comboAdvanced:
                audioController.playConfirm()
                renderer.play(event)
            case .fruitExpired:
                audioController.playNavigate()
                renderer.play(event)
            case .bombTriggered, .floorCollapsed:
                audioController.playPause()
                renderer.play(event)
            case .boostActivated:
                audioController.playConfirm()
                renderer.play(event)
            case .safetyBrake:
                audioController.playPause()
                renderer.play(event)
            case .gameOver:
                boostButtonHeld = false
                hasStartedCurrentRun = false
                let recordedMember = battleSession?.currentMember ?? settings.familyMember
                let placement = runHistoryStore.recordRun(snapshot: engine.snapshot, familyMember: recordedMember)
                lastRunPlacement = placement
                lastPersonalBestMember = placement.personalBestImproved ? recordedMember : nil
                audioController.playGameOver()
                renderer.play(event)
                if placement.totalRank != nil || placement.dailyRank != nil || placement.personalBestImproved {
                    renderer.play(.leaderboardRanked(placement))
                }
                if battleSession != nil {
                    advanceBattleAfterGameOver()
                } else {
                    mode = .gameOver
                    gameOverSelection = 0
                    syncAudioMode()
                }
            case .highScoreUpdated(let newScore):
                if highScoreStore.saveIfNeeded(score: newScore) {
                    renderer.play(event)
                }
            case .leaderboardRanked:
                renderer.play(event)
            case .missionCompleted:
                renderer.play(event)
                if let challenge = engine.snapshot.dailyChallenge,
                   dailyChallengeStore.markCompleted(challenge) {
                    renderer.play(.dailyChallengeCompleted(challenge))
                }
            case .achievementUnlocked, .themeUnlocked:
                renderer.play(event)
            case .dailyChallengeCompleted, .rewardUnlocked:
                renderer.play(event)
            }
        }

        recordCurrentCodexDiscovery().forEach { renderer.play(.codexDiscovered($0)) }
        achievementStore.updateProgress(snapshot: engine.snapshot, runStats: engine.runStats)

        let unlockedAchievements = achievementStore.unlock(
            AchievementCatalog.unlockedAchievements(snapshot: engine.snapshot, runStats: engine.runStats)
        )
        unlockedAchievements.forEach { achievement in
            renderer.play(.achievementUnlocked(achievement))
            VisualTheme.allCases
                .filter { $0.unlockAchievementID == achievement.id }
                .forEach { renderer.play(.themeUnlocked($0)) }
        }
        syncRewardUnlocks(playEffects: true)
    }

    func applyMainMenuSelection() {
        audioController.playConfirm()
        switch MainMenuOption.allCases[mainMenuSelection] {
        case .resume:
            guard hasResumableRun else {
                return
            }
            mode = .playing
        case .start:
            beginCurrentRun()
        case .gameCollection:
            gameSelectionIndex = 0
            gameSelectionSection = 0
            gameSelectionRoleIndex = FamilyMember.allCases.firstIndex(of: settings.familyMember) ?? 0
            mode = .gameSelection
        case .dailyChallenge:
            battleSession = nil
            preparePreview(challenge: todayDailyChallenge)
            beginCurrentRun()
        case .reroll:
            preparePreview()
            mode = .mainMenu
        case .achievements:
            achievementSelection = 0
            mode = .achievements
        case .familyOverview:
            familyOverviewSelection = FamilyMember.allCases.firstIndex(of: settings.familyMember) ?? 0
            characterSelectionFlow = .manageProfiles
            mode = .familyOverview
        case .leaderboard:
            leaderboardScopeSelection = 0
            mode = .leaderboard
        case .codex:
            codexSectionSelection = 0
            codexItemSelection = 0
            mode = .codex
        case .help:
            mode = .help
        case .settings:
            settingsSelection = 0
            mode = .settings
        case .quit:
            guard confirmReturnToHome() else {
                renderCurrent()
                return
            }
            mode = .gameSelection
            gameSelectionSection = 0
            gameSelectionRoleIndex = FamilyMember.allCases.firstIndex(of: settings.familyMember) ?? 0
        }
        syncAudioMode()
    }

    func confirmReturnToHome() -> Bool {
        confirmAction(
            title: "确认返回主页",
            message: "会退出当前贪吃蛇菜单，回到游戏主页。",
            confirmTitle: "返回主页"
        )
    }

    func confirmExitApplication() -> Bool {
        confirmAction(
            title: "确认退出应用",
            message: "退出后本次窗口会关闭。",
            confirmTitle: "退出应用"
        )
    }

    private func confirmAction(title: String, message: String, confirmTitle: String) -> Bool {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: confirmTitle)
        alert.addButton(withTitle: "取消")

        let response: NSApplication.ModalResponse
        if let window = view?.window {
            response = alert.runModal()
            window.makeFirstResponder(nil)
        } else {
            response = alert.runModal()
        }
        return response == .alertFirstButtonReturn
    }

    private func applyFamilyOverviewSelection() {
        let members = FamilyMember.allCases
        guard members.indices.contains(familyOverviewSelection) else {
            return
        }
        selectFamilyMember(members[familyOverviewSelection])
        audioController.playConfirm()
        renderCurrent()
    }

    func openFamilyDetail(for member: FamilyMember) {
        familyDetailMember = member
        familyDetailSelection = 0
        mode = .familyDetail
        audioController.playConfirm()
        syncAudioMode()
    }

    func applyFamilyDetailSelection() {
        guard let member = familyDetailMember else {
            return
        }
        switch familyDetailSelection {
        case 0:
            selectFamilyMember(member)
            audioController.playConfirm()
        case 1:
            renameFamilyMember(member)
        case 2:
            selectFamilyMember(member, refreshPreview: false)
            resetCurrentFamilyMemberAppearance()
        default:
            break
        }
        renderCurrent()
    }

    func applyGameSelection() {
        let option = GameCollectionOption.allCases[wrappedIndex(gameSelectionIndex, count: GameCollectionOption.allCases.count)]
        switch option {
        case .snake:
            snakeModeSelection = 0
            mode = .snakeModeSelection
        case .brickBreaker:
            mode = .gameConstruction
        }
        audioController.playConfirm()
        syncAudioMode()
        renderCurrent()
    }

    func applySnakeModeSelection() {
        let option = SnakeEntryModeOption.allCases[wrappedIndex(snakeModeSelection, count: SnakeEntryModeOption.allCases.count)]
        switch option {
        case .singlePlayer:
            settings.battleModeEnabled = false
            persistSettings()
            mainMenuSelection = hasResumableRun ? 0 : 1
            mode = .mainMenu
        case .battle:
            settings.battleModeEnabled = true
            persistSettings()
            battleSetupSelection = 0
            mode = .battleSetup
        }
        audioController.playConfirm()
        syncAudioMode()
        renderCurrent()
    }

    func applyGameSelectionRole() {
        let members = FamilyMember.allCases
        if members.indices.contains(gameSelectionRoleIndex) {
            selectFamilyMember(members[gameSelectionRoleIndex])
            audioController.playConfirm()
            syncAudioMode()
            renderCurrent()
            return
        }
        if gameSelectionRoleIndex == members.count {
            openFamilyDetail(for: settings.familyMember)
        }
    }

    func applyCharacterSelectionLaunch() {
        let members = FamilyMember.allCases
        guard members.indices.contains(familyOverviewSelection) else {
            return
        }
        selectFamilyMember(members[familyOverviewSelection])
        mainMenuSelection = hasResumableRun ? 0 : 1
        characterSelectionFlow = .manageProfiles
        mode = .mainMenu
        audioController.playConfirm()
        syncAudioMode()
        renderCurrent()
    }

    func familyDetailItems(for member: FamilyMember, recentRuns: [RunLeaderboardEntry]? = nil) -> [OverlayMenuItem] {
        let recentRuns = recentRuns ?? runHistoryStore.recentEntries(for: member)
        let bestEntry = recentRuns.max { lhs, rhs in
            if lhs.score != rhs.score {
                return lhs.score < rhs.score
            }
            if lhs.length != rhs.length {
                return lhs.length < rhs.length
            }
            return lhs.timestamp < rhs.timestamp
        }
        return GameScenePresentationBuilder.familyDetailItems(
            member: member,
            currentMember: settings.familyMember,
            displayName: displayName(for: member),
            memberTitle: member.title,
            accentColor: accent(for: member).color,
            recentRuns: recentRuns,
            bestEntry: bestEntry
        )
    }

    private func familyDetailSubtitle(for member: FamilyMember, recentRuns: [RunLeaderboardEntry]) -> String {
        GameScenePresentationBuilder.familyDetailSubtitle(
            member: member,
            currentMember: settings.familyMember,
            avatarTitle: settings.avatar(for: member).title,
            accentTitle: accent(for: member).title,
            familySummary: familyLeaderboardEntries.first(where: { $0.member == member })
        )
    }

    func applyGameOverSelection() {
        audioController.playConfirm()
        switch GameOverOption.allCases[gameOverSelection] {
        case .replay:
            if let challenge = engine.snapshot.dailyChallenge {
                preparePreview(challenge: challenge)
            } else {
                preparePreview()
            }
            beginCurrentRun()
        case .mainMenu:
            preparePreview()
            mode = .mainMenu
        case .achievements:
            achievementSelection = 0
            mode = .achievements
        }
        syncAudioMode()
    }

    func persistSettings() {
        settings = normalized(settings)
        settingsStore.settings = settings
        audioController.apply(settings: settings)
        engine.applySpeedPreset(settings.speedPreset)
        syncAudioMode()
    }

    func renderCurrent() {
        if mode == .mainMenu, !hasResumableRun, mainMenuSelection == 0 {
            mainMenuSelection = 1
        }
        let selectedGame = GameCollectionOption.allCases[wrappedIndex(gameSelectionIndex, count: GameCollectionOption.allCases.count)]
        renderer.updateHomePresentation(selectedGame: selectedGame, accent: accent(for: settings.familyMember))
        if mode == .gameSelection || mode == .gameConstruction {
            backgroundColor = SKColor(calibratedRed: 0.06, green: 0.07, blue: 0.09, alpha: 1.0)
        } else {
            backgroundColor = renderer.backgroundColor(for: engine.snapshot.level, theme: settings.visualTheme)
        }
        renderer.updateLayout(sceneSize: size, level: engine.snapshot.level, theme: settings.visualTheme)
        renderer.render(
            snapshot: engine.snapshot,
            boostStatus: boostStatus,
            mode: mode,
            progress: progressSummary,
            overlayMenu: overlayMenuState
        )
    }

    func updateCursorStyle(isInteractive: Bool) {
        guard isPointingCursorActive != isInteractive else {
            return
        }
        isPointingCursorActive = isInteractive
        if isInteractive {
            NSCursor.pointingHand.set()
        } else {
            NSCursor.arrow.set()
        }
    }

    func syncAudioMode() {
        let audioMode: SceneAudioMode
        switch mode {
        case .gameSelection, .gameConstruction, .snakeModeSelection, .mainMenu, .battleSetup, .battleSummary, .familyOverview, .familyDetail, .achievements, .achievementDetail, .leaderboard, .codex, .codexDetail, .help, .settings, .ready:
            audioMode = .menu
        case .playing:
            audioMode = .gameplay
        case .paused, .gameOver:
            audioMode = .silent
        }
        audioController.updateMusic(for: audioMode)
    }

    private var overlayMenuState: OverlayMenuState? {
        switch mode {
        case .gameSelection:
            return GameSceneOverlayMenuFactory.gameSelection(
                currentMember: settings.familyMember,
                currentCharacterName: displayName(for: settings.familyMember),
                currentCharacterSymbol: displaySymbol(for: settings.familyMember),
                currentCharacterAccent: accent(for: settings.familyMember),
                currentCharacterAvatar: settings.avatar(for: settings.familyMember),
                currentCharacterPlayMode: playMode(for: settings.familyMember),
                displayName: displayName(for:),
                displaySymbol: displaySymbol(for:),
                avatar: settings.avatar(for:),
                accent: accent(for:),
                selectedIndex: gameSelectionSection == 0
                    ? gameSelectionIndex
                    : GameCollectionOption.allCases.count + gameSelectionRoleIndex
            )
        case .gameConstruction:
            return GameSceneOverlayMenuFactory.gameConstruction()
        case .snakeModeSelection:
            return GameSceneOverlayMenuFactory.snakeModeSelection(selectedIndex: snakeModeSelection)
        case .mainMenu:
            let dailyChallenge = todayDailyChallenge
            return GameSceneOverlayMenuFactory.mainMenu(
                settings: settings,
                currentMemberName: displayName(for: settings.familyMember),
                currentMemberSymbol: displaySymbol(for: settings.familyMember),
                currentMemberAvatarSymbol: settings.avatar(for: settings.familyMember).symbol,
                currentMemberAccent: accent(for: settings.familyMember),
                dailyChallenge: dailyChallenge,
                dailyCompleted: dailyChallengeStore.isCompleted(dailyChallenge),
                rewardSummary: unlockedRewardDefinitions.isEmpty
                    ? "尚未解锁奖励内容"
                    : unlockedRewardDefinitions.map { "\($0.symbol)\($0.title)" }.joined(separator: " · "),
                recentDiscoveries: recentCodexEntries.map { "\($0.symbol)\($0.title)" }.joined(separator: " · "),
                mainMenuSelection: mainMenuSelection,
                hasResumableRun: hasResumableRun,
                leaderboardSubtitle: leaderboardSubtitle,
                leaderboardDetail: leaderboardDetail,
                leaderboardBadge: leaderboardBadge,
                leaderboardEntriesEmpty: leaderboardEntries.isEmpty,
                codexDiscoveredCount: codexStore.totalDiscoveredCount,
                codexTotalCount: CodexCatalog.all(levelNames: codexLevelNames).count
            )
        case .battleSetup:
            return GameSceneOverlayMenuFactory.battleSetup(
                config: battleConfig,
                selectedIndex: battleSetupSelection,
                displayName: { self.displayName(for: $0) },
                displaySymbol: { self.displaySymbol(for: $0) },
                playMode: { self.playMode(for: $0) },
                accent: { self.accent(for: $0) },
                familyEntries: familyLeaderboardEntries
            )
        case .battleSummary:
            guard let battleSession else {
                return nil
            }
            return GameSceneOverlayMenuFactory.battleSummary(
                summary: battleSummary,
                results: battleSession.results,
                displayName: { self.displayName(for: $0) },
                displaySymbol: { self.displaySymbol(for: $0) },
                accent: { self.accent(for: $0) }
            )
        case .familyOverview:
            return GameSceneOverlayMenuFactory.familyOverview(
                currentMember: settings.familyMember,
                familyOverviewSelection: familyOverviewSelection,
                selectionFlow: characterSelectionFlow,
                familyLeaderboardEntries: familyLeaderboardEntries,
                displayName: { self.displayName(for: $0) },
                displaySymbol: { self.displaySymbol(for: $0) },
                avatar: { self.settings.avatar(for: $0) },
                accent: { self.accent(for: $0) }
            )
        case .familyDetail:
            guard let member = familyDetailMember else {
                return nil
            }
            let recentRuns = runHistoryStore.recentEntries(for: member)
            let items = familyDetailItems(for: member, recentRuns: recentRuns)
            familyDetailSelection = wrappedIndex(familyDetailSelection, count: items.count)
            return GameSceneOverlayMenuFactory.familyDetail(
                member: member,
                items: items,
                subtitle: familyDetailSubtitle(for: member, recentRuns: recentRuns),
                displayName: { self.displayName(for: $0) },
                displaySymbol: { self.displaySymbol(for: $0) },
                selectedIndex: familyDetailSelection
            )
        case .leaderboard:
            let scope = LeaderboardScope.allCases[leaderboardScopeSelection]
            return GameSceneOverlayMenuFactory.leaderboard(
                scope: scope,
                familyEntries: familyLeaderboardEntries,
                leaderboardEntries: leaderboardEntries(for: scope),
                headline: leaderboardHeadline(for: scope),
                displayName: { self.displayName(for: $0) },
                displaySymbol: { self.displaySymbol(for: $0) },
                accent: { self.accent(for: $0) },
                familyDetail: { self.familyLeaderboardDetail(for: $0, rank: $1) },
                familyBadge: { self.familyLeaderboardBadge(for: $0, rank: $1) },
                entryDetail: { self.leaderboardDetail(for: $0, rank: $1) },
                entryBadge: { self.leaderboardBadge(for: $0) },
                rankIcon: { self.rankIcon(for: $0) },
                formattedDate: { self.formattedLeaderboardDate($0) }
            )
        case .achievements:
            achievementSelection = wrappedIndex(achievementSelection, count: AchievementCatalog.all.count)
            return GameSceneOverlayMenuFactory.achievements(
                selectedIndex: achievementSelection,
                unlockedCount: achievementStore.unlockedCount,
                totalCount: AchievementCatalog.all.count,
                items: AchievementCatalog.all.map { achievement in
                    let progress = achievementStore.progress(for: achievement)
                    let unlocked = progress.isUnlocked
                    return OverlayMenuItem(
                        title: achievement.title,
                        subtitle: nil,
                        detail: achievement.detail,
                        icon: achievement.symbol,
                        badge: unlocked ? "已解锁 · \(achievement.category.title)" : progress.summaryText,
                        isDimmed: !unlocked
                    )
                }
            )
        case .achievementDetail:
            let achievement = AchievementCatalog.all[wrappedIndex(achievementSelection, count: AchievementCatalog.all.count)]
            let progress = achievementStore.progress(for: achievement)
            let themeReward = VisualTheme.allCases.first(where: { $0.unlockAchievementID == achievement.id })
            return GameSceneOverlayMenuFactory.achievementDetail(
                achievement: achievement,
                progress: progress,
                rewardText: themeReward.map { "\($0.symbol) \($0.title)" } ?? "暂无专属皮肤奖励"
            )
        case .codex:
            let section = CodexSection.allCases[codexSectionSelection]
            let entries = CodexCatalog.entries(for: section, levelNames: codexLevelNames)
            let discoveredIDs = codexStore.discoveredIDs(for: section)
            return GameSceneOverlayMenuFactory.codex(
                section: section,
                discoveredCount: discoveredIDs.count,
                totalCount: entries.count,
                completionText: codexCompletionText(for: section, total: entries.count, current: discoveredIDs.count),
                detail: recentCodexEntries.isEmpty
                    ? "悬停条目查看简介"
                    : "悬停条目查看简介 · 最近新发现：\(recentCodexEntries.map { "\($0.symbol)\($0.title)" }.joined(separator: " · "))",
                items: entries.map { entry in
                    let discovered = discoveredIDs.contains(entry.id)
                    return OverlayMenuItem(
                        title: entry.title,
                        subtitle: nil,
                        detail: discovered ? entry.detail : "继续游玩来发现这条记录",
                        icon: entry.symbol,
                        badge: discovered ? "已发现" : "未发现",
                        isDimmed: !discovered
                    )
                },
                selectedIndex: codexItemSelection
            )
        case .codexDetail:
            let section = CodexSection.allCases[codexSectionSelection]
            let entry = selectedCodexEntry
            let discovered = entry.map { codexStore.discoveredIDs(for: section).contains($0.id) } ?? false
            return GameSceneOverlayMenuFactory.codexDetail(
                section: section,
                discovered: discovered,
                entry: entry,
                unlockHint: codexUnlockHint(for: entry, discovered: discovered)
            )
        case .help:
            return GameSceneOverlayMenuFactory.help(simpleModeEnabled: settings.simpleModeEnabled)
        case .settings:
            let currentPlayMode = playMode(for: settings.familyMember)
            return GameSceneOverlayMenuFactory.settings(
                settings: settings,
                items: SettingsOption.allCases.map { option in
                    switch option {
                    case .sound:
                        return OverlayMenuItem(title: option.title, subtitle: settings.soundEnabled ? "开启" : "关闭", detail: settingsDescription(for: option), icon: "♪", badge: nil, isDimmed: false)
                    case .music:
                        return OverlayMenuItem(title: option.title, subtitle: settings.musicEnabled ? "开启" : "关闭", detail: settingsDescription(for: option), icon: "♫", badge: nil, isDimmed: false)
                    case .simpleMode:
                        return OverlayMenuItem(
                            title: option.title,
                            subtitle: currentPlayMode.isSimpleModeEnabled ? currentPlayMode.title : "标准",
                            detail: settingsDescription(for: option),
                            icon: "☺",
                            badge: currentPlayMode.isSimpleModeEnabled ? "绑定当前成员" : nil,
                            isDimmed: false
                        )
                    case .manualStepMode:
                        return OverlayMenuItem(
                            title: option.title,
                            subtitle: currentPlayMode.isSimpleModeEnabled
                                ? (currentPlayMode.isManualStepEnabled ? "按键一步一步走" : "自动前进")
                                : "仅儿童模式生效",
                            detail: settingsDescription(for: option),
                            icon: "👣",
                            badge: currentPlayMode.isManualStepEnabled ? "已开启" : nil,
                            isDimmed: !currentPlayMode.isSimpleModeEnabled
                        )
                    case .speed:
                        return OverlayMenuItem(title: option.title, subtitle: settings.speedPreset.title, detail: settingsDescription(for: option), icon: "➤", badge: nil, isDimmed: false)
                    case .familyMember:
                        return OverlayMenuItem(
                            title: option.title,
                            subtitle: "\(displaySymbol(for: settings.familyMember)) \(displayName(for: settings.familyMember))",
                            detail: settingsDescription(for: option),
                            icon: "👨‍👩‍👧‍👦",
                            badge: currentPlayMode.title,
                            accentColor: accent(for: settings.familyMember).color,
                            isDimmed: false
                        )
                    case .familyHitPoints:
                        return OverlayMenuItem(
                            title: option.title,
                            subtitle: settings.hitPointHearts(for: settings.familyMember),
                            detail: settingsDescription(for: option),
                            icon: "♥",
                            badge: "当前成员",
                            accentColor: accent(for: settings.familyMember).color,
                            isDimmed: false
                        )
                    case .characterDefinition:
                        return OverlayMenuItem(
                            title: option.title,
                            subtitle: "\(displaySymbol(for: settings.familyMember)) \(displayName(for: settings.familyMember))",
                            detail: settingsDescription(for: option),
                            icon: "🪪",
                            badge: "入口",
                            accentColor: accent(for: settings.familyMember).color,
                            isDimmed: false
                        )
                    case .familyAvatar:
                        let avatar = settings.avatar(for: settings.familyMember)
                        return OverlayMenuItem(
                            title: option.title,
                            subtitle: "\(avatar.symbol) \(avatar.title)",
                            detail: settingsDescription(for: option),
                            icon: "🙂",
                            badge: "当前成员",
                            accentColor: accent(for: settings.familyMember).color,
                            isDimmed: false
                        )
                    case .familyAccent:
                        let familyAccent = accent(for: settings.familyMember)
                        return OverlayMenuItem(
                            title: option.title,
                            subtitle: "\(familyAccent.symbol) \(familyAccent.title)",
                            detail: settingsDescription(for: option),
                            icon: "▣",
                            badge: "边框色",
                            accentColor: familyAccent.color,
                            isDimmed: false
                        )
                    case .familyReset:
                        return OverlayMenuItem(
                            title: option.title,
                            subtitle: "只重置当前成员",
                            detail: settingsDescription(for: option),
                            icon: "↺",
                            badge: "昵称/头像/颜色",
                            accentColor: accent(for: settings.familyMember).color,
                            isDimmed: false
                        )
                    case .theme:
                        return OverlayMenuItem(
                            title: option.title,
                            subtitle: "\(settings.visualTheme.symbol) \(settings.visualTheme.title)",
                            detail: settingsDescription(for: option),
                            icon: "🎨",
                            badge: "\(unlockedThemes.count)/\(VisualTheme.allCases.count)",
                            isDimmed: false
                        )
                    case .back:
                        return OverlayMenuItem(title: option.title, subtitle: nil, detail: settingsDescription(for: option), icon: "⌂", badge: nil, isDimmed: false)
                    }
                },
                selectedIndex: settingsSelection
            )
        case .gameOver:
            return GameSceneOverlayMenuFactory.gameOver(
                snapshot: engine.snapshot,
                personalBestText: lastRunPlacement?.personalBestImproved == true ? " · 刷新个人最佳" : "",
                gapText: personalBestGapText.map { " · \($0)" } ?? "",
                selectedIndex: gameOverSelection,
                items: GameOverOption.allCases.map {
                    OverlayMenuItem(title: $0.title, subtitle: nil, detail: gameOverDetail(for: $0), icon: $0.symbol, badge: nil, isDimmed: false)
                }
            )
        default:
            return nil
        }
    }

    func wrappedIndex(_ value: Int, count: Int) -> Int {
        guard count > 0 else {
            return 0
        }
        let remainder = value % count
        return remainder >= 0 ? remainder : remainder + count
    }

    private var progressSummary: GameProgressSummary {
        GameProgressSummary(
            unlockedAchievements: achievementStore.unlockedCount,
            totalAchievements: AchievementCatalog.all.count,
            unlockedRewards: unlockedRewardDefinitions.count,
            totalRewards: RewardCatalog.all.count,
            battleTitle: battleSession?.progressTitle,
            battleDetail: battleSession?.progressDetail
        )
    }

    private var codexLevelNames: [String] {
        levelFactory.allLevels(isSimpleModeEnabled: false).map(\.name)
    }

    private var recentCodexEntries: [CodexEntryDefinition] {
        codexStore.recentDiscoveryIDs.compactMap { codexEntryLookup[$0] }
    }

    var unlockedThemes: [VisualTheme] {
        ThemeCatalog.unlockedThemes(for: achievementStore.unlockedIDs)
    }

    private var unlockedRewardDefinitions: [RewardUnlockDefinition] {
        RewardCatalog.all.filter { rewardUnlockStore.unlockedIDs.contains($0.id) }
    }

    var unlockedRewardIDs: Set<RewardUnlockID> {
        rewardUnlockStore.unlockedIDs
    }

    private var hasResumableRun: Bool {
        hasStartedCurrentRun && !engine.isGameOver
    }

    var battleConfig: BattleConfig {
        BattleConfig(
            participants: settings.battleParticipants,
            roundCount: settings.battleRoundCount
        )
    }

    private var battleSummary: BattleSummary {
        BattleSummary(config: battleSession?.config ?? battleConfig, results: battleSession?.results ?? [])
    }

    private var todayDailyChallenge: DailyChallengeDefinition {
        runContentFactory.dailyChallenge(
            levelFactory: levelFactory,
            unlockedRewards: unlockedRewardIDs
        )
    }

    var codexEntriesForCurrentSection: [CodexEntryDefinition] {
        CodexCatalog.entries(for: CodexSection.allCases[codexSectionSelection], levelNames: codexLevelNames)
    }

    private var selectedCodexEntry: CodexEntryDefinition? {
        let entries = codexEntriesForCurrentSection
        guard !entries.isEmpty else {
            return nil
        }
        return entries[wrappedIndex(codexItemSelection, count: entries.count)]
    }

    private var codexEntryLookup: [String: CodexEntryDefinition] {
        Dictionary(uniqueKeysWithValues: CodexCatalog.all(levelNames: codexLevelNames).map { ($0.id, $0) })
    }

    func clampCodexItemSelection() {
        let count = codexEntriesForCurrentSection.count
        codexItemSelection = count > 0 ? wrappedIndex(codexItemSelection, count: count) : 0
    }

    private var boostStatus: BoostStatusSnapshot {
        let canUseBoost = engine.canActivateBoost
        let hasEnoughLength = engine.snapshot.snake.count > 3
        let cooldown = max(0, boostCooldownRemaining)
        return BoostStatusSnapshot(
            isReady: canUseBoost && cooldown <= 0.01,
            chargeProgress: canUseBoost ? min(1, max(0, 1 - cooldown / 5)) : 0,
            cooldownRemaining: cooldown,
            isHeld: boostButtonHeld,
            hasEnoughLength: hasEnoughLength
        )
    }

    func handleBoostPressed() {
        guard mode == .playing, engine.canActivateBoost else {
            return
        }
        boostButtonHeld = true
        if tryActivateBoost() {
            renderCurrent()
        }
    }

    private func tryActivateBoost() -> Bool {
        guard mode == .playing, !engine.isGameOver else {
            return false
        }
        guard boostCooldownRemaining <= 0.01 else {
            return false
        }
        let events = engine.activateBoost()
        guard !events.isEmpty else {
            return false
        }
        boostCooldownRemaining = 5
        handle(events: events)
        return true
    }

    func beginCurrentRun() {
        mode = .playing
        hasStartedCurrentRun = true
        lastRunPlacement = nil
        lastPersonalBestMember = nil
        recordCurrentCodexDiscovery().forEach { renderer.play(.codexDiscovered($0)) }
        renderCurrent()
    }

    private func recordCurrentCodexDiscovery() -> [CodexEntryDefinition] {
        var discoveredIDs = codexStore.record(level: engine.snapshot.level)
        if let fruit = engine.snapshot.fruit {
            discoveredIDs += codexStore.record(fruit: fruit)
        }
        return discoveredIDs.compactMap { codexEntryLookup[$0] }
    }

    private func codexCompletionText(for section: CodexSection, total: Int, current: Int) -> String {
        _ = section
        return GameScenePresentationBuilder.codexCompletionText(total: total, current: current)
    }

    private func codexUnlockHint(for entry: CodexEntryDefinition?, discovered: Bool) -> String {
        GameScenePresentationBuilder.codexUnlockHint(for: entry, discovered: discovered)
    }

    private func syncRewardUnlocks(playEffects: Bool) {
        let available = RewardCatalog.unlockedDefinitions(
            unlockedAchievementCount: achievementStore.unlockedCount,
            codexDiscoveredCount: codexStore.totalDiscoveredCount
        )
        let newlyUnlocked = rewardUnlockStore.syncUnlocked(available)
        guard playEffects else {
            return
        }
        newlyUnlocked.forEach { renderer.play(.rewardUnlocked($0)) }
    }

    private func settingsDescription(for option: SettingsOption) -> String {
        GameScenePresentationBuilder.settingsDescription(
            for: option,
            settings: settings,
            unlockedThemeCount: unlockedThemes.count,
            totalThemeCount: VisualTheme.allCases.count,
            currentMemberName: displayName(for: settings.familyMember),
            currentMemberSymbol: displaySymbol(for: settings.familyMember),
            currentAvatar: settings.avatar(for: settings.familyMember),
            currentAccent: accent(for: settings.familyMember)
        )
    }

    private func gameOverDetail(for option: GameOverOption) -> String {
        GameScenePresentationBuilder.gameOverDetail(
            for: option,
            placement: lastRunPlacement,
            currentScore: engine.snapshot.score
        )
    }

    private var leaderboardEntries: [RunLeaderboardEntry] {
        runHistoryStore.leaderboard
    }

    private func leaderboardEntries(for scope: LeaderboardScope) -> [RunLeaderboardEntry] {
        runHistoryStore.leaderboardEntries(for: scope)
    }

    var familyLeaderboardEntries: [FamilyLeaderboardEntry] {
        runHistoryStore.familyLeaderboard()
    }

    private var leaderboardBadge: String {
        leaderboardEntries.isEmpty ? "等待首局" : "Top \(leaderboardEntries.count)"
    }

    private var leaderboardSubtitle: String {
        guard let best = leaderboardEntries.first else {
            return "本机前 10 名"
        }
        return "最高 \(best.score) 分"
    }

    private var leaderboardDetail: String {
        guard let best = leaderboardEntries.first else {
            return "本机前 10 名成绩会显示在这里，先开始几局再回来看看。"
        }
        return "当前榜首 \(best.score) 分，长度 \(best.length)，来自 \(best.levelName)。"
    }

    private var personalBestGapText: String? {
        guard lastRunPlacement?.personalBestImproved != true,
              let previousBestScore = lastRunPlacement?.previousBestScore else {
            return nil
        }
        let scoreGap = max(0, previousBestScore - engine.snapshot.score)
        if scoreGap == 0 {
            return "已追平最高分"
        }
        return "离个人最佳差 \(scoreGap) 分"
    }

    private func leaderboardHeadline(for scope: LeaderboardScope) -> String {
        GameScenePresentationBuilder.leaderboardHeadline(
            for: scope,
            leaderboardEntries: leaderboardEntries(for: scope),
            familyEntries: familyLeaderboardEntries,
            displayName: { self.displayName(for: $0) },
            displaySymbol: { self.displaySymbol(for: $0) }
        )
    }

    private func leaderboardDetail(for entry: RunLeaderboardEntry, rank: Int) -> String {
        GameScenePresentationBuilder.leaderboardDetail(for: entry, rank: rank)
    }

    private func leaderboardBadge(for entry: RunLeaderboardEntry) -> String {
        if entry.isDailyChallenge {
            return "每日"
        }
        if entry.isSimpleModeEnabled {
            return "极简"
        }
        return entry.missionCompleted ? "达成任务" : "进行中"
    }

    private func familyLeaderboardDetail(for entry: FamilyLeaderboardEntry, rank: Int) -> String {
        GameScenePresentationBuilder.familyLeaderboardDetail(
            for: entry,
            rank: rank,
            lastPersonalBestMember: lastPersonalBestMember,
            displayName: { self.displayName(for: $0) }
        )
    }

    private func familyLeaderboardBadge(for entry: FamilyLeaderboardEntry, rank: Int) -> String {
        GameScenePresentationBuilder.familyLeaderboardBadge(
            for: entry,
            rank: rank,
            currentMember: settings.familyMember,
            lastPersonalBestMember: lastPersonalBestMember,
            accentSymbol: accent(for: entry.member).symbol
        )
    }

    private func rankIcon(for index: Int) -> String {
        GameScenePresentationBuilder.rankIcon(for: index)
    }

    private func formattedLeaderboardDate(_ timestamp: TimeInterval) -> String {
        GameScenePresentationBuilder.formattedDate(timestamp, formatter: Self.leaderboardDateFormatter)
    }
}
