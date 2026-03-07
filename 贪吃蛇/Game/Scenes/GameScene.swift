//
//  GameScene.swift
//  贪吃蛇
//
//  Created by zhangwang on 2026/3/6.
//

import AppKit
import SpriteKit

final class GameScene: SKScene {
    private let levelFactory = LevelFactory()
    private let runContentFactory = RunContentFactory()
    private let inputController = GameInputController()
    private let gameControllerInputManager = GameControllerInputManager()
    private let renderer = GameRenderer()
    private let highScoreStore = HighScoreStore()
    private let achievementStore = AchievementStore()
    private let codexStore = CollectionCodexStore()
    private let settingsStore = GameSettingsStore()
    private let runHistoryStore = RunHistoryStore()
    private let audioController = GameAudioController()

    private var engine = SnakeGameEngine(
        level: LevelDefinition(name: "初始化", columns: 20, rows: 14, tickDuration: 0.18, obstacles: [], dynamicMechanic: nil, hasCollapsingTiles: false)
    )
    private var lastUpdateTime: TimeInterval = 0
    private var timeAccumulator: TimeInterval = 0
    private var sceneReady = false
    private var mode: SceneMode = .mainMenu
    private var settings = GameSettings.default
    private var mainMenuSelection = 0
    private var settingsSelection = 0
    private var gameOverSelection = 0
    private var codexSectionSelection = 0
    private var boostButtonHeld = false
    private var boostCooldownRemaining: TimeInterval = 0

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
        preparePreview()
        mode = .mainMenu
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

