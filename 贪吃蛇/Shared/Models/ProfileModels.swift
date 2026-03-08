//
//  ProfileModels.swift
//  贪吃蛇
//
//  Created by Codex on 2026/3/8.
//

import SpriteKit

enum VisualTheme: String, CaseIterable {
    case orchard
    case sunset
    case mint
    case neon
    case motorcade
    case police
    case construction
    case racing

    var title: String {
        switch self {
        case .orchard:
            return "果园"
        case .sunset:
            return "落日"
        case .mint:
            return "薄荷"
        case .neon:
            return "霓虹"
        case .motorcade:
            return "车队"
        case .police:
            return "警车"
        case .construction:
            return "工程车"
        case .racing:
            return "赛车"
        }
    }

    var symbol: String {
        switch self {
        case .orchard:
            return "🍃"
        case .sunset:
            return "🌇"
        case .mint:
            return "🍬"
        case .neon:
            return "🌌"
        case .motorcade:
            return "🚗"
        case .police:
            return "🚓"
        case .construction:
            return "🚧"
        case .racing:
            return "🏁"
        }
    }

    var detail: String {
        switch self {
        case .orchard:
            return "经典果园涂装，清新明亮。"
        case .sunset:
            return "暖橙落日列车，像傍晚巡游。"
        case .mint:
            return "薄荷糖配色，车头像糖果小火车。"
        case .neon:
            return "霓虹夜行列车，灯带更醒目。"
        case .motorcade:
            return "整条贪吃蛇都会变成小汽车车队。"
        case .police:
            return "整条贪吃蛇都会变成巡逻警车车队。"
        case .construction:
            return "整条贪吃蛇都会变成工程施工车队。"
        case .racing:
            return "整条贪吃蛇都会变成高速赛车车队。"
        }
    }

    var unlockHint: String {
        switch self {
        case .orchard:
            return "默认可用"
        case .sunset:
            return "解锁条件: 金彩猎手"
        case .mint:
            return "解锁条件: 列车长"
        case .neon:
            return "解锁条件: 机关舞者"
        case .motorcade:
            return "默认可用"
        case .police:
            return "默认可用"
        case .construction:
            return "默认可用"
        case .racing:
            return "默认可用"
        }
    }

    var unlockAchievementID: AchievementID? {
        switch self {
        case .orchard:
            return nil
        case .sunset:
            return .goldenHunter
        case .mint:
            return .trainCollector
        case .neon:
            return .hazardRunner
        case .motorcade:
            return nil
        case .police:
            return nil
        case .construction:
            return nil
        case .racing:
            return nil
        }
    }

    var usesVehicleCollectibles: Bool {
        switch self {
        case .motorcade, .police, .construction, .racing:
            return true
        default:
            return false
        }
    }

    func collectibleName(for kind: FruitKind) -> String {
        guard usesVehicleCollectibles else {
            return kind.name
        }

        switch self {
        case .motorcade:
            switch kind {
            case .banana:
                return "出租车"
            case .apple:
                return "小轿车"
            case .pomelo:
                return "越野车"
            case .watermelon:
                return "皮卡"
            case .peach:
                return "跑车"
            }
        case .police:
            switch kind {
            case .banana:
                return "巡逻警车"
            case .apple:
                return "警用轿车"
            case .pomelo:
                return "防暴警车"
            case .watermelon:
                return "警用皮卡"
            case .peach:
                return "摩托警车"
            }
        case .construction:
            switch kind {
            case .banana:
                return "挖掘机"
            case .apple:
                return "推土机"
            case .pomelo:
                return "吊车"
            case .watermelon:
                return "翻斗车"
            case .peach:
                return "水泥车"
            }
        case .racing:
            switch kind {
            case .banana:
                return "卡丁车"
            case .apple:
                return "拉力赛车"
            case .pomelo:
                return "耐力赛车"
            case .watermelon:
                return "超跑"
            case .peach:
                return "方程式赛车"
            }
        case .orchard, .sunset, .mint, .neon:
            return kind.name
        }
    }

