//
//  GameScenePresentationBuilder.swift
//  贪吃蛇
//
//  Created by Codex on 2026/3/8.
//

import Foundation
import SpriteKit

enum GameScenePresentationBuilder {
    static func familyDetailItems(
        member: FamilyMember,
        currentMember: FamilyMember,
        displayName: String,
        memberTitle: String,
        accentColor: SKColor,
        recentRuns: [RunLeaderboardEntry],
        bestEntry: RunLeaderboardEntry?
    ) -> [OverlayMenuItem] {
        let managementItems = [
            OverlayMenuItem(
                title: "设为当前成员",
                subtitle: member == currentMember ? "正在使用" : "切换到这个角色",
                detail: member == currentMember
                    ? "这个角色已经是当前使用中的身份。"
                    : "之后的成绩、排行榜和对战记录都会记到这个角色名下。",
                icon: "✓",
                badge: member == currentMember ? "当前" : nil,
                accentColor: accentColor,
                isDimmed: false
            ),
            OverlayMenuItem(
                title: "编辑昵称",
                subtitle: displayName,
                detail: "打开输入框修改这个角色的昵称。留空会恢复默认名 \(memberTitle)。",
                icon: "✎",
                badge: nil,
                accentColor: accentColor,
                isDimmed: false
            ),
            OverlayMenuItem(
                title: "恢复默认外观",
                subtitle: "昵称 / 头像 / 颜色",
                detail: "把这个角色的昵称、头像和颜色恢复成默认值，不影响别的角色。",
                icon: "↺",
                badge: nil,
                accentColor: accentColor,
                isDimmed: false
            )
        ]

        let runItems: [OverlayMenuItem]
        if recentRuns.isEmpty {
            runItems = [
                OverlayMenuItem(
                    title: "最近战绩",
                    subtitle: "还没有记录",
                    detail: "这个角色还没有开始过对局。先切到这个角色并玩几局，最近战绩就会显示在这里。",
                    icon: "—",
                    badge: nil,
                    accentColor: accentColor,
                    isDimmed: true
                )
            ]
        } else {
            runItems = recentRuns.enumerated().map { index, entry in
                let modeText = entry.isSimpleModeEnabled ? "极简" : "标准"
                let challengeText = entry.isDailyChallenge ? " · 每日" : ""
                let missionText = entry.missionCompleted ? "任务完成" : "任务未完成"
                let isBestEntry = bestEntry.map {
                    $0.timestamp == entry.timestamp && $0.score == entry.score && $0.length == entry.length
                } ?? false
                return OverlayMenuItem(
                    title: "第 \(index + 1) 局 · \(entry.score) 分",
                    subtitle: "长度 \(entry.length) · \(entry.levelName) · \(formattedDate(entry.timestamp, formatter: GameScene.leaderboardDateFormatter))",
                    detail: "\(modeText)\(challengeText)\n任务: \(entry.missionTitle) · \(missionText)\n记录时间: \(formattedDate(entry.timestamp, formatter: GameScene.leaderboardDateFormatter))",
                    icon: isBestEntry ? "★" : rankIcon(for: index),
                    badge: isBestEntry ? "个人最佳" : missionText,
                    accentColor: accentColor,
                    isDimmed: false
                )
            }
        }

        return managementItems + runItems
    }

    static func familyDetailSubtitle(
        member: FamilyMember,
        currentMember: FamilyMember,
        avatarTitle: String,
        accentTitle: String,
        familySummary: FamilyLeaderboardEntry?
    ) -> String {
        let memberTag = member == currentMember ? "当前成员" : member.title
        let summary = familySummary.map {
            "最佳 \($0.bestScore) 分 · 长度 \($0.bestLength) · \($0.runCount) 局"
        } ?? "还没有成绩记录"
        return "\(memberTag) · \(avatarTitle) · \(accentTitle)\n\(summary)"
    }

    static func codexCompletionText(total: Int, current: Int) -> String {
        guard total > 0 else {
            return "0%"
        }
        let percent = Int((Double(current) / Double(total) * 100).rounded())
        return "\(percent)%"
    }

