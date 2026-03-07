//
//  RunContentFactory.swift
//  贪吃蛇
//
//  Created by zhangwang on 2026/3/7.
//

import Foundation

struct RunContentFactory {
    func randomModifier(isSimpleModeEnabled: Bool = false) -> RunModifier {
        guard !isSimpleModeEnabled else {
            return .harvestRush
        }
        return RunModifier.allCases.randomElement() ?? .harvestRush
    }

    func randomMission(for level: LevelDefinition, modifier: RunModifier, isSimpleModeEnabled: Bool = false) -> MissionDefinition {
        if isSimpleModeEnabled {
            let missions: [MissionDefinition] = [
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
}
