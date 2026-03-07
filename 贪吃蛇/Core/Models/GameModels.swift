//
//  GameModels.swift
//  贪吃蛇
//
//  Created by zhangwang on 2026/3/6.
//

import SpriteKit

struct GridPoint: Hashable {
    let x: Int
    let y: Int

    func moved(_ direction: Direction) -> GridPoint {
        GridPoint(x: x + direction.dx, y: y + direction.dy)
    }
}

enum Direction {
    case up
    case down
    case left
    case right

    var dx: Int {
        switch self {
        case .left:
            return -1
        case .right:
            return 1
        default:
            return 0
        }
    }

    var dy: Int {
        switch self {
        case .down:
            return -1
        case .up:
            return 1
        default:
            return 0
        }
    }

    func isOpposite(to other: Direction) -> Bool {
        (dx + other.dx == 0) && (dy + other.dy == 0)
    }

    var rotationAngle: CGFloat {
        switch self {
        case .right:
            return 0
        case .left:
            return .pi
        case .up:
            return .pi / 2
        case .down:
            return -.pi / 2
        }
    }
}

enum FruitKind: CaseIterable, Hashable {
    case banana
    case apple
    case pomelo
    case watermelon
    case peach

    var name: String {
        switch self {
        case .banana:
            return "香蕉"
        case .apple:
            return "苹果"
        case .pomelo:
            return "柚子"
        case .watermelon:
            return "西瓜"
        case .peach:
            return "桃子"
        }
    }

    var symbol: String {
        switch self {
        case .banana:
            return "🍌"
        case .apple:
            return "🍎"
        case .pomelo:
            return "🍊"
        case .watermelon:
            return "🍉"
        case .peach:
            return "🍑"
        }
    }

    var growth: Int {
        switch self {
        case .pomelo:
            return 2
        default:
            return 1
        }
    }

    var color: SKColor {
        switch self {
        case .banana:
            return SKColor(calibratedRed: 0.96, green: 0.82, blue: 0.25, alpha: 1.0)
        case .apple:
            return SKColor(calibratedRed: 0.84, green: 0.24, blue: 0.27, alpha: 1.0)
        case .pomelo:
            return SKColor(calibratedRed: 0.96, green: 0.88, blue: 0.55, alpha: 1.0)
        case .watermelon:
            return SKColor(calibratedRed: 0.22, green: 0.68, blue: 0.32, alpha: 1.0)
        case .peach:
            return SKColor(calibratedRed: 0.96, green: 0.60, blue: 0.63, alpha: 1.0)
        }
    }
}

enum FruitEffect: CaseIterable, Hashable {
    case normal
    case golden
    case frost
    case ghost
    case warp
    case bomb

    var title: String {
        switch self {
        case .normal:
            return ""
        case .golden:
            return "金彩"
        case .frost:
            return "冰镇"
        case .ghost:
            return "幽影"
        case .warp:
            return "回环"
        case .bomb:
            return "爆裂"
        }
    }

    var badge: String {
        switch self {
        case .normal:
            return ""
        case .golden:
            return "★"
        case .frost:
            return "❄"
        case .ghost:
            return "◌"
        case .warp:
            return "↻"
        case .bomb:
            return "✹"
        }
    }

    var ringColor: SKColor {
        switch self {
        case .normal:
            return SKColor(calibratedWhite: 1.0, alpha: 0.18)
        case .golden:
            return SKColor(calibratedRed: 1.0, green: 0.88, blue: 0.28, alpha: 1.0)
        case .frost:
            return SKColor(calibratedRed: 0.52, green: 0.84, blue: 1.0, alpha: 1.0)
        case .ghost:
            return SKColor(calibratedRed: 0.78, green: 0.66, blue: 1.0, alpha: 1.0)
        case .warp:
            return SKColor(calibratedRed: 1.0, green: 0.60, blue: 0.24, alpha: 1.0)
        case .bomb:
            return SKColor(calibratedRed: 1.0, green: 0.36, blue: 0.20, alpha: 1.0)
        }
    }

    var scoreMultiplier: Int {
        switch self {
        case .normal:
            return 1
        case .golden:
            return 2
        case .bomb:
            return 2
        case .frost, .ghost, .warp:
            return 1
        }
    }