    static func codexUnlockHint(for entry: CodexEntryDefinition?, discovered: Bool) -> String {
        guard let entry else {
            return "当前分类没有更多条目。"
        }
        if discovered {
            return "你已经解锁了这条记录。"
        }

        switch entry.section {
        case .fruits:
            return "吃到对应水果后就会记录。"
        case .effects:
            return "遇到对应特效果实时会记录。"
        case .mechanics:
            return "进入带有对应机关的地图即可记录。"
        case .levels:
            return "开始这张地图的一局后就会记录。"
        }
    }

    static func settingsDescription(
        for option: SettingsOption,
        settings: GameSettings,
        unlockedThemeCount: Int,
        totalThemeCount: Int,
        currentMemberName: String,
        currentMemberSymbol: String,
        currentAvatar: FamilyAvatar,
        currentAccent: FamilyAccent
    ) -> String {
        let currentPlayMode = settings.playMode(for: settings.familyMember)
        switch option {
        case .theme:
            return "\(settings.visualTheme.symbol) \(settings.visualTheme.title) · \(settings.visualTheme.detail)\n\(settings.visualTheme.unlockHint) · 已解锁 \(unlockedThemeCount)/\(totalThemeCount)"
        case .familyMember:
            return "\(currentMemberSymbol) \(currentMemberName) · \(settings.familyMember.detail)\n当前绑定模式：\(currentPlayMode.title)。左右切换角色槽位，空格编辑当前昵称。"
        case .familyHitPoints:
            return "\(currentMemberSymbol) \(currentMemberName) 当前血量 \(settings.hitPointHearts(for: settings.familyMember))。\n每撞一次墙、障碍、自己或危险区都会先扣 1 格 ❤️，原地停下等你换方向；归零才结束。左右调整当前角色的默认血量。"
        case .characterDefinition:
            return "进入当前角色的定义入口。后面扩展虚拟头像、角色档案和更多角色能力时，会继续复用这条链路。"
        case .familyAvatar:
            return "\(currentAvatar.symbol) \(currentAvatar.title) · \(currentAvatar.detail)\n左右切换当前角色头像。角色榜和主菜单会同步显示。"
        case .familyAccent:
            return "\(currentAccent.symbol) \(currentAccent.title) · \(currentAccent.detail)\n左右切换当前角色的边框色。角色榜和设置项会同步高亮。"
        case .familyReset:
            return "把当前角色的昵称、头像和颜色恢复成默认值，不会影响其它角色。"
        case .simpleMode:
            return currentPlayMode.isSimpleModeEnabled
                ? "\(currentMemberName) 当前是 \(currentPlayMode.title)。儿童模式会限制为更简单的关卡和普通水果，并屏蔽极速档。"
                : "\(currentMemberName) 当前是标准模式。切到儿童模式后，这个成员后续单人和对战都会沿用。"
        case .manualStepMode:
            return currentPlayMode.isSimpleModeEnabled
                ? (currentPlayMode.isManualStepEnabled
                    ? "\(currentMemberName) 已开启手动步进。蛇不会自动前进，只有你按方向键或手柄方向时才会走一步。"
                    : "\(currentMemberName) 现在是儿童自动模式。开启后会切成极简手动，后续对战也会沿用。")
                : "这个开关只在儿童模式下生效。先把当前家庭成员切到儿童模式，再决定是否开启手动步进。"
        case .speed:
            return "速度会直接影响当前与下一局的移动节奏。极简模式下只开放轻松和标准。"
        case .sound, .music:
            return "音效和音乐会立即应用到菜单和对局。"
        case .back:
            return "返回主菜单，当前设置会自动保存。"
        }
    }

