//
//  RunContentFactory.swift
//  贪吃蛇
//
//  Created by zhangwang on 2026/3/7.
//

import Foundation

struct RunContentFactory {
    private enum DailyDifficulty {
        case relaxed
        case standard
        case intense
    }

    private struct SeededGenerator {
        private var state: UInt64

        init(seed: UInt64) {
            self.state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
        }

        mutating func nextInt(upperBound: Int) -> Int {
            guard upperBound > 0 else {
                return 0
            }
            state = 2862933555777941757 &* state &+ 3037000493
            return Int(state % UInt64(upperBound))
        }
    }

    func randomModifier(isSimpleModeEnabled: Bool = false) -> RunModifier {
        guard !isSimpleModeEnabled else {
            return .harvestRush
        }
        return RunModifier.allCases.randomElement() ?? .harvestRush
    }

    func randomMission(
        for level: LevelDefinition,
        modifier: RunModifier,
        isSimpleModeEnabled: Bool = false,
        unlockedRewards: Set<RewardUnlockID> = []
    ) -> MissionDefinition {
        if isSimpleModeEnabled {
            let stations = DeliveryStationCatalog.availableStations(for: unlockedRewards)
            var missions: [MissionDefinition] = [
                MissionDefinition(title: "开心采果", detail: "吃到 4 个水果", goal: .fruits(4)),
                MissionDefinition(title: "轻松冲分", detail: "本局拿到 50 分", goal: .score(50)),
                MissionDefinition(title: "尾巴变长", detail: "长度达到 8", goal: .reachLength(8)),
                MissionDefinition(title: "柚子尝鲜", detail: "吃到 1 个柚子", goal: .specificFruit(kind: .pomelo, count: 1)),
                MissionDefinition(title: "稳稳前进", detail: "活过 12 步", goal: .surviveSteps(12)),
                MissionDefinition(title: "彩虹列车", detail: "吃到 3 种不同水果", goal: .differentFruitKinds(3)),
                MissionDefinition(title: "香蕉专列", detail: "吃到 2 根香蕉", goal: .specificFruit(kind: .banana, count: 2)),
                MissionDefinition(title: "果香编组", detail: "收齐 香蕉、苹果、桃子 车厢", goal: .collectionSet([.banana, .apple, .peach])),
                MissionDefinition(title: "夏日列车", detail: "收齐 西瓜、柚子 车厢", goal: .collectionSet([.watermelon, .pomelo])),
                MissionDefinition(title: "甜甜车站", detail: "收齐 苹果、桃子 车厢", goal: .collectionSet([.apple, .peach]))
            ]
            if let orchardStation = stations.first(where: { $0.id == DeliveryStationCatalog.orchardStation.id }) {
                missions.append(
                    makeDeliveryMission(
                        title: "果园送货",
                        station: orchardStation,
                        requiredKinds: [.banana, .apple]
                    )
                )
            }
            if let sunnyStation = stations.first(where: { $0.id == DeliveryStationCatalog.sunnyStation.id }) {
                missions.append(
                    makeDeliveryMission(
                        title: "晴天送达",
                        station: sunnyStation,
                        requiredKinds: [.watermelon, .peach]
                    )
                )
            }
            if unlockedRewards.contains(.harborStations) {
                if let harborStation = stations.first(where: { $0.id == DeliveryStationCatalog.harborStation.id }) {
                    missions.append(
                        makeDeliveryMission(
                            title: "码头交接",
                            station: harborStation,
                            requiredKinds: [.banana, .pomelo]
                        )
                    )
                }
                if let starlightStation = stations.first(where: { $0.id == DeliveryStationCatalog.starlightStation.id }) {
                    missions.append(
                        makeDeliveryMission(
                            title: "星光快运",
                            station: starlightStation,
                            requiredKinds: [.apple, .peach, .watermelon]
                        )
                    )
                }
            }
            if unlockedRewards.contains(.paradeRoutes),
               let paradeStation = stations.first(where: { $0.id == DeliveryStationCatalog.paradeStation.id }) {
                missions.append(
                    makeDeliveryMission(
                        title: "巡游货运",
                        station: paradeStation,
                        requiredKinds: [.banana, .apple, .peach, .watermelon]
                    )
                )
            }
            return missions.randomElement() ?? missions[0]
        }

        var missions: [MissionDefinition] = [
            MissionDefinition(title: "果园采集", detail: "吃到 6 个水果", goal: .fruits(6)),
            MissionDefinition(title: "冲分挑战", detail: "本局拿到 90 分", goal: .score(90)),
            MissionDefinition(title: "长尾试炼", detail: "长度达到 12", goal: .reachLength(12)),
            MissionDefinition(title: "柚子收藏", detail: "吃到 2 个柚子", goal: .specificFruit(kind: .pomelo, count: 2)),
            MissionDefinition(title: "奇遇猎人", detail: "吃到 2 个特殊水果", goal: .specialFruit(2))
        ]

        if level.dynamicMechanic != nil {
            missions.append(
                MissionDefinition(title: "机关漫步", detail: "在机关图里活过 20 步", goal: .surviveSteps(20))
            )
        }

        switch modifier {
        case .harvestRush:
            missions.append(
                MissionDefinition(title: "丰收盛宴", detail: "在丰收词条下拿到 120 分", goal: .score(120))
            )
        case .swiftWinds:
            missions.append(
                MissionDefinition(title: "快节奏", detail: "在疾风词条下活过 24 步", goal: .surviveSteps(24))
            )
        case .luckyStars:
            missions.append(
                MissionDefinition(title: "好运来了", detail: "在奇遇词条下吃到 3 个特殊水果", goal: .specialFruit(3))
            )
        }

        return missions.randomElement() ?? missions[0]
    }