    func collectibleSymbol(for kind: FruitKind) -> String {
        guard usesVehicleCollectibles else {
            return kind.symbol
        }

        switch self {
        case .motorcade:
            switch kind {
            case .banana:
                return "🚕"
            case .apple:
                return "🚗"
            case .pomelo:
                return "🚙"
            case .watermelon:
                return "🛻"
            case .peach:
                return "🏎️"
            }
        case .police:
            switch kind {
            case .banana:
                return "🚓"
            case .apple:
                return "🚔"
            case .pomelo:
                return "🚐"
            case .watermelon:
                return "🛻"
            case .peach:
                return "🏍️"
            }
        case .construction:
            switch kind {
            case .banana:
                return "🚜"
            case .apple:
                return "🚛"
            case .pomelo:
                return "🏗️"
            case .watermelon:
                return "🚚"
            case .peach:
                return "🚒"
            }
        case .racing:
            switch kind {
            case .banana:
                return "🏎️"
            case .apple:
                return "🚗"
            case .pomelo:
                return "🚘"
            case .watermelon:
                return "🚙"
            case .peach:
                return "🏁"
            }
        case .orchard, .sunset, .mint, .neon:
            return kind.symbol
        }
    }

    var residueSymbol: String {
        switch self {
        case .motorcade:
            return "🚗"
        case .police:
            return "🚓"
        case .construction:
            return "🚜"
        case .racing:
            return "🏎️"
        default:
            return "💩"
        }
    }

    var collectibleLabelTitle: String {
        usesVehicleCollectibles ? "当前车辆" : "当前水果"
    }
}

enum ThemeCatalog {
    static func unlockedThemes(for achievementIDs: Set<AchievementID>) -> [VisualTheme] {
        VisualTheme.allCases.filter { theme in
            guard let unlockAchievementID = theme.unlockAchievementID else {
                return true
            }
            return achievementIDs.contains(unlockAchievementID)
        }
    }
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

enum FamilyMember: String, CaseIterable, Codable, Hashable {
    case memberOne
    case memberTwo
    case memberThree
    case memberFour

    var title: String {
        switch self {
        case .memberOne:
            return "爸爸"
        case .memberTwo:
            return "柚柚"
        case .memberThree:
            return "伙伴甲"
        case .memberFour:
            return "伙伴乙"
        }
    }

    var symbol: String {
        switch self {
        case .memberOne:
            return "🚗"
        case .memberTwo:
            return "🚙"
        case .memberThree:
            return "🏎"
        case .memberFour:
            return "🚕"
        }
    }

    var detail: String {
        switch self {
        case .memberOne:
            return "默认预设的家长角色。"
        case .memberTwo:
            return "默认预设的小朋友角色。"
        case .memberThree:
            return "额外预留的角色档位。"
        case .memberFour:
            return "额外预留的角色档位。"
        }
    }
}

enum FamilyAvatar: String, CaseIterable, Codable, Hashable {
    case hatchback
    case suv
    case race
    case taxi
    case police
    case truck
    case bus
    case tractor

    var symbol: String {
        switch self {
        case .hatchback:
            return "🚗"
        case .suv:
            return "🚙"
        case .race:
            return "🏎"
        case .taxi:
            return "🚕"
        case .police:
            return "🚓"
        case .truck:
            return "🚚"
        case .bus:
            return "🚌"
        case .tractor:
            return "🚜"
        }
    }

    var title: String {
        switch self {
        case .hatchback:
            return "小轿车"
        case .suv:
            return "越野车"
        case .race:
            return "赛车"
        case .taxi:
            return "出租车"
        case .police:
            return "警车"
        case .truck:
            return "货车"
        case .bus:
            return "巴士"
        case .tractor:
            return "拖拉机"
        }
    }

    var detail: String {
        switch self {
        case .hatchback:
            return "经典小轿车头像，适合通用成员。"
        case .suv:
            return "更敦实的越野车头像。"
        case .race:
            return "速度感最强的赛车头像。"
        case .taxi:
            return "醒目的出租车头像。"
        case .police:
            return "带一点警灯感的警车头像。"
        case .truck:
            return "更像运输担当的货车头像。"
        case .bus:
            return "圆润醒目的巴士头像。"
        case .tractor:
            return "有点童趣的拖拉机头像。"
        }
    }
}

enum FamilyAccent: String, CaseIterable, Codable, Hashable {
    case orchard
    case sky
    case sunset
    case mint
    case grape
    case coral

    var title: String {
        switch self {
        case .orchard:
            return "果园绿"
        case .sky:
            return "天空蓝"
        case .sunset:
            return "落日橙"
        case .mint:
            return "薄荷青"
        case .grape:
            return "葡萄紫"
        case .coral:
            return "珊瑚红"
        }
    }

    var symbol: String {
        switch self {
        case .orchard:
            return "🟢"
        case .sky:
            return "🔵"
        case .sunset:
            return "🟠"
        case .mint:
            return "🩵"
        case .grape:
            return "🟣"
        case .coral:
            return "🔴"
        }
    }