    static func gameOverDetail(for option: GameOverOption, placement: RunLeaderboardPlacement?, currentScore: Int) -> String {
        switch option {
        case .replay:
            if placement?.personalBestImproved == true {
                return "这局已经刷新了当前家庭成员的个人最佳，试试看能不能再往上推一点。"
            }
            if let previousBestScore = placement?.previousBestScore {
                let scoreGap = max(0, previousBestScore - currentScore)
                if scoreGap == 0 {
                    return "你已经追平这个成员的最高分了，再多 1 节长度就能超越个人最佳。"
                }
                return "距离这个成员的个人最佳还差 \(scoreGap) 分。再来一局冲一下。"
            }
            return "用当前这局的模式重新开始，再冲一次更高分。"
        case .mainMenu:
            return "回到主菜单，重新选择模式、图鉴或设置。"
        case .achievements:
            return "打开成就页，查看这局有没有推进新的解锁条件。"
        }
    }

    static func leaderboardHeadline(
        for scope: LeaderboardScope,
        leaderboardEntries: [RunLeaderboardEntry],
        familyEntries: [FamilyLeaderboardEntry],
        displayName: (FamilyMember) -> String,
        displaySymbol: (FamilyMember) -> String
    ) -> String {
        switch scope {
        case .family:
            guard let champion = familyEntries.first else {
                return "角色最佳成绩"
            }
            return "角色冠军 \(displaySymbol(champion.member))\(displayName(champion.member)) · \(champion.bestScore) 分"
        case .overall, .dailyChallenge:
            guard let best = leaderboardEntries.first else {
                return scope == .overall ? "本机前 10 名成绩" : "每日挑战前 10 名"
            }
            return "榜首 \(best.score) 分 · 最长 \(best.length) 节"
        }
    }

    static func leaderboardDetail(for entry: RunLeaderboardEntry, rank: Int) -> String {
        let mode = entry.isSimpleModeEnabled ? "极简模式" : "标准模式"
        let challenge = entry.isDailyChallenge ? " · 每日挑战" : ""
        let mission = entry.missionCompleted ? "已完成任务" : "任务未完成"
        return "#\(rank) · \(mode)\(challenge)\n关卡: \(entry.levelName)\n任务: \(entry.missionTitle) · \(mission)\n记录时间: \(formattedDate(entry.timestamp, formatter: GameScene.leaderboardDateFormatter))"
    }

    static func familyLeaderboardDetail(
        for entry: FamilyLeaderboardEntry,
        rank: Int,
        lastPersonalBestMember: FamilyMember?,
        displayName: (FamilyMember) -> String
    ) -> String {
        let crown = rank == 1 ? "当前家庭冠军" : "家庭榜第 \(rank) 名"
        let refreshText = lastPersonalBestMember == entry.member ? "\n刚刚刷新了个人最佳。" : ""
        return "\(crown)\n昵称: \(displayName(entry.member))\n最佳成绩: \(entry.bestScore) 分 · 最长 \(entry.bestLength) 节\n出战局数: \(entry.runCount) · 每日挑战 \(entry.dailyChallengeCount) 局\n最近游戏: \(formattedDate(entry.latestTimestamp, formatter: GameScene.leaderboardDateFormatter))\(refreshText)"
    }

    static func familyLeaderboardBadge(
        for entry: FamilyLeaderboardEntry,
        rank: Int,
        currentMember: FamilyMember,
        lastPersonalBestMember: FamilyMember?,
        accentSymbol: String
    ) -> String {
        if lastPersonalBestMember == entry.member {
            return rank == 1 ? "\(accentSymbol) 新纪录冠军" : "\(accentSymbol) 刚刷新"
        }
        if entry.member == currentMember {
            return rank == 1 ? "\(accentSymbol) 当前冠军" : "\(accentSymbol) 当前成员"
        }
        return rank == 1 ? "\(accentSymbol) 家庭冠军" : "\(accentSymbol) 出战 \(entry.runCount)"
    }

    static func rankIcon(for index: Int) -> String {
        switch index {
        case 0:
            return "🥇"
        case 1:
            return "🥈"
        case 2:
            return "🥉"
        default:
            return "•"
        }
    }

    static func formattedDate(_ timestamp: TimeInterval, formatter: DateFormatter) -> String {
        formatter.string(from: Date(timeIntervalSince1970: timestamp))
    }
}