    func dailyChallenge(
        date: Date = Date(),
        levelFactory: LevelFactory,
        unlockedRewards: Set<RewardUnlockID>
    ) -> DailyChallengeDefinition {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 2026
        let month = components.month ?? 1
        let day = components.day ?? 1
        let numericDate = year * 10_000 + month * 100 + day
        var generator = SeededGenerator(seed: UInt64(numericDate))

        let levelPool = dailyLevelPool(levelFactory: levelFactory, unlockedRewards: unlockedRewards)
        let modifierPool: [RunModifier] = unlockedRewards.contains(.dailyFestivalPack)
            ? RunModifier.allCases
            : [.harvestRush, .swiftWinds]

        let level = levelPool[generator.nextInt(upperBound: levelPool.count)]
        let modifier = modifierPool[generator.nextInt(upperBound: modifierPool.count)]
        let difficulty = dailyDifficulty(for: level)
        let mission = dailyMission(
            level: level,
            modifier: modifier,
            unlockedRewards: unlockedRewards,
            generator: &generator
        )
        let titlePool = unlockedRewards.contains(.dailyFestivalPack)
            ? ["果园冲刺", "节拍快跑", "灯光列阵", "好运班列"]
            : ["每日热身", "今日冲分", "稳稳前进", "今日试炼"]
        let symbolPool = unlockedRewards.contains(.dailyFestivalPack)
            ? ["🎉", "🌟", "🎈", "🚩"]
            : ["📅", "☀️", "🍏", "⏱"]
        let title = "\(difficultyBadge(for: difficulty))\(titlePool[generator.nextInt(upperBound: titlePool.count)])"
        let symbol = symbolPool[generator.nextInt(upperBound: symbolPool.count)]
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        let dateText = formatter.string(from: date)
        let rewardSummary = unlockedRewards.contains(.dailyFestivalPack)
            ? "奖励内容加成已开启：今日挑战池更丰富 · 难度 \(difficultyText(for: difficulty))"
            : "完成今日任务，点亮每日挑战记录 · 难度 \(difficultyText(for: difficulty))"

        return DailyChallengeDefinition(
            id: "daily-\(numericDate)-\(level.name)-\(modifier.identifier)-\(mission.title)",
            dateText: dateText,
            title: title,
            detail: "\(level.name) · \(modifier.title) · \(mission.title)",
            symbol: symbol,
            level: level,
            modifier: modifier,
            mission: mission,
            rewardSummary: rewardSummary
        )
    }

