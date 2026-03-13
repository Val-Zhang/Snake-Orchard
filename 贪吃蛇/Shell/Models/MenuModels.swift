//
//  MenuModels.swift
//  贪吃蛇
//
//  Created by Codex on 2026/3/8.
//

import SpriteKit

enum MainMenuOption: CaseIterable {
    case resume
    case start
    case gameCollection
    case dailyChallenge
    case reroll
    case achievements
    case familyOverview
    case leaderboard
    case codex
    case help
    case settings
    case quit

    var title: String {
        switch self {
        case .resume:
            return "继续上一局"
        case .start:
            return "开始本局"
        case .gameCollection:
            return "返回游戏目录"
        case .dailyChallenge:
            return "每日挑战"
        case .reroll:
            return "换一张图"
        case .achievements:
            return "成就图鉴"
        case .familyOverview:
            return "角色选择"
        case .leaderboard:
            return "排行榜"
        case .codex:
            return "收藏图鉴"
        case .help:
            return "玩法帮助"
        case .settings:
            return "设置"
        case .quit:
            return "返回主页"
        }
    }
}

enum GameCollectionOption: CaseIterable {
    case snake
    case brickBreaker

    var title: String {
        switch self {
        case .snake:
            return "贪吃蛇"
        case .brickBreaker:
            return "打砖块"
        }
    }
}

enum SnakeEntryModeOption: CaseIterable {
    case singlePlayer
    case battle

    var title: String {
        switch self {
        case .singlePlayer:
            return "单人模式"
        case .battle:
            return "对战模式"
        }
    }
}

enum CharacterSelectionFlow {
    case launchSnake
    case manageProfiles
}

enum SettingsOption: CaseIterable {
    case sound
    case music
    case simpleMode
    case manualStepMode
    case speed
    case familyMember
    case familyHitPoints
    case characterDefinition
    case familyAvatar
    case familyAccent
    case familyReset
    case theme
    case back

    var title: String {
        switch self {
        case .sound:
            return "音效"
        case .music:
            return "音乐"
        case .simpleMode:
            return "模式"
        case .manualStepMode:
            return "手动步进"
        case .speed:
            return "速度"
        case .familyMember:
            return "当前角色"
        case .familyHitPoints:
            return "血量"
        case .characterDefinition:
            return "角色定义"
        case .familyAvatar:
            return "角色头像"
        case .familyAccent:
            return "角色颜色"
        case .familyReset:
            return "重置角色"
        case .theme:
            return "皮肤"
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
    case gameSelectionCards
}

struct OverlayMenuItem {
    let title: String
    let subtitle: String?
    let detail: String?
    let icon: String?
    let badge: String?
    let accentColor: SKColor?
    let isDimmed: Bool

    init(
        title: String,
        subtitle: String? = nil,
        detail: String? = nil,
        icon: String? = nil,
        badge: String? = nil,
        accentColor: SKColor? = nil,
        isDimmed: Bool
    ) {
        self.title = title
        self.subtitle = subtitle
        self.detail = detail
        self.icon = icon
        self.badge = badge
        self.accentColor = accentColor
        self.isDimmed = isDimmed
    }
}

struct OverlayTabItem {
    let title: String
    let icon: String?
    let isSelected: Bool
}

struct OverlayMenuState {
    let title: String
    let subtitle: String
    let detail: String?
    let items: [OverlayMenuItem]
    let tabs: [OverlayTabItem]
    let selectedIndex: Int?
    let footer: String
    let layout: OverlayMenuLayout
}

enum LeaderboardScope: CaseIterable {
    case overall
    case dailyChallenge
    case family

    var title: String {
        switch self {
        case .overall:
            return "总榜"
        case .dailyChallenge:
            return "每日挑战"
        case .family:
            return "角色榜"
        }
    }

    var symbol: String {
        switch self {
        case .overall:
            return "🏆"
        case .dailyChallenge:
            return "📅"
        case .family:
            return "🧑"
        }
    }
}

enum SceneMode {
    case gameSelection
    case gameConstruction
    case snakeModeSelection
    case mainMenu
    case battleSetup
    case battleSummary
    case familyOverview
    case familyDetail
    case achievements
    case achievementDetail
    case leaderboard
    case codex
    case codexDetail
    case help
    case ready
    case playing
    case paused
    case gameOver
    case settings
}