    var slowMoveBonus: Int {
        switch self {
        case .frost:
            return 10
        default:
            return 0
        }
    }

    var ghostMoveBonus: Int {
        switch self {
        case .ghost:
            return 9
        default:
            return 0
        }
    }

    var wrapMoveBonus: Int {
        switch self {
        case .warp:
            return 8
        default:
            return 0
        }
    }
}

struct FruitDefinition {
    let kind: FruitKind
    let effect: FruitEffect

    var name: String {
        effect == .normal ? kind.name : "\(effect.title)\(kind.name)"
    }

    var symbol: String {
        kind.symbol
    }

    var growth: Int {
        kind.growth
    }

    var color: SKColor {
        kind.color
    }

    var scoreValue: Int {
        10 * growth * effect.scoreMultiplier
    }
}

enum RunModifier: CaseIterable {
    case harvestRush
    case swiftWinds
    case luckyStars

    var title: String {
        switch self {
        case .harvestRush:
            return "丰收时刻"
        case .swiftWinds:
            return "疾风节奏"
        case .luckyStars:
            return "奇遇星夜"
        }
    }

    var badge: String {
        switch self {
        case .harvestRush:
            return "✦"
        case .swiftWinds:
            return "➤"
        case .luckyStars:
            return "☄"
        }
    }

    var detail: String {
        switch self {
        case .harvestRush:
            return "所有水果分数提高 50%"
        case .swiftWinds:
            return "基础速度提升 18%，更考验走位"
        case .luckyStars:
            return "特殊水果更容易出现"
        }
    }

    var scoreMultiplier: Double {
        switch self {
        case .harvestRush:
            return 1.5
        case .swiftWinds, .luckyStars:
            return 1.0
        }
    }

    var tickMultiplier: Double {
        switch self {
        case .swiftWinds:
            return 0.82
        case .harvestRush, .luckyStars:
            return 1.0
        }
    }

    var goldenChanceBonus: Int {
        switch self {
        case .luckyStars:
            return 14
        default:
            return 0
        }
    }

    var frostChanceBonus: Int {
        switch self {
        case .luckyStars:
            return 8
        default:
            return 0
        }
    }
}

enum MissionGoal: Equatable {
    case fruits(Int)
    case score(Int)
    case reachLength(Int)
    case specificFruit(kind: FruitKind, count: Int)
    case differentFruitKinds(Int)
    case collectionSet([FruitKind])
    case specialFruit(Int)
    case surviveSteps(Int)

    var targetValue: Int {
        switch self {
        case .fruits(let count),
             .score(let count),
             .reachLength(let count),
             .differentFruitKinds(let count),
             .specialFruit(let count),
             .surviveSteps(let count):
            return count
        case .collectionSet(let kinds):
            return Set(kinds).count
        case .specificFruit(_, let count):
            return count
        }
    }
}

struct MissionDefinition: Equatable {
    let title: String
    let detail: String
    let goal: MissionGoal
}

struct MissionProgress: Equatable {
    let current: Int
    let target: Int
    let isCompleted: Bool

    var summaryText: String {
        isCompleted ? "已完成" : "\(min(current, target))/\(target)"
    }
}

enum AchievementID: String, CaseIterable {
    case firstFruit
    case pomeloCollector
    case goldenHunter
    case longTail
    case missionStarter
    case hazardRunner
    case rainbowPicnic
    case speedster
    case poopTrail
    case trainCollector
}

enum AchievementCategory {
    case collection
    case challenge
    case mastery

    var title: String {
        switch self {
        case .collection:
            return "收集"
        case .challenge:
            return "挑战"
        case .mastery:
            return "技巧"
        }
    }

    var symbol: String {
        switch self {
        case .collection:
            return "◉"
        case .challenge:
            return "✦"
        case .mastery:
            return "⬢"
        }
    }
}

struct AchievementDefinition: Equatable {
    let id: AchievementID
    let title: String
    let detail: String
    let symbol: String
    let category: AchievementCategory
}

struct GameRunStats {
    var stepsSurvived = 0
    var fruitsByKind: [FruitKind: Int] = [:]
    var fruitsByEffect: [FruitEffect: Int] = [:]
    var missionCompleted = false
    var boostUses = 0
    var poopDrops = 0

