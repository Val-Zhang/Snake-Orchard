//
//  GameScene.swift
//  贪吃蛇
//
//  Created by zhangwang on 2026/3/6.
//

import SpriteKit

final class GameScene: SKScene {
    private let levelFactory = LevelFactory()
    private let runContentFactory = RunContentFactory()
    private let inputController = GameInputController()
    private let renderer = GameRenderer()
    private let highScoreStore = HighScoreStore()
    private let achievementStore = AchievementStore()
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

    override func didMove(to view: SKView) {
        guard !sceneReady else {
            return
        }

        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        settings = settingsStore.settings
        audioController.apply(settings: settings)
        engine.applySpeedPreset(settings.speedPreset)
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
        audioController.stopAll()
    }

    override func keyDown(with event: NSEvent) {
        guard let action = inputController.action(for: event) else {
            return
        }

        switch action {
        case .changeDirection(let direction):
            handleDirectionAction(direction)
        case .primaryAction:
            handlePrimaryAction()
        case .togglePause:
            handlePauseAction()
        case .secondaryAction:
            handleSecondaryAction()
        }
    }

    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        }

        let delta = currentTime - lastUpdateTime
        lastUpdateTime = currentTime

        guard mode == .playing, !engine.isGameOver else {
            return
        }

        timeAccumulator += min(delta, 0.25)
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

        if advanced {
            renderCurrent()
        }
    }

    private func preparePreview() {
        let level = levelFactory.randomLevel()
        let modifier = runContentFactory.randomModifier()
        let mission = runContentFactory.randomMission(for: level, modifier: modifier)
        engine.restart(with: level, modifier: modifier, mission: mission, highScore: highScoreStore.highScore)
        engine.applySpeedPreset(settings.speedPreset)
        lastUpdateTime = 0
        timeAccumulator = 0
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
            case .gameOver:
                mode = .gameOver
                gameOverSelection = 0
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
        case .achievements, .help:
            mode = .mainMenu
            audioController.playConfirm()
            syncAudioMode()
        case .settings:
            applySettingsPrimaryAction()
        case .ready:
            mode = .playing
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
            audioController.playPause()
            syncAudioMode()
        case .paused:
            mode = .playing
            audioController.playPause()
            syncAudioMode()
        case .mainMenu, .achievements, .help, .settings, .ready, .gameOver:
            break
        }
        renderCurrent()
    }

    private func handleSecondaryAction() {
        switch mode {
        case .playing:
            mode = .paused
            audioController.playPause()
            syncAudioMode()
        case .paused, .gameOver, .ready:
            mode = .mainMenu
            syncAudioMode()
        case .settings, .achievements, .help:
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
            mode = .playing
        case .reroll:
            preparePreview()
            mode = .mainMenu
        case .achievements:
            mode = .achievements
        case .help:
            mode = .help
        case .settings:
            settingsSelection = 0
            mode = .settings
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
            mode = .playing
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
        case .speed:
            adjustSpeedPreset(step: step)
        case .back:
            break
        }
    }

    private func adjustSpeedPreset(step: Int) {
        let presets = SpeedPreset.allCases
        guard let currentIndex = presets.firstIndex(of: settings.speedPreset) else {
            return
        }
        settings.speedPreset = presets[wrappedIndex(currentIndex + step, count: presets.count)]
        persistSettings()
        audioController.playNavigate()
    }

    private func persistSettings() {
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
            mode: mode,
            progress: progressSummary,
            overlayMenu: overlayMenuState
        )
    }

    private func syncAudioMode() {
        let audioMode: SceneAudioMode
        switch mode {
        case .mainMenu, .achievements, .help, .settings, .ready:
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
                subtitle: "随机地图、随机词条、随机任务",
                detail: "最高分 \(highScoreStore.highScore) · 最长长度 \(history.bestLength) · 已玩 \(history.totalRuns) 局\n上局: \(history.lastLevelName) / \(history.lastScore) 分 / \(history.lastMissionCompleted ? "任务完成" : "任务未完成")",
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
        case .help:
            return OverlayMenuState(
                title: "玩法帮助",
                subtitle: "先活下来，再追求更高收益",
                detail: "普通流程: 吃水果变长，撞墙/撞障碍/撞机关/塌陷地板结束。\n特殊水果: 金彩双倍分，冰镇减速，幽影穿身，回环穿墙，爆裂会炸出临时危险区。\n操作: 方向键/WASD 移动，空格确认，P 暂停，Esc 返回。",
                items: [
                    OverlayMenuItem(title: "柚子 +2，其它水果 +1", subtitle: "优先规划长身位", icon: "🍊", badge: nil, isDimmed: false),
                    OverlayMenuItem(title: "机关图危险更高，但路线收益也更高", subtitle: "动态障碍会实时变化", icon: "⚙", badge: nil, isDimmed: false),
                    OverlayMenuItem(title: "倒计时水果和连击会逼你提速", subtitle: "地砖塌陷时不要原路折返", icon: "⏳", badge: nil, isDimmed: false)
                ],
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
                case .speed:
                    return OverlayMenuItem(title: option.title, subtitle: settings.speedPreset.title, icon: "➤", badge: nil, isDimmed: false)
                case .back:
                    return OverlayMenuItem(title: option.title, subtitle: nil, icon: "⌂", badge: nil, isDimmed: false)
                }
            }
            return OverlayMenuState(
                title: "设置",
                subtitle: "修改会立即生效",
                detail: "音效和音乐会立即应用，速度会直接影响当前与下一局的移动节奏。",
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
                detail: "关卡: \(engine.snapshot.level.name) · 词条: \(engine.snapshot.modifier.title)\n长度 \(engine.snapshot.snake.count) · 水果 \(engine.snapshot.fruitsEaten) · 生存 \(engine.snapshot.stepsSurvived) 步\n已解锁成就: \(progressSummary.unlockedAchievements)/\(progressSummary.totalAchievements)",
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
}
