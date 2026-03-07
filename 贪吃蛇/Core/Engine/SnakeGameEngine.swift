//
//  SnakeGameEngine.swift
//  贪吃蛇
//
//  Created by zhangwang on 2026/3/6.
//

import Foundation

final class SnakeGameEngine {
    private struct ActiveTemporaryHazard {
        var style: TemporaryHazardStyle
        var remainingSteps: Int
    }

    private let gameplayHint = "撞墙、撞障碍、撞自己都会结束；柚子一次加两节，其它水果加一节"
    private let restartHint = "按空格重新开始，本次关卡会重新随机"

    private(set) var level: LevelDefinition
    private(set) var modifier: RunModifier
    private(set) var mission: MissionDefinition
    private(set) var missionProgress = MissionProgress(current: 0, target: 1, isCompleted: false)
    private(set) var runStats = GameRunStats()
    private(set) var snake: [GridPoint] = []
    private(set) var dynamicObstacle: DynamicObstacleSnapshot?
    private(set) var temporaryHazards: [TemporaryHazardSnapshot] = []
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
    private var ghostMovesRemaining = 0
    private var wrapMovesRemaining = 0
    private var fruitCountdownRemaining: Int?
    private var comboCount = 0
    private var comboWindowRemaining = 0
    private var lastComboBonus = 0
    private var endMessage: String?
    private var mechanicTick = 0
    private var userSpeedMultiplier = SpeedPreset.standard.tickMultiplier
    private var activeTemporaryHazards: [GridPoint: ActiveTemporaryHazard] = [:]

    init(level: LevelDefinition) {
        self.level = level
        self.modifier = .harvestRush
        self.mission = MissionDefinition(title: "热身", detail: "吃到 1 个水果", goal: .fruits(1))
        restart(with: level, modifier: .harvestRush, mission: self.mission, highScore: 0)
    }

    var tickDuration: TimeInterval {
        let baseDuration = level.tickDuration * modifier.tickMultiplier
        let adjustedDuration = baseDuration * userSpeedMultiplier
        return slowMovesRemaining > 0 ? adjustedDuration * 1.35 : adjustedDuration
    }

    var snapshot: GameSnapshot {
        GameSnapshot(
            level: level,
            modifier: modifier,
            mission: mission,
            missionProgress: missionProgress,
            snake: snake,
            dynamicObstacle: dynamicObstacle,
            temporaryHazards: temporaryHazards,
            fruitPosition: fruitPosition,
            fruit: fruit,
            fruitCountdown: fruitCountdownRemaining,
            score: score,
            highScore: highScore,
            fruitsEaten: fruitsEaten,
            stepsSurvived: runStats.stepsSurvived,
            comboCount: comboCount,
            comboBonus: lastComboBonus,
            isGameOver: isGameOver,
            statusText: isGameOver ? (endMessage ?? "游戏结束") : "方向键 / WASD 控制",
            hintText: isGameOver ? restartHint : gameplayHint,
            activeEffectText: activeEffectText,
            mechanicText: level.dynamicMechanic?.statusText(at: mechanicTick)
        )
    }

    func restart(with level: LevelDefinition, modifier: RunModifier, mission: MissionDefinition, highScore: Int) {
        self.level = level
        self.modifier = modifier
        self.mission = mission
        self.highScore = highScore
        direction = .right
        pendingDirection = nil
        queuedGrowth = 0
        score = 0
        fruitsEaten = 0
        isGameOver = false
        slowMovesRemaining = 0
        ghostMovesRemaining = 0
        wrapMovesRemaining = 0
        fruitCountdownRemaining = nil
        comboCount = 0
        comboWindowRemaining = 0
        lastComboBonus = 0
        endMessage = nil
        mechanicTick = 0
        runStats = GameRunStats()
        dynamicObstacle = level.dynamicMechanic?.snapshot(at: mechanicTick)
        activeTemporaryHazards = [:]
        temporaryHazards = []
        missionProgress = Self.makeMissionProgress(for: mission, snapshot: nil, runStats: runStats)

        snake = makeStartingSnake(in: level)
        fruitPosition = nil
        fruit = nil
        spawnFruit()
        missionProgress = Self.makeMissionProgress(for: mission, snapshot: snapshot, runStats: runStats)
    }