    private func dailyMission(
        level: LevelDefinition,
        modifier: RunModifier,
        unlockedRewards: Set<RewardUnlockID>,
        generator: inout SeededGenerator
    ) -> MissionDefinition {
        let difficulty = dailyDifficulty(for: level)
        let fruitTarget: Int
        let scoreTarget: Int
        let lengthTarget: Int
        let surviveTarget: Int

        switch difficulty {
        case .relaxed:
            fruitTarget = 6
            scoreTarget = 90
            lengthTarget = 12
            surviveTarget = 20
        case .standard:
            fruitTarget = 7
            scoreTarget = 100
            lengthTarget = 13
            surviveTarget = 22
        case .intense:
            fruitTarget = 7
            scoreTarget = 110
            lengthTarget = 13
            surviveTarget = 24
        }

        var missions: [MissionDefinition] = [
            MissionDefinition(title: "今日采果", detail: "吃到 \(fruitTarget) 个水果", goal: .fruits(fruitTarget)),
            MissionDefinition(title: "今日高分", detail: "拿到 \(scoreTarget) 分", goal: .score(scoreTarget)),
            MissionDefinition(title: "今日长尾", detail: "长度达到 \(lengthTarget)", goal: .reachLength(lengthTarget))
        ]

        if level.dynamicMechanic != nil {
            missions.append(MissionDefinition(title: "机关值班", detail: "在机关图里活过 \(surviveTarget) 步", goal: .surviveSteps(surviveTarget)))
        }
        if modifier == .luckyStars || (unlockedRewards.contains(.dailyFestivalPack) && difficulty != .relaxed) {
            missions.append(MissionDefinition(title: "好运班列", detail: "吃到 3 个特殊水果", goal: .specialFruit(3)))
        }
        if unlockedRewards.contains(.dailyFestivalPack), difficulty != .relaxed {
            missions.append(MissionDefinition(title: "彩虹打卡", detail: "吃到 4 种不同水果", goal: .differentFruitKinds(4)))
        }

        return missions[generator.nextInt(upperBound: missions.count)]
    }

    private func makeDeliveryMission(
        title: String,
        station: DeliveryStationDefinition,
        requiredKinds: [FruitKind]
    ) -> MissionDefinition {
        let cargoText = requiredKinds.map(\.name).joined(separator: "、")
        let detail = "收齐 \(cargoText) 车厢后，开到 \(station.title)"
        return MissionDefinition(
            title: title,
            detail: detail,
            goal: .deliverRoute(DeliveryRouteDefinition(station: station, requiredKinds: requiredKinds))
        )
    }

    private func dailyLevelPool(levelFactory: LevelFactory, unlockedRewards: Set<RewardUnlockID>) -> [LevelDefinition] {
        let allLevels = levelFactory.allLevels(isSimpleModeEnabled: false)
        if unlockedRewards.contains(.dailyFestivalPack) {
            return allLevels
        }
        return allLevels.filter { level in
            !level.hasCollapsingTiles && level.name != "石壁夹道" && level.name != "风车庭院"
        }
    }

    private func dailyDifficulty(for level: LevelDefinition) -> DailyDifficulty {
        if level.hasCollapsingTiles || level.name == "石壁夹道" || level.name == "风车庭院" {
            return .intense
        }
        if level.dynamicMechanic != nil || level.name == "折返跑" {
            return .standard
        }
        return .relaxed
    }

    private func difficultyText(for difficulty: DailyDifficulty) -> String {
        switch difficulty {
        case .relaxed:
            return "轻松"
        case .standard:
            return "标准"
        case .intense:
            return "挑战"
        }
    }

    private func difficultyBadge(for difficulty: DailyDifficulty) -> String {
        switch difficulty {
        case .relaxed:
            return "轻松 · "
        case .standard:
            return "标准 · "
        case .intense:
            return "挑战 · "
        }
    }
}