    private func handleInputAction(_ action: GameInputAction) {
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

    private func preparePreview() {
        let level = levelFactory.randomLevel(isSimpleModeEnabled: settings.simpleModeEnabled)
        let modifier = runContentFactory.randomModifier(isSimpleModeEnabled: settings.simpleModeEnabled)
        let mission = runContentFactory.randomMission(for: level, modifier: modifier, isSimpleModeEnabled: settings.simpleModeEnabled)
        engine.restart(
            with: level,
            modifier: modifier,
            mission: mission,
            highScore: highScoreStore.highScore,
            isSimpleModeEnabled: settings.simpleModeEnabled
        )
        engine.applySpeedPreset(settings.speedPreset)
        lastUpdateTime = 0
        timeAccumulator = 0
        boostButtonHeld = false
        boostCooldownRemaining = 0
    }

    private func handle(events: [GameEvent]) {
        for event in events {
            switch event {
            case .ateFruit(let fruit, _, _):
                audioController.playFruit(effect: fruit.effect)
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
                mode = .gameOver
                gameOverSelection = 0
                boostButtonHeld = false
                runHistoryStore.recordRun(snapshot: engine.snapshot)
                audioController.playGameOver()
                syncAudioMode()
                renderer.play(event)
            case .highScoreUpdated(let newScore):
                if highScoreStore.saveIfNeeded(score: newScore) {
                    renderer.play(event)
                }
            case .missionCompleted:
                renderer.play(event)
            case .achievementUnlocked:
                renderer.play(event)
            }
        }

        recordCurrentCodexDiscovery()

        let unlockedAchievements = achievementStore.unlock(
            AchievementCatalog.unlockedAchievements(snapshot: engine.snapshot, runStats: engine.runStats)
        )
        unlockedAchievements.forEach { renderer.play(.achievementUnlocked($0)) }
    }

    private func handleDirectionAction(_ direction: Direction) {
        switch mode {
        case .playing:
            engine.queueDirection(direction)
        case .mainMenu:
            guard direction == .up || direction == .down else {
                return
            }
            let delta = direction == .up ? -1 : 1
            mainMenuSelection = wrappedIndex(mainMenuSelection + delta, count: MainMenuOption.allCases.count)
            audioController.playNavigate()
            renderCurrent()
        case .achievements, .help:
            break
        case .codex:
            guard direction == .up || direction == .down else {
                return
            }
            let delta = direction == .up ? -1 : 1
            codexSectionSelection = wrappedIndex(codexSectionSelection + delta, count: CodexSection.allCases.count)
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

    private func handlePrimaryAction() {
        switch mode {
        case .mainMenu:
            applyMainMenuSelection()
        case .achievements, .help, .codex:
            mode = .mainMenu
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

    private func handlePauseAction() {
        switch mode {
        case .playing:
            mode = .paused
            boostButtonHeld = false
            audioController.playPause()
            syncAudioMode()
        case .paused:
            mode = .playing
            audioController.playPause()
            syncAudioMode()
        case .mainMenu, .achievements, .codex, .help, .settings, .ready, .gameOver:
            break
        }
        renderCurrent()
    }

    private func handleSecondaryAction() {
        switch mode {
        case .playing:
            mode = .paused
            boostButtonHeld = false
            audioController.playPause()
            syncAudioMode()
        case .paused, .gameOver, .ready:
            mode = .mainMenu
            syncAudioMode()
        case .settings, .achievements, .codex, .help:
            mode = .mainMenu
            audioController.playConfirm()
            syncAudioMode()
        case .mainMenu:
            break
        }
        renderCurrent()
    }

    private func applyMainMenuSelection() {
        audioController.playConfirm()
        switch MainMenuOption.allCases[mainMenuSelection] {
        case .start:
            beginCurrentRun()
        case .reroll:
            preparePreview()
            mode = .mainMenu
        case .achievements:
            mode = .achievements
        case .codex:
            codexSectionSelection = 0
            mode = .codex
        case .help:
            mode = .help
        case .settings:
            settingsSelection = 0
            mode = .settings
        case .quit:
            NSApplication.shared.terminate(nil)
        }
        syncAudioMode()
    }

    private func applySettingsPrimaryAction() {
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
        case .speed:
            adjustSpeedPreset(step: 1)
        case .back:
            audioController.playConfirm()
            mode = .mainMenu
            syncAudioMode()
        }
    }

    private func applyGameOverSelection() {
        audioController.playConfirm()
        switch GameOverOption.allCases[gameOverSelection] {
        case .replay:
            preparePreview()
            beginCurrentRun()
        case .mainMenu:
            preparePreview()
            mode = .mainMenu
        case .achievements:
            mode = .achievements
        }
        syncAudioMode()
    }

    private func adjustSelectedSetting(step: Int) {
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
        case .speed:
            adjustSpeedPreset(step: step)
        case .back:
            break
        }
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
        settings.simpleModeEnabled.toggle()
        settings = normalized(settings)
        persistSettings()
        if mode != .playing && mode != .paused && mode != .gameOver {
            preparePreview()
        }
    }

    private func normalized(_ settings: GameSettings) -> GameSettings {
        var normalizedSettings = settings
        if normalizedSettings.simpleModeEnabled, normalizedSettings.speedPreset == .turbo {
            normalizedSettings.speedPreset = .relaxed
        }
        return normalizedSettings
    }

    private func persistSettings() {
        settings = normalized(settings)
        settingsStore.settings = settings
        audioController.apply(settings: settings)
        engine.applySpeedPreset(settings.speedPreset)
        syncAudioMode()
    }

    private func renderCurrent() {
        backgroundColor = renderer.backgroundColor(for: engine.snapshot.level)
        renderer.updateLayout(sceneSize: size, level: engine.snapshot.level)
        renderer.render(
            snapshot: engine.snapshot,
            boostStatus: boostStatus,
            mode: mode,
            progress: progressSummary,
            overlayMenu: overlayMenuState
        )
    }

    private func syncAudioMode() {
        let audioMode: SceneAudioMode
        switch mode {
        case .mainMenu, .achievements, .codex, .help, .settings, .ready:
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
        case .mainMenu:
            let history = runHistoryStore.summary
            return OverlayMenuState(
                title: "Snake Orchard",
                subtitle: settings.simpleModeEnabled ? "极简模式 · 更慢更简单" : "随机地图、随机词条、随机任务",
                detail: "最高分 \(highScoreStore.highScore) · 最长长度 \(history.bestLength) · 已玩 \(history.totalRuns) 局 · 图鉴 \(codexStore.totalDiscoveredCount)/\(CodexCatalog.all(levelNames: codexLevelNames).count)\n上局: \(history.lastLevelName) / \(history.lastScore) 分 / \(history.lastMissionCompleted ? "任务完成" : "任务未完成")",
                items: MainMenuOption.allCases.map {
                    OverlayMenuItem(title: $0.title, subtitle: nil, icon: nil, badge: nil, isDimmed: false)
                },
                selectedIndex: mainMenuSelection,
                footer: "上/下选择 · 空格确认 · Esc 关闭子页",
                layout: .list
            )
        case .achievements:
            let unlockedIDs = Set(achievementStore.unlockedAchievements.map(\.id))
            let items = AchievementCatalog.all.map { achievement in
                let unlocked = unlockedIDs.contains(achievement.id)
                return OverlayMenuItem(
                    title: achievement.title,
                    subtitle: achievement.detail,
                    icon: achievement.symbol,
                    badge: unlocked ? achievement.category.title : "未解锁",
                    isDimmed: !unlocked
                )
            }
            return OverlayMenuState(
                title: "成就图鉴",
                subtitle: "已解锁 \(achievementStore.unlockedCount)/\(AchievementCatalog.all.count)",
                detail: "完成任务、挑战机关和收集特殊水果来解锁更多成就。",
                items: items,
                selectedIndex: nil,
                footer: "空格或 Esc 返回主菜单",
                layout: .achievementGrid
            )
        case .codex:
            let section = CodexSection.allCases[codexSectionSelection]
            let entries = CodexCatalog.entries(for: section, levelNames: codexLevelNames)
            let discoveredIDs = codexStore.discoveredIDs(for: section)
            let items = entries.map { entry in
                let discovered = discoveredIDs.contains(entry.id)
                return OverlayMenuItem(
                    title: entry.title,
                    subtitle: discovered ? entry.detail : "继续游玩来发现这条记录",
                    icon: entry.symbol,
                    badge: discovered ? "已发现" : "未发现",
                    isDimmed: !discovered
                )
            }
            return OverlayMenuState(
                title: "收藏图鉴",
                subtitle: "\(section.symbol) \(section.title) · 已发现 \(discoveredIDs.count)/\(entries.count)",
                detail: "上/下切换分类：水果、特效、机关、地图。图鉴会随着你真正游玩而逐步点亮。",
                items: items,
                selectedIndex: nil,
                footer: "上/下切换分类 · 空格或 Esc 返回主菜单",
                layout: .achievementGrid
            )
        case .help:
            let helpDetail = settings.simpleModeEnabled
                ? "极简模式: 只会出现基础关卡和普通水果，没有特殊水果、倒计时、连击、爆炸地块或塌陷机制，而且整体节奏会更慢。\n蛇会变成小火车，吃到什么水果，就在尾巴后面多挂上对应的水果车厢；第一次撞到危险时还会自动安全刹车一次。\n长按空格或手柄右肩键可以喷射加速，每 5 秒最多一次，会甩掉一节尾巴并留下短暂便便残留。\n操作: 键盘方向键/WASD 或手柄方向键/左摇杆移动，A 确认，B 返回，Menu 暂停。"
                : "普通流程: 吃水果变长，撞墙/撞障碍/撞机关/塌陷地板结束。\n特殊水果: 金彩双倍分，冰镇减速，幽影穿身，回环穿墙，爆裂会炸出临时危险区。\n长按空格或手柄右肩键可以喷射加速，每 5 秒最多一次，会甩掉一节尾巴并留下短暂便便残留。\n操作: 键盘方向键/WASD 或手柄方向键/左摇杆移动，A 确认，B 返回，Menu 暂停。"
            let helpItems = settings.simpleModeEnabled
                ? [
                    OverlayMenuItem(title: "火车模式", subtitle: "吃到什么水果，就增加对应车厢", icon: "🚂", badge: nil, isDimmed: false),
                    OverlayMenuItem(title: "只抽基础地图", subtitle: "没有机关图和塌陷地板", icon: "☁", badge: nil, isDimmed: false),
                    OverlayMenuItem(title: "速度更慢", subtitle: "只保留轻松/标准，并额外放慢", icon: "☺", badge: nil, isDimmed: false),
                    OverlayMenuItem(title: "安全刹车", subtitle: "第一次撞到危险会自动停下", icon: "🛑", badge: nil, isDimmed: false),
                    OverlayMenuItem(title: "喷射加速", subtitle: "长按空格，5 秒一充能，会甩掉一节尾巴", icon: "⚡", badge: nil, isDimmed: false)
                ]
                : [
                    OverlayMenuItem(title: "柚子 +2，其它水果 +1", subtitle: "优先规划长身位", icon: "🍊", badge: nil, isDimmed: false),
                    OverlayMenuItem(title: "机关图危险更高，但路线收益也更高", subtitle: "动态障碍会实时变化", icon: "⚙", badge: nil, isDimmed: false),
                    OverlayMenuItem(title: "倒计时水果和连击会逼你提速", subtitle: "地砖塌陷时不要原路折返", icon: "⏳", badge: nil, isDimmed: false),
                    OverlayMenuItem(title: "喷射加速", subtitle: "长按空格快速冲刺，但会甩掉一节尾巴", icon: "⚡", badge: nil, isDimmed: false)
                ]
            return OverlayMenuState(
                title: "玩法帮助",
                subtitle: settings.simpleModeEnabled ? "先熟悉方向，再慢慢提高难度" : "先活下来，再追求更高收益",
                detail: helpDetail,
                items: helpItems,
                selectedIndex: nil,
                footer: "空格或 Esc 返回主菜单",
                layout: .list
            )
        case .settings:
            let items = SettingsOption.allCases.map { option in
                switch option {
                case .sound:
                    return OverlayMenuItem(title: option.title, subtitle: settings.soundEnabled ? "开启" : "关闭", icon: "♪", badge: nil, isDimmed: false)
                case .music:
                    return OverlayMenuItem(title: option.title, subtitle: settings.musicEnabled ? "开启" : "关闭", icon: "♫", badge: nil, isDimmed: false)
                case .simpleMode:
                    return OverlayMenuItem(
                        title: option.title,
                        subtitle: settings.simpleModeEnabled ? "极简" : "标准",
                        icon: "☺",
                        badge: settings.simpleModeEnabled ? "儿童友好" : nil,
                        isDimmed: false
                    )
                case .speed:
                    return OverlayMenuItem(title: option.title, subtitle: settings.speedPreset.title, icon: "➤", badge: nil, isDimmed: false)
                case .back:
                    return OverlayMenuItem(title: option.title, subtitle: nil, icon: "⌂", badge: nil, isDimmed: false)
                }
            }
            return OverlayMenuState(
                title: "设置",
                subtitle: "修改会立即生效",
                detail: settings.simpleModeEnabled
                    ? "极简模式会限制为更简单的关卡和普通水果，并屏蔽极速档。"
                    : "音效和音乐会立即应用，速度会直接影响当前与下一局的移动节奏。",
                items: items,
                selectedIndex: settingsSelection,
                footer: "上/下切换 · 左/右调整 · 空格确认 · Esc 返回",
                layout: .list
            )
        case .gameOver:
            let items = GameOverOption.allCases.map {
                OverlayMenuItem(title: $0.title, subtitle: nil, icon: $0.symbol, badge: nil, isDimmed: false)
            }
            return OverlayMenuState(
                title: engine.snapshot.statusText,
                subtitle: "本局得分 \(engine.snapshot.score) · 最高 \(engine.snapshot.highScore) · 任务 \(engine.snapshot.missionProgress.summaryText)",
                detail: "关卡: \(engine.snapshot.level.name) · 词条: \(engine.snapshot.modifier.title) · 模式: \(engine.snapshot.isSimpleModeEnabled ? "极简" : "标准")\n长度 \(engine.snapshot.snake.count) · 水果 \(engine.snapshot.fruitsEaten) · 生存 \(engine.snapshot.stepsSurvived) 步\n已解锁成就: \(progressSummary.unlockedAchievements)/\(progressSummary.totalAchievements)",
                items: items,
                selectedIndex: gameOverSelection,
                footer: "上/下选择 · 空格确认 · Esc 返回主菜单",
                layout: .list
            )
        default:
            return nil
        }
    }

    private func wrappedIndex(_ value: Int, count: Int) -> Int {
        guard count > 0 else {
            return 0
        }
        let remainder = value % count
        return remainder >= 0 ? remainder : remainder + count
    }

    private var progressSummary: GameProgressSummary {
        GameProgressSummary(
            unlockedAchievements: achievementStore.unlockedCount,
            totalAchievements: AchievementCatalog.all.count
        )
    }

    private var codexLevelNames: [String] {
        levelFactory.allLevels(isSimpleModeEnabled: false).map(\.name)
    }

    private var boostStatus: BoostStatusSnapshot {
        let hasEnoughLength = engine.snapshot.snake.count > 3
        let cooldown = max(0, boostCooldownRemaining)
        return BoostStatusSnapshot(
            isReady: cooldown <= 0.01 && hasEnoughLength,
            chargeProgress: min(1, max(0, 1 - cooldown / 5)),
            cooldownRemaining: cooldown,
            isHeld: boostButtonHeld,
            hasEnoughLength: hasEnoughLength
        )
    }

    private func handleBoostPressed() {
        guard mode == .playing else {
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

    private func beginCurrentRun() {
        mode = .playing
        recordCurrentCodexDiscovery()
    }

    private func recordCurrentCodexDiscovery() {
        codexStore.record(level: engine.snapshot.level)
        if let fruit = engine.snapshot.fruit {
            codexStore.record(fruit: fruit)
        }
    }
}