    mutating func recordFruit(_ fruit: FruitDefinition) {
        fruitsByKind[fruit.kind, default: 0] += 1
        fruitsByEffect[fruit.effect, default: 0] += 1
    }

    func fruits(for kind: FruitKind) -> Int {
        fruitsByKind[kind, default: 0]
    }

    func fruits(with effect: FruitEffect) -> Int {
        fruitsByEffect[effect, default: 0]
    }

    var totalFruitsEaten: Int {
        fruitsByKind.values.reduce(0, +)
    }

    var totalSpecialFruitsEaten: Int {
        fruitsByEffect.reduce(into: 0) { partialResult, entry in
            if entry.key != .normal {
                partialResult += entry.value
            }
        }
    }

    var uniqueFruitKindsEaten: Int {
        fruitsByKind.filter { $0.value > 0 }.count
    }
}

struct GameProgressSummary {
    let unlockedAchievements: Int
    let totalAchievements: Int
}

enum CodexSection: CaseIterable {
    case fruits
    case effects
    case mechanics
    case levels

    var title: String {
        switch self {
        case .fruits:
            return "水果"
        case .effects:
            return "特效"
        case .mechanics:
            return "机关"
        case .levels:
            return "地图"
        }
    }

    var symbol: String {
        switch self {
        case .fruits:
            return "🍎"
        case .effects:
            return "✨"
        case .mechanics:
            return "⚙"
        case .levels:
            return "🗺"
        }
    }
}

struct CodexEntryDefinition: Equatable {
    let id: String
    let title: String
    let detail: String
    let symbol: String
    let section: CodexSection
}

enum CodexCatalog {
    static let mechanicEntries: [CodexEntryDefinition] = [
        CodexEntryDefinition(id: "mechanic_sweeper", title: "横扫机关", detail: "一排障碍在走廊里来回横扫。", symbol: "↔", section: .mechanics),
        CodexEntryDefinition(id: "mechanic_gate", title: "中央闸门", detail: "会周期性开启和闭合的水闸。", symbol: "▥", section: .mechanics),
        CodexEntryDefinition(id: "mechanic_rotor", title: "旋刃机关", detail: "围绕中心切换方向的旋转刀阵。", symbol: "✶", section: .mechanics),
        CodexEntryDefinition(id: "mechanic_crusher", title: "夹壁机关", detail: "上下石壁会向中间缓慢合拢。", symbol: "⬍", section: .mechanics),
        CodexEntryDefinition(id: "mechanic_collapse", title: "塌陷地板", detail: "走过的尾迹会短暂塌陷，不能立刻回头。", symbol: "▧", section: .mechanics)
    ]

    static var fruitEntries: [CodexEntryDefinition] {
        FruitKind.allCases.map {
            CodexEntryDefinition(
                id: fruitID(for: $0),
                title: $0.name,
                detail: $0 == .pomelo ? "吃到后增加 2 节。" : "吃到后增加 1 节。",
                symbol: $0.symbol,
                section: .fruits
            )
        }
    }

    static var effectEntries: [CodexEntryDefinition] {
        FruitEffect.allCases.map {
            CodexEntryDefinition(
                id: effectID(for: $0),
                title: $0 == .normal ? "普通果实" : "\($0.title)果实",
                detail: effectDetail(for: $0),
                symbol: $0 == .normal ? "•" : $0.badge,
                section: .effects
            )
        }
    }

    static func levelEntries(names: [String]) -> [CodexEntryDefinition] {
        names.map { name in
            CodexEntryDefinition(
                id: levelID(for: name),
                title: name,
                detail: levelDetail(for: name),
                symbol: levelSymbol(for: name),
                section: .levels
            )
        }
    }

    static func entries(for section: CodexSection, levelNames: [String]) -> [CodexEntryDefinition] {
        switch section {
        case .fruits:
            return fruitEntries
        case .effects:
            return effectEntries
        case .mechanics:
            return mechanicEntries
        case .levels:
            return levelEntries(names: levelNames)
        }
    }

    static func all(levelNames: [String]) -> [CodexEntryDefinition] {
        CodexSection.allCases.flatMap { entries(for: $0, levelNames: levelNames) }
    }