    func applySpeedPreset(_ preset: SpeedPreset) {
        userSpeedMultiplier = preset.tickMultiplier
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

        let rawNextHead = currentHead.moved(direction)
        let nextHead = normalizedHead(from: rawNextHead)
        let eatingFruit = fruitPosition.map { nextHead == $0 } ?? false
        let growthFromFruit = eatingFruit ? (fruit?.growth ?? 0) : 0
        let tailWillRemain = queuedGrowth > 0 || growthFromFruit > 0
        let collisionBody = tailWillRemain ? snake : Array(snake.dropLast())
        let dynamicBlocked = Set(dynamicObstacle?.points ?? [])
        let temporaryBlocked = Set(activeTemporaryHazards.keys)

        let hitWall = !hasWrapActive && (
            rawNextHead.x < 0 || rawNextHead.x >= level.columns ||
            rawNextHead.y < 0 || rawNextHead.y >= level.rows
        )
        let hitObstacle = level.obstacles.contains(nextHead)
        let hitDynamicObstacle = dynamicBlocked.contains(nextHead)
        let hitTemporaryHazard = temporaryBlocked.contains(nextHead)
        let hitSelf = !hasGhostActive && collisionBody.contains(nextHead)

        if hitWall || hitObstacle || hitDynamicObstacle || hitSelf || hitTemporaryHazard {
            if hitTemporaryHazard {
                endGame(message: temporaryHazardMessage(for: activeTemporaryHazards[nextHead]?.style))
            } else {
                endGame(message: "游戏结束")
            }
            events.append(.gameOver)
            return events
        }

        snake.insert(nextHead, at: 0)

        let eatenFruit = fruit
        if let eatenFruit, eatingFruit {
            queuedGrowth += eatenFruit.growth
            fruitsEaten += 1
            runStats.recordFruit(eatenFruit)
            let comboBonus = nextComboBonus()
            let gainedPoints = modifiedScore(for: eatenFruit) + comboBonus
            score += gainedPoints
            slowMovesRemaining += eatenFruit.effect.slowMoveBonus
            ghostMovesRemaining += eatenFruit.effect.ghostMoveBonus
            wrapMovesRemaining += eatenFruit.effect.wrapMoveBonus
            comboWindowRemaining = 5
            events.append(.ateFruit(fruit: eatenFruit, at: nextHead, points: gainedPoints))
            if comboCount >= 2 {
                events.append(.comboAdvanced(count: comboCount, bonus: comboBonus))
            }
            if eatenFruit.effect == .bomb {
                armBombHazards(around: nextHead)
                events.append(.bombTriggered)
            }
            if score > highScore {
                highScore = score
                events.append(.highScoreUpdated(highScore))
            }
            spawnFruit()
        } else if comboWindowRemaining > 0 {
            comboWindowRemaining -= 1
            if comboWindowRemaining == 0 {
                comboCount = 0
                lastComboBonus = 0
            }
        }

        var collapsedTileAdded = false
        if queuedGrowth > 0 {
            queuedGrowth -= 1
        } else {
            let removedTail = snake.removeLast()
            if armCollapsingTile(at: removedTail) {
                collapsedTileAdded = true
            }
        }

        if slowMovesRemaining > 0 {
            slowMovesRemaining -= 1
        }
        if ghostMovesRemaining > 0 {
            ghostMovesRemaining -= 1
        }
        if wrapMovesRemaining > 0 {
            wrapMovesRemaining -= 1
        }
        if !eatingFruit, let fruitCountdownRemaining {
            let updatedCountdown = fruitCountdownRemaining - 1
            if updatedCountdown <= 0 {
                if let fruit {
                    events.append(.fruitExpired(fruit))
                }
                spawnFruit()
            } else {
                self.fruitCountdownRemaining = updatedCountdown
            }
        }

        runStats.stepsSurvived += 1
        mechanicTick += 1
        dynamicObstacle = level.dynamicMechanic?.snapshot(at: mechanicTick)
        tickTemporaryHazards()
        rebuildTemporaryHazardSnapshot()

        let newDynamicBlocked = Set(dynamicObstacle?.points ?? [])
        if snake.contains(where: { newDynamicBlocked.contains($0) }) {
            endGame(message: "被机关夹住了")
            events.append(.gameOver)
            return events
        }
        if let collidedHazardPoint = snake.first(where: { activeTemporaryHazards[$0] != nil }) {
            endGame(message: temporaryHazardMessage(for: activeTemporaryHazards[collidedHazardPoint]?.style))
            events.append(.gameOver)
            return events
        }

        if fruitPosition.map({ newDynamicBlocked.contains($0) || activeTemporaryHazards[$0] != nil }) ?? false {
            spawnFruit()
        }
        if collapsedTileAdded {
            events.append(.floorCollapsed)
        }

        let updatedMissionProgress = Self.makeMissionProgress(for: mission, snapshot: snapshot, runStats: runStats)
        if updatedMissionProgress.isCompleted && !missionProgress.isCompleted {
            runStats.missionCompleted = true
            events.append(.missionCompleted(mission))
        }
        missionProgress = Self.makeMissionProgress(for: mission, snapshot: snapshot, runStats: runStats)

        return events
    }

