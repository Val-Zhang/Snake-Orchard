//
//  SnakeGameEngine.swift
//  贪吃蛇
//
//  Created by zhangwang on 2026/3/6.
//

import Foundation

final class SnakeGameEngine {
    private let gameplayHint = "撞墙、撞障碍、撞自己都会结束；柚子一次加两节，其它水果加一节"
    private let restartHint = "按空格重新开始，本次关卡会重新随机"

    private(set) var level: LevelDefinition
    private(set) var snake: [GridPoint] = []
    private(set) var dynamicObstacle: DynamicObstacleSnapshot?
    private(set) var fruitPosition: GridPoint?
    private(set) var fruit: FruitDefinition?
    private(set) var score = 0
    private(set) var highScore = 0
    private(set) var fruitsEaten = 0
    private(set) var isGameOver = false

    private var direction: Direction = .right
    private var pendingDirection: Direction?
    private var queuedGrowth = 0
    private var slowMovesRemaining = 0
    private var endMessage: String?
    private var mechanicTick = 0

    init(level: LevelDefinition) {
        self.level = level
        restart(with: level, highScore: 0)
    }

    var tickDuration: TimeInterval {
        slowMovesRemaining > 0 ? level.tickDuration * 1.35 : level.tickDuration
    }

    var snapshot: GameSnapshot {
        GameSnapshot(
            level: level,
            snake: snake,
            dynamicObstacle: dynamicObstacle,
            fruitPosition: fruitPosition,
            fruit: fruit,
            score: score,
            highScore: highScore,
            fruitsEaten: fruitsEaten,
            isGameOver: isGameOver,
            statusText: isGameOver ? (endMessage ?? "游戏结束") : "方向键 / WASD 控制",
            hintText: isGameOver ? restartHint : gameplayHint,
            activeEffectText: slowMovesRemaining > 0 ? "冰镇减速 \(slowMovesRemaining) 步" : nil,
            mechanicText: level.dynamicMechanic?.statusText(at: mechanicTick)
        )
    }

    func restart(with level: LevelDefinition, highScore: Int) {
        self.level = level
        self.highScore = highScore
        direction = .right
        pendingDirection = nil
        queuedGrowth = 0
        score = 0
        fruitsEaten = 0
        isGameOver = false
        slowMovesRemaining = 0
        endMessage = nil
        mechanicTick = 0
        dynamicObstacle = level.dynamicMechanic?.snapshot(at: mechanicTick)

        snake = makeStartingSnake(in: level)
        fruitPosition = nil
        fruit = nil
        spawnFruit()
    }

    func queueDirection(_ requestedDirection: Direction) {
        guard !isGameOver else {
            return
        }

        let referenceDirection = pendingDirection ?? direction
        if !requestedDirection.isOpposite(to: referenceDirection) {
            pendingDirection = requestedDirection
        }
    }

    func advance() -> [GameEvent] {
        guard !isGameOver, let currentHead = snake.first else {
            return []
        }

        var events: [GameEvent] = []

        if let pendingDirection, !pendingDirection.isOpposite(to: direction) {
            direction = pendingDirection
        }
        pendingDirection = nil

        let nextHead = currentHead.moved(direction)
        let eatingFruit = fruitPosition.map { nextHead == $0 } ?? false
        let growthFromFruit = eatingFruit ? (fruit?.growth ?? 0) : 0
        let tailWillRemain = queuedGrowth > 0 || growthFromFruit > 0
        let collisionBody = tailWillRemain ? snake : Array(snake.dropLast())
        let dynamicBlocked = Set(dynamicObstacle?.points ?? [])

        let hitWall = nextHead.x < 0 || nextHead.x >= level.columns || nextHead.y < 0 || nextHead.y >= level.rows
        let hitObstacle = level.obstacles.contains(nextHead)
        let hitDynamicObstacle = dynamicBlocked.contains(nextHead)
        let hitSelf = collisionBody.contains(nextHead)

        if hitWall || hitObstacle || hitDynamicObstacle || hitSelf {
            endGame(message: "游戏结束")
            events.append(.gameOver)
            return events
        }

        snake.insert(nextHead, at: 0)

        let eatenFruit = fruit
        if let eatenFruit, eatingFruit {
            queuedGrowth += eatenFruit.growth
            fruitsEaten += 1
            score += eatenFruit.scoreValue
            slowMovesRemaining += eatenFruit.effect.slowMoveBonus
            events.append(.ateFruit(fruit: eatenFruit, at: nextHead, points: eatenFruit.scoreValue))
            if score > highScore {
                highScore = score
                events.append(.highScoreUpdated(highScore))
            }
            spawnFruit()
        }

        if queuedGrowth > 0 {
            queuedGrowth -= 1
        } else {
            snake.removeLast()
        }

        if slowMovesRemaining > 0 {
            slowMovesRemaining -= 1
        }

        mechanicTick += 1
        dynamicObstacle = level.dynamicMechanic?.snapshot(at: mechanicTick)

        let newDynamicBlocked = Set(dynamicObstacle?.points ?? [])
        if snake.contains(where: { newDynamicBlocked.contains($0) }) {
            endGame(message: "被机关夹住了")
            events.append(.gameOver)
            return events
        }

        if fruitPosition.map({ newDynamicBlocked.contains($0) }) ?? false {
            spawnFruit()
        }

        return events
    }

    private func spawnFruit() {
        let occupied = Set(snake)
            .union(level.obstacles)
            .union(dynamicObstacle?.points ?? [])
        let available = (0 ..< level.columns).flatMap { x in
            (0 ..< level.rows).compactMap { y -> GridPoint? in
                let point = GridPoint(x: x, y: y)
                return occupied.contains(point) ? nil : point
            }
        }

        guard let nextPosition = available.randomElement() else {
            fruitPosition = nil
            fruit = nil
            endGame(message: "你把棋盘吃满了")
            return
        }

        fruitPosition = nextPosition
        fruit = FruitDefinition(
            kind: FruitKind.allCases.randomElement() ?? .apple,
            effect: randomEffect()
        )
    }

    private func makeStartingSnake(in level: LevelDefinition) -> [GridPoint] {
        let dynamicBlocked = Set(dynamicObstacle?.points ?? [])
        let orderedRows = (0 ..< level.rows).sorted { lhs, rhs in
            abs(lhs - level.rows / 2) < abs(rhs - level.rows / 2)
        }

        for row in orderedRows {
            for headX in 2 ..< level.columns {
                let candidate = [
                    GridPoint(x: headX, y: row),
                    GridPoint(x: headX - 1, y: row),
                    GridPoint(x: headX - 2, y: row)
                ]

                if candidate.allSatisfy({ !level.obstacles.contains($0) && !dynamicBlocked.contains($0) }) {
                    return candidate
                }
            }
        }

        return [
            GridPoint(x: 2, y: max(0, level.rows / 2)),
            GridPoint(x: 1, y: max(0, level.rows / 2)),
            GridPoint(x: 0, y: max(0, level.rows / 2))
        ]
    }

    private func endGame(message: String) {
        isGameOver = true
        endMessage = message
    }

    private func randomEffect() -> FruitEffect {
        let roll = Int.random(in: 0 ..< 100)
        switch roll {
        case 0 ..< 14:
            return .golden
        case 14 ..< 28:
            return .frost
        default:
            return .normal
        }
    }
}