    static func fruitID(for kind: FruitKind) -> String {
        "fruit_\(kind.name)"
    }

    static func effectID(for effect: FruitEffect) -> String {
        switch effect {
        case .normal:
            return "effect_normal"
        case .golden:
            return "effect_golden"
        case .frost:
            return "effect_frost"
        case .ghost:
            return "effect_ghost"
        case .warp:
            return "effect_warp"
        case .bomb:
            return "effect_bomb"
        }
    }

    static func levelID(for name: String) -> String {
        "level_\(name)"
    }

    static func mechanicID(for level: LevelDefinition) -> String? {
        if level.hasCollapsingTiles {
            return "mechanic_collapse"
        }

        guard let mechanic = level.dynamicMechanic else {
            return nil
        }

        switch mechanic {
        case .sweeper:
            return "mechanic_sweeper"
        case .pulseGate:
            return "mechanic_gate"
        case .rotor:
            return "mechanic_rotor"
        case .crusher:
            return "mechanic_crusher"
        }
    }

    private static func effectDetail(for effect: FruitEffect) -> String {
        switch effect {
        case .normal:
            return "基础果实，没有额外效果。"
        case .golden:
            return "得分翻倍，适合冲分。"
        case .frost:
            return "短时间减速，给你更多反应时间。"
        case .ghost:
            return "短时间允许穿过自己。"
        case .warp:
            return "短时间允许穿墙，从另一侧穿出。"
        case .bomb:
            return "会在周围炸出临时危险区。"
        }
    }

    private static func levelSymbol(for name: String) -> String {
        switch name {
        case "草地":
            return "🌿"
        case "门廊":
            return "🏛"
        case "双塔":
            return "🗼"
        case "斗兽场":
            return "🏟"
        case "折返跑":
            return "〰"
        case "回旋走廊":
            return "↔"
        case "水闸":
            return "🚪"
        case "风车庭院":
            return "✶"
        case "石壁夹道":
            return "🧱"
        case "浮桥":
            return "🌉"
        default:
            return "◻"
        }
    }

    private static func levelDetail(for name: String) -> String {
        switch name {
        case "草地":
            return "空旷新手图，适合熟悉方向。"
        case "门廊":
            return "上下横墙留出中间通道。"
        case "双塔":
            return "左右双塔会把路线切成三段。"
        case "斗兽场":
            return "中心封闭区域要求你绕外圈跑。"
        case "折返跑":
            return "横向障碍让你不断折返换线。"
        case "回旋走廊":
            return "中段有会左右横扫的机关。"
        case "水闸":
            return "中央闸门会周期性打开和关闭。"
        case "风车庭院":
            return "中央旋刃会轮流切换方向。"
        case "石壁夹道":
            return "上下夹壁会向中间慢慢合拢。"
        case "浮桥":
            return "尾迹会塌陷，回头会更危险。"
        default:
            return "一张未知地图。"
        }
    }
}

enum AchievementCatalog {
    static let all: [AchievementDefinition] = [
        AchievementDefinition(id: .firstFruit, title: "第一口", detail: "第一次吃到水果", symbol: "🍎", category: .collection),
        AchievementDefinition(id: .pomeloCollector, title: "柚子专家", detail: "单局吃到 3 个柚子", symbol: "🍊", category: .collection),
        AchievementDefinition(id: .goldenHunter, title: "金彩猎手", detail: "单局吃到 2 个金彩水果", symbol: "✦", category: .challenge),
        AchievementDefinition(id: .longTail, title: "长尾进化", detail: "蛇身长度达到 18", symbol: "🐍", category: .mastery),
        AchievementDefinition(id: .missionStarter, title: "任务达人", detail: "完成任意一局任务", symbol: "✓", category: .challenge),
        AchievementDefinition(id: .hazardRunner, title: "机关舞者", detail: "在机关关卡拿到 80 分", symbol: "⚙", category: .mastery),
        AchievementDefinition(id: .rainbowPicnic, title: "彩虹野餐", detail: "单局吃到全部 5 种水果", symbol: "🌈", category: .collection),
        AchievementDefinition(id: .speedster, title: "喷射车手", detail: "单局使用 1 次加速", symbol: "⚡", category: .mastery),
        AchievementDefinition(id: .poopTrail, title: "便便尾迹", detail: "单局甩出 3 团便便残留", symbol: "💩", category: .challenge),
        AchievementDefinition(id: .trainCollector, title: "列车长", detail: "极简模式下收集 4 种水果车厢", symbol: "🚂", category: .collection)
    ]