    var detail: String {
        switch self {
        case .orchard:
            return "偏自然的果园绿色边框。"
        case .sky:
            return "更清爽的天空蓝边框。"
        case .sunset:
            return "更活泼的落日橙边框。"
        case .mint:
            return "轻快柔和的薄荷青边框。"
        case .grape:
            return "更显眼的葡萄紫边框。"
        case .coral:
            return "热闹醒目的珊瑚红边框。"
        }
    }

    var color: SKColor {
        switch self {
        case .orchard:
            return SKColor(calibratedRed: 0.54, green: 0.86, blue: 0.38, alpha: 1.0)
        case .sky:
            return SKColor(calibratedRed: 0.48, green: 0.76, blue: 1.0, alpha: 1.0)
        case .sunset:
            return SKColor(calibratedRed: 1.0, green: 0.70, blue: 0.34, alpha: 1.0)
        case .mint:
            return SKColor(calibratedRed: 0.56, green: 0.92, blue: 0.84, alpha: 1.0)
        case .grape:
            return SKColor(calibratedRed: 0.80, green: 0.62, blue: 1.0, alpha: 1.0)
        case .coral:
            return SKColor(calibratedRed: 1.0, green: 0.52, blue: 0.50, alpha: 1.0)
        }
    }
}

struct GameSettings: Equatable {
    var soundEnabled: Bool
    var musicEnabled: Bool
    var speedPreset: SpeedPreset
    var simpleModeEnabled: Bool
    var manualStepModeEnabled: Bool
    var battleModeEnabled: Bool
    var battleParticipants: [FamilyMember]
    var battleRoundCount: Int
    var familyMember: FamilyMember
    var familyNicknames: [FamilyMember: String]
    var familyAvatars: [FamilyMember: FamilyAvatar]
    var familyAccents: [FamilyMember: FamilyAccent]
    var familyPlayModes: [FamilyMember: FamilyPlayMode]
    var visualTheme: VisualTheme

    func displayName(for member: FamilyMember) -> String {
        guard let nickname = familyNicknames[member]?.trimmingCharacters(in: .whitespacesAndNewlines),
              !nickname.isEmpty else {
            return member.title
        }
        return nickname
    }

    func avatar(for member: FamilyMember) -> FamilyAvatar {
        familyAvatars[member] ?? defaultAvatar(for: member)
    }

    func accent(for member: FamilyMember) -> FamilyAccent {
        familyAccents[member] ?? defaultAccent(for: member)
    }

    func playMode(for member: FamilyMember) -> FamilyPlayMode {
        familyPlayModes[member] ?? .standard
    }

    private func defaultAvatar(for member: FamilyMember) -> FamilyAvatar {
        switch member {
        case .memberOne:
            return .hatchback
        case .memberTwo:
            return .suv
        case .memberThree:
            return .race
        case .memberFour:
            return .taxi
        }
    }

    private func defaultAccent(for member: FamilyMember) -> FamilyAccent {
        switch member {
        case .memberOne:
            return .orchard
        case .memberTwo:
            return .sky
        case .memberThree:
            return .sunset
        case .memberFour:
            return .mint
        }
    }

    static let `default` = GameSettings(
        soundEnabled: true,
        musicEnabled: true,
        speedPreset: .standard,
        simpleModeEnabled: false,
        manualStepModeEnabled: false,
        battleModeEnabled: false,
        battleParticipants: BattleConfig.defaultConfig.participants,
        battleRoundCount: BattleConfig.defaultConfig.roundCount,
        familyMember: .memberOne,
        familyNicknames: [:],
        familyAvatars: [:],
        familyAccents: [:],
        familyPlayModes: [:],
        visualTheme: .orchard
    )
}

enum FamilyPlayMode: String, CaseIterable {
    case standard
    case simple
    case simpleManual

    var title: String {
        switch self {
        case .standard:
            return "标准"
        case .simple:
            return "儿童自动"
        case .simpleManual:
            return "极简手动"
        }
    }

    var detail: String {
        switch self {
        case .standard:
            return "标准玩法，会自动前进并开放完整内容。"
        case .simple:
            return "儿童模式，会自动前进，但会限制为更简单的内容。"
        case .simpleManual:
            return "儿童模式下的手动步进，只有按方向时才前进一步。"
        }
    }

    var isSimpleModeEnabled: Bool {
        switch self {
        case .standard:
            return false
        case .simple, .simpleManual:
            return true
        }
    }

    var isManualStepEnabled: Bool {
        self == .simpleManual
    }

    static func from(simpleModeEnabled: Bool, manualStepModeEnabled: Bool) -> FamilyPlayMode {
        guard simpleModeEnabled else {
            return .standard
        }
        return manualStepModeEnabled ? .simpleManual : .simple
    }
}
