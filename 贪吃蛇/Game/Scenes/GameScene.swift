//
//  GameScene.swift
//  贪吃蛇
//
//  Created by zhangwang on 2026/3/6.
//

import SpriteKit

final class GameScene: SKScene {
    private let levelFactory = LevelFactory()
    private let inputController = GameInputController()
    private let renderer = GameRenderer()
    private let highScoreStore = HighScoreStore()
    private let audioController = GameAudioController()

    private var engine = SnakeGameEngine(
        level: LevelDefinition(name: "初始化", columns: 20, rows: 14, tickDuration: 0.18, obstacles: [], dynamicMechanic: nil)
    )
    private var lastUpdateTime: TimeInterval = 0
    private var timeAccumulator: TimeInterval = 0
    private var sceneReady = false
    private var mode: SceneMode = .ready

    override func didMove(to view: SKView) {
        guard !sceneReady else {
            return
        }

        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = SKColor(calibratedRed: 0.06, green: 0.08, blue: 0.12, alpha: 1.0)

        renderer.attach(to: self)
        sceneReady = true
        prepareNewGame()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        guard sceneReady else {
            return
        }

        renderer.updateLayout(sceneSize: size, level: engine.snapshot.level)
        renderer.render(snapshot: engine.snapshot, mode: mode)
    }

    override func keyDown(with event: NSEvent) {
        guard let action = inputController.action(for: event) else {
            return
        }

        switch action {
        case .changeDirection(let direction):
            if mode == .playing {
                engine.queueDirection(direction)
            }
        case .primaryAction:
            switch mode {
            case .ready:
                mode = .playing
            case .paused:
                mode = .playing
                audioController.playPause()
            case .gameOver:
                prepareNewGame()
            case .playing:
                break
            }
            renderer.render(snapshot: engine.snapshot, mode: mode)
        case .togglePause:
            switch mode {
            case .playing:
                mode = .paused
                audioController.playPause()
            case .paused:
                mode = .playing
                audioController.playPause()
            case .ready, .gameOver:
                break
            }
            renderer.render(snapshot: engine.snapshot, mode: mode)
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
        while timeAccumulator >= engine.tickDuration {
            timeAccumulator -= engine.tickDuration
            let events = engine.advance()
            handle(events: events)
            renderer.render(snapshot: engine.snapshot, mode: mode)
        }
    }

    private func prepareNewGame() {
        engine.restart(with: levelFactory.randomLevel(), highScore: highScoreStore.highScore)
        lastUpdateTime = 0
        timeAccumulator = 0
        mode = .ready
        renderer.updateLayout(sceneSize: size, level: engine.snapshot.level)
        renderer.render(snapshot: engine.snapshot, mode: mode)
    }

    private func handle(events: [GameEvent]) {
        for event in events {
            switch event {
            case .ateFruit(let fruit, _, _):
                audioController.playFruit(effect: fruit.effect)
                renderer.play(event)
            case .gameOver:
                mode = .gameOver
                audioController.playGameOver()
                renderer.play(event)
            case .highScoreUpdated(let newScore):
                if highScoreStore.saveIfNeeded(score: newScore) {
                    renderer.play(event)
                }
            }
        }
    }
}