    static func definition(for id: AchievementID) -> AchievementDefinition? {
        all.first(where: { $0.id == id })
    }

    static func unlockedAchievements(snapshot: GameSnapshot, runStats: GameRunStats) -> [AchievementDefinition] {
        var unlocked: [AchievementDefinition] = []

        if runStats.totalFruitsEaten > 0 {
            append(.firstFruit, to: &unlocked)
        }
        if runStats.fruits(for: .pomelo) >= 3 {
            append(.pomeloCollector, to: &unlocked)
        }
        if runStats.fruits(with: .golden) >= 2 {
            append(.goldenHunter, to: &unlocked)
        }
        if snapshot.snake.count >= 18 {
            append(.longTail, to: &unlocked)
        }
        if runStats.missionCompleted {
            append(.missionStarter, to: &unlocked)
        }
        if snapshot.level.dynamicMechanic != nil && snapshot.score >= 80 {
            append(.hazardRunner, to: &unlocked)
        }
        if runStats.uniqueFruitKindsEaten >= FruitKind.allCases.count {
            append(.rainbowPicnic, to: &unlocked)
        }
        if runStats.boostUses >= 1 {
            append(.speedster, to: &unlocked)
        }
        if runStats.poopDrops >= 3 {
            append(.poopTrail, to: &unlocked)
        }
        if snapshot.isSimpleModeEnabled && runStats.uniqueFruitKindsEaten >= 4 {
            append(.trainCollector, to: &unlocked)
        }

        return unlocked
    }

    private static func append(_ id: AchievementID, to achievements: inout [AchievementDefinition]) {
        guard let definition = definition(for: id) else {
            return
        }
        achievements.append(definition)
    }
}

enum DynamicObstacleStyle {
    case sweeper
    case gate
    case rotor
    case crusher
}

enum TemporaryHazardStyle {
    case collapse
    case bomb
    case poop
}

struct DynamicObstacleSnapshot {
    let points: [GridPoint]
    let style: DynamicObstacleStyle
}

struct TemporaryHazardSnapshot {
    let points: [GridPoint]
    let style: TemporaryHazardStyle
}

struct SweeperDefinition: Equatable {
    let row: Int
    let minX: Int
    let maxX: Int
    let length: Int

    func points(at tick: Int) -> [GridPoint] {
        let startPositions = max(1, maxX - minX - length + 2)
        let period = startPositions > 1 ? (startPositions - 1) * 2 : 1
        let phase = tick % period
        let reflected = phase < startPositions ? phase : (period - phase)
        let startX = minX + reflected

        return (0 ..< length).map { GridPoint(x: startX + $0, y: row) }
    }

    func statusText(at tick: Int) -> String {
        let startPositions = max(1, maxX - minX - length + 2)
        if startPositions == 1 {
            return "横扫机关: 固定封锁第 \(row + 1) 行"
        }

        let period = (startPositions - 1) * 2
        let phase = tick % period
        let movingRight = phase < (startPositions - 1)
        return movingRight
            ? "横扫机关: 第 \(row + 1) 行向右推进"
            : "横扫机关: 第 \(row + 1) 行向左回扫"
    }
}

struct PulseGateDefinition: Equatable {
    let closedPoints: [GridPoint]
    let closedDuration: Int
    let openDuration: Int

    func activePoints(at tick: Int) -> [GridPoint] {
        let cycle = max(1, closedDuration + openDuration)
        let phase = tick % cycle
        return phase < closedDuration ? closedPoints : []
    }

    func statusText(at tick: Int) -> String {
        let cycle = max(1, closedDuration + openDuration)
        let phase = tick % cycle
        if phase < closedDuration {
            let remaining = closedDuration - phase
            return "中央闸门: 封闭中，\(remaining) 步后开启"
        } else {
            let remaining = cycle - phase
            return "中央闸门: 开启中，\(remaining) 步后闭合"
        }
    }
}