    private func spawnFruit() {
        let occupied = Set(snake)
            .union(level.obstacles)
            .union(dynamicObstacle?.points ?? [])
            .union(activeTemporaryHazards.keys)
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
        fruitCountdownRemaining = Int.random(in: 0 ..< 100) < 35 ? Int.random(in: 8 ... 12) : nil
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

    private func modifiedScore(for fruit: FruitDefinition) -> Int {
        Int((Double(fruit.scoreValue) * modifier.scoreMultiplier).rounded())
    }

    private func randomEffect() -> FruitEffect {
        let roll = Int.random(in: 0 ..< 100)
        let goldenThreshold = min(70, 14 + modifier.goldenChanceBonus)
        let frostThreshold = min(85, goldenThreshold + 14 + modifier.frostChanceBonus)
        let ghostThreshold = min(92, frostThreshold + 7)
        let warpThreshold = min(96, ghostThreshold + 5)
        let bombThreshold = min(98, warpThreshold + 2)
        switch roll {
        case 0 ..< goldenThreshold:
            return .golden
        case goldenThreshold ..< frostThreshold:
            return .frost
        case frostThreshold ..< ghostThreshold:
            return .ghost
        case ghostThreshold ..< warpThreshold:
            return .warp
        case warpThreshold ..< bombThreshold:
            return .bomb
        default:
            return .normal
        }
    }

    private static func makeMissionProgress(
        for mission: MissionDefinition,
        snapshot: GameSnapshot?,
        runStats: GameRunStats
    ) -> MissionProgress {
        let current: Int
        let target = mission.goal.targetValue

        switch mission.goal {
        case .fruits:
            current = runStats.totalFruitsEaten
        case .score:
            current = snapshot?.score ?? 0
        case .reachLength:
            current = snapshot?.snake.count ?? 0
        case .specificFruit(let kind, _):
            current = runStats.fruits(for: kind)
        case .specialFruit:
            current = runStats.totalSpecialFruitsEaten
        case .surviveSteps:
            current = runStats.stepsSurvived
        }

        return MissionProgress(
            current: current,
            target: target,
            isCompleted: current >= target
        )
    }

    private var hasGhostActive: Bool {
        ghostMovesRemaining > 0
    }

    private var hasWrapActive: Bool {
        wrapMovesRemaining > 0
    }

    private var activeEffectText: String? {
        var parts: [String] = []
        if slowMovesRemaining > 0 {
            parts.append("冰镇减速 \(slowMovesRemaining) 步")
        }
        if ghostMovesRemaining > 0 {
            parts.append("幽影穿身 \(ghostMovesRemaining) 步")
        }
        if wrapMovesRemaining > 0 {
            parts.append("回环穿墙 \(wrapMovesRemaining) 步")
        }
        if comboWindowRemaining > 0, comboCount >= 2 {
            parts.append("连击 x\(comboCount)")
        }
        if let fruitCountdownRemaining {
            parts.append("倒计时 \(fruitCountdownRemaining) 步")
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private func normalizedHead(from rawHead: GridPoint) -> GridPoint {
        guard hasWrapActive else {
            return rawHead
        }
        return GridPoint(
            x: wrapped(rawHead.x, max: level.columns),
            y: wrapped(rawHead.y, max: level.rows)
        )
    }

    private func wrapped(_ value: Int, max upperBound: Int) -> Int {
        guard upperBound > 0 else {
            return value
        }
        let modulo = value % upperBound
        return modulo >= 0 ? modulo : modulo + upperBound
    }

    private func nextComboBonus() -> Int {
        if comboWindowRemaining > 0 {
            comboCount += 1
        } else {
            comboCount = 1
        }
        lastComboBonus = comboCount >= 2 ? comboCount * 3 : 0
        return lastComboBonus
    }

    private func tickTemporaryHazards() {
        var updated: [GridPoint: ActiveTemporaryHazard] = [:]
        for (point, hazard) in activeTemporaryHazards {
            let remaining = hazard.remainingSteps - 1
            if remaining > 0 {
                updated[point] = ActiveTemporaryHazard(style: hazard.style, remainingSteps: remaining)
            }
        }
        activeTemporaryHazards = updated
    }

    private func rebuildTemporaryHazardSnapshot() {
        let collapsePoints = activeTemporaryHazards.compactMap { entry in
            entry.value.style == .collapse ? entry.key : nil
        }
        let bombPoints = activeTemporaryHazards.compactMap { entry in
            entry.value.style == .bomb ? entry.key : nil
        }

        temporaryHazards = [
            collapsePoints.isEmpty ? nil : TemporaryHazardSnapshot(points: collapsePoints, style: .collapse),
            bombPoints.isEmpty ? nil : TemporaryHazardSnapshot(points: bombPoints, style: .bomb)
        ].compactMap { $0 }
    }

    private func armCollapsingTile(at point: GridPoint) -> Bool {
        guard level.hasCollapsingTiles else {
            return false
        }
        guard !level.obstacles.contains(point) else {
            return false
        }
        guard !(dynamicObstacle?.points.contains(point) ?? false) else {
            return false
        }
        activeTemporaryHazards[point] = ActiveTemporaryHazard(style: .collapse, remainingSteps: 5)
        return true
    }

    private func armBombHazards(around center: GridPoint) {
        let offsets = [
            GridPoint(x: -1, y: 0), GridPoint(x: 1, y: 0),
            GridPoint(x: 0, y: -1), GridPoint(x: 0, y: 1),
            GridPoint(x: -1, y: -1), GridPoint(x: 1, y: -1),
            GridPoint(x: -1, y: 1), GridPoint(x: 1, y: 1)
        ]

        let occupiedBySnake = Set(snake)
        for offset in offsets {
            let point = GridPoint(x: center.x + offset.x, y: center.y + offset.y)
            guard point.x >= 0, point.x < level.columns, point.y >= 0, point.y < level.rows else {
                continue
            }
            guard !level.obstacles.contains(point) else {
                continue
            }
            guard !(dynamicObstacle?.points.contains(point) ?? false) else {
                continue
            }
            guard !occupiedBySnake.contains(point) else {
                continue
            }
            activeTemporaryHazards[point] = ActiveTemporaryHazard(style: .bomb, remainingSteps: 6)
        }
        rebuildTemporaryHazardSnapshot()
    }

    private func temporaryHazardMessage(for style: TemporaryHazardStyle?) -> String {
        switch style {
        case .collapse:
            return "踩进塌陷地板了"
        case .bomb:
            return "被爆裂余波困住了"
        case .none:
            return "游戏结束"
        }
    }
}
