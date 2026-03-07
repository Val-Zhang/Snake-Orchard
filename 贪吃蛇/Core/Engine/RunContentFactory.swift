//
//  RunContentFactory.swift
//  贪吃蛇
//
//  Created by zhangwang on 2026/3/7.
//

import Foundation

struct RunContentFactory {
    func randomModifier() -> RunModifier {
        RunModifier.allCases.randomElement() ?? .harvestRush
    }

    func randomMission(for level: LevelDefinition, modifier: RunModifier) -> MissionDefinition {
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