struct RotorDefinition: Equatable {
    let center: GridPoint
    let armLength: Int
    let holdTicks: Int

    func points(at tick: Int) -> [GridPoint] {
        let phase = max(0, tick / max(1, holdTicks)) % 4
        let directions: [(Int, Int)]

        switch phase {
        case 0:
            directions = [(0, 1), (0, -1)]
        case 1:
            directions = [(1, 1), (-1, -1)]
        case 2:
            directions = [(1, 0), (-1, 0)]
        default:
            directions = [(1, -1), (-1, 1)]
        }

        var occupied = [center]
        for (dx, dy) in directions {
            occupied += (1 ... armLength).map {
                GridPoint(x: center.x + dx * $0, y: center.y + dy * $0)
            }
        }
        return occupied
    }

    func statusText(at tick: Int) -> String {
        let phase = max(0, tick / max(1, holdTicks)) % 4
        switch phase {
        case 0:
            return "旋刃机关: 纵向切割"
        case 1:
            return "旋刃机关: 斜向掠过"
        case 2:
            return "旋刃机关: 横向切割"
        default:
            return "旋刃机关: 反斜切换"
        }
    }
}

struct CrusherDefinition: Equatable {
    let minY: Int
    let maxY: Int
    let fromX: Int
    let toX: Int

    func points(at tick: Int) -> [GridPoint] {
        let steps = max(1, (maxY - minY) / 2)
        let period = steps > 1 ? (steps - 1) * 2 : 1
        let phase = tick % period
        let reflected = phase < steps ? phase : (period - phase)
        let topY = minY + reflected
        let bottomY = maxY - reflected

        let top = (fromX ... toX).map { GridPoint(x: $0, y: topY) }
        let bottom = (fromX ... toX).map { GridPoint(x: $0, y: bottomY) }
        return top + bottom
    }

    func statusText(at tick: Int) -> String {
        let steps = max(1, (maxY - minY) / 2)
        if steps == 1 {
            return "夹壁机关: 保持压缩"
        }
        let period = (steps - 1) * 2
        let phase = tick % period
        let movingInward = phase < (steps - 1)
        return movingInward ? "夹壁机关: 向内合拢" : "夹壁机关: 缓慢退开"
    }
}

enum DynamicMechanicDefinition: Equatable {
    case sweeper(SweeperDefinition)
    case pulseGate(PulseGateDefinition)
    case rotor(RotorDefinition)
    case crusher(CrusherDefinition)

    func snapshot(at tick: Int) -> DynamicObstacleSnapshot {
        switch self {
        case .sweeper(let definition):
            return DynamicObstacleSnapshot(points: definition.points(at: tick), style: .sweeper)
        case .pulseGate(let definition):
            return DynamicObstacleSnapshot(points: definition.activePoints(at: tick), style: .gate)
        case .rotor(let definition):
            return DynamicObstacleSnapshot(points: definition.points(at: tick), style: .rotor)
        case .crusher(let definition):
            return DynamicObstacleSnapshot(points: definition.points(at: tick), style: .crusher)
        }
    }

    func statusText(at tick: Int) -> String {
        switch self {
        case .sweeper(let definition):
            return definition.statusText(at: tick)
        case .pulseGate(let definition):
            return definition.statusText(at: tick)
        case .rotor(let definition):
            return definition.statusText(at: tick)
        case .crusher(let definition):
            return definition.statusText(at: tick)
        }
    }
}

struct LevelDefinition: Equatable {
    let name: String
    let columns: Int
    let rows: Int
    let tickDuration: TimeInterval
    let obstacles: Set<GridPoint>
    let dynamicMechanic: DynamicMechanicDefinition?
    let hasCollapsingTiles: Bool
}

struct GameSnapshot {
    let level: LevelDefinition
    let modifier: RunModifier
    let mission: MissionDefinition
    let missionProgress: MissionProgress
    let isSimpleModeEnabled: Bool
    let currentDirection: Direction
    let childSafetyBrakeAvailable: Bool
    let snake: [GridPoint]
    let trainCarriages: [FruitKind?]
    let dynamicObstacle: DynamicObstacleSnapshot?
    let temporaryHazards: [TemporaryHazardSnapshot]
    let fruitPosition: GridPoint?
    let fruit: FruitDefinition?
    let fruitCountdown: Int?
    let score: Int
    let highScore: Int
    let fruitsEaten: Int
    let stepsSurvived: Int
    let comboCount: Int
    let comboBonus: Int
    let boostMovesRemaining: Int
    let isGameOver: Bool
    let statusText: String
    let hintText: String
    let activeEffectText: String?
    let mechanicText: String?
}

