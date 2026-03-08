//
//  GameRendererOverlaySupport.swift
//  贪吃蛇
//
//  Created by Codex on 2026/3/8.
//

import Foundation

struct RendererOverlaySectionSpec {
    let title: String
    let icon: String
    let startIndex: Int
}

enum GameRendererOverlaySupport {
    static func supportsHover(in mode: SceneMode) -> Bool {
        switch mode {
        case .gameSelection, .gameConstruction, .snakeModeSelection, .mainMenu, .battleSetup, .battleSummary, .familyOverview, .familyDetail, .achievements, .achievementDetail, .leaderboard, .codex, .codexDetail, .help, .settings, .gameOver:
            return true
        case .ready, .playing, .paused:
            return false
        }
    }

    static func detailText(
        for overlayMenu: OverlayMenuState,
        mode: SceneMode,
        hoveredIndex: Int?
    ) -> String? {
        if let hoveredIndex,
           hoveredIndex >= 0,
           hoveredIndex < overlayMenu.items.count,
           let detail = overlayMenu.items[hoveredIndex].detail ?? overlayMenu.items[hoveredIndex].subtitle {
            return detail
        }

        switch mode {
        case .gameSelection:
            return "悬停查看游戏或角色"
        case .gameConstruction:
            return "悬停查看入口"
        case .snakeModeSelection:
            return "悬停查看要进入的玩法模式"
        case .codexDetail, .achievementDetail:
            return overlayMenu.detail
        case .mainMenu:
            return "图标和角标表示当前状态"
        case .battleSetup:
            return "悬停查看对战设置"
        case .battleSummary:
            return "悬停查看对战表现"
        case .familyOverview:
            return "悬停成员卡片"
        case .familyDetail:
            return "悬停条目"
        case .achievements:
            return "悬停成就"
        case .leaderboard:
            return "悬停成绩"
        case .codex:
            return "悬停条目"
        case .help:
            return "悬停查看规则"
        case .settings:
            return "悬停查看设置"
        case .gameOver:
            return "悬停查看选项"
        case .ready, .playing, .paused:
            return overlayMenu.detail
        }
    }

    static func lineSpacing(for itemCount: Int) -> CGFloat {
        switch itemCount {
        case 0 ... 5:
            return 34
        case 6 ... 7:
            return 31
        case 8 ... 10:
            return 27
        default:
            return 24
        }
    }

    static func sections(for mode: SceneMode) -> [RendererOverlaySectionSpec] {
        switch mode {
        case .mainMenu:
            return [
                RendererOverlaySectionSpec(title: "对局", icon: "▶", startIndex: 0),
                RendererOverlaySectionSpec(title: "资料", icon: "✦", startIndex: 5),
                RendererOverlaySectionSpec(title: "系统", icon: "⚙", startIndex: 9)
            ]
        case .battleSetup:
            return [
                RendererOverlaySectionSpec(title: "出战成员", icon: "👥", startIndex: 0),
                RendererOverlaySectionSpec(title: "赛制", icon: "🏁", startIndex: 4),
                RendererOverlaySectionSpec(title: "开始", icon: "▶", startIndex: 5)
            ]
        case .battleSummary:
            return [
                RendererOverlaySectionSpec(title: "最终排名", icon: "🏆", startIndex: 0)
            ]
        case .gameSelection:
            return []
        case .snakeModeSelection:
            return [
                RendererOverlaySectionSpec(title: "玩法模式", icon: "🎯", startIndex: 0)
            ]
        case .familyOverview:
            return [
                RendererOverlaySectionSpec(title: "角色档位", icon: "🧑", startIndex: 0)
            ]
        case .familyDetail:
            return [
                RendererOverlaySectionSpec(title: "角色管理", icon: "⚙", startIndex: 0),
                RendererOverlaySectionSpec(title: "最近战绩", icon: "🕘", startIndex: 3)
            ]
        case .settings:
            return [
                RendererOverlaySectionSpec(title: "音频", icon: "♪", startIndex: 0),
                RendererOverlaySectionSpec(title: "玩法", icon: "➤", startIndex: 2),
                RendererOverlaySectionSpec(title: "角色", icon: "🧑", startIndex: 5),
                RendererOverlaySectionSpec(title: "外观", icon: "🎨", startIndex: 10),
                RendererOverlaySectionSpec(title: "返回", icon: "⌂", startIndex: 11)
            ]
        default:
            return []
        }
    }
}