struct BoostStatusSnapshot {
    let isReady: Bool
    let chargeProgress: Double
    let cooldownRemaining: TimeInterval
    let isHeld: Bool
    let hasEnoughLength: Bool
}

enum SpeedPreset: String, CaseIterable {
    case relaxed
    case standard
    case turbo

    var title: String {
        switch self {
        case .relaxed:
            return "轻松"
        case .standard:
            return "标准"
        case .turbo:
            return "极速"
        }
    }

    var tickMultiplier: Double {
        switch self {
        case .relaxed:
            return 1.12
        case .standard:
            return 1.0
        case .turbo:
            return 0.88
        }
    }
}

struct GameSettings: Equatable {
    var soundEnabled: Bool
    var musicEnabled: Bool
    var speedPreset: SpeedPreset
    var simpleModeEnabled: Bool

    static let `default` = GameSettings(
        soundEnabled: true,
        musicEnabled: true,
        speedPreset: .standard,
        simpleModeEnabled: false
    )
}

enum MainMenuOption: CaseIterable {
    case start
    case reroll
    case achievements
    case codex
    case help
    case settings
    case quit

    var title: String {
        switch self {
        case .start:
            return "开始本局"
        case .reroll:
            return "换一张图"
        case .achievements:
            return "成就图鉴"
        case .codex:
            return "收藏图鉴"
        case .help:
            return "玩法帮助"
        case .settings:
            return "设置"
        case .quit:
            return "退出游戏"
        }
    }
}

enum SettingsOption: CaseIterable {
    case sound
    case music
    case simpleMode
    case speed
    case back

    var title: String {
        switch self {
        case .sound:
            return "音效"
        case .music:
            return "音乐"
        case .simpleMode:
            return "模式"
        case .speed:
            return "速度"
        case .back:
            return "返回主菜单"
        }
    }
}

enum GameOverOption: CaseIterable {
    case replay
    case mainMenu
    case achievements

    var title: String {
        switch self {
        case .replay:
            return "再来一局"
        case .mainMenu:
            return "回到主菜单"
        case .achievements:
            return "查看成就"
        }
    }

    var symbol: String {
        switch self {
        case .replay:
            return "↻"
        case .mainMenu:
            return "⌂"
        case .achievements:
            return "★"
        }
    }
}

enum OverlayMenuLayout {
    case list
    case achievementGrid
}

struct OverlayMenuItem {
    let title: String
    let subtitle: String?
    let icon: String?
    let badge: String?
    let isDimmed: Bool
}

struct OverlayMenuState {
    let title: String
    let subtitle: String
    let detail: String?
    let items: [OverlayMenuItem]
    let selectedIndex: Int?
    let footer: String
    let layout: OverlayMenuLayout
}

struct RunHistorySummary {
    let totalRuns: Int
    let bestLength: Int
    let lastScore: Int
    let lastLength: Int
    let lastLevelName: String
    let lastMissionTitle: String
    let lastMissionCompleted: Bool

    static let empty = RunHistorySummary(
        totalRuns: 0,
        bestLength: 0,
        lastScore: 0,
        lastLength: 0,
        lastLevelName: "尚无记录",
        lastMissionTitle: "尚无记录",
        lastMissionCompleted: false
    )
}

enum SceneMode {
    case mainMenu
    case achievements
    case codex
    case help
    case ready
    case playing
    case paused
    case gameOver
    case settings
}

enum GameEvent {
    case ateFruit(fruit: FruitDefinition, at: GridPoint, points: Int)
    case comboAdvanced(count: Int, bonus: Int)
    case fruitExpired(FruitDefinition)
    case bombTriggered
    case boostActivated
    case floorCollapsed
    case safetyBrake
    case gameOver
    case highScoreUpdated(Int)
    case missionCompleted(MissionDefinition)
    case achievementUnlocked(AchievementDefinition)
}
