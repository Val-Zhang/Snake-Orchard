//
//  GameSceneOverlayMenuFactory.swift
//  贪吃蛇
//
//  Created by Codex on 2026/3/8.
//

import Foundation
import SpriteKit

enum GameSceneOverlayMenuFactory {
    static func gameSelection(
        currentMember: FamilyMember,
        currentCharacterName: String,
        currentCharacterSymbol: String,
        currentCharacterAccent: FamilyAccent,
        currentCharacterAvatar: FamilyAvatar,
        currentCharacterPlayMode: FamilyPlayMode,
        displayName: (FamilyMember) -> String,
        displaySymbol: (FamilyMember) -> String,
        avatar: (FamilyMember) -> FamilyAvatar,
        accent: (FamilyMember) -> FamilyAccent,
        selectedIndex: Int
    ) -> OverlayMenuState {
        let gameItems = GameCollectionOption.allCases.map { option in
            switch option {
            case .snake:
                return OverlayMenuItem(
                    title: option.title,
                    subtitle: nil,
                    detail: "进入现有的贪吃蛇，并直接使用下方当前选中的默认角色开始。",
                    icon: "▶",
                    badge: "可玩",
                    accentColor: currentCharacterAccent.color,
                    isDimmed: false
                )
            case .brickBreaker:
                return OverlayMenuItem(
                    title: option.title,
                    subtitle: "建设中",
                    detail: "后续会补成新的亲子小游戏，目前先预留入口。",
                    icon: "⧉",
                    badge: "建设中",
                    isDimmed: false
                )
            }
        }

        let roleItems = FamilyMember.allCases.map { member in
            let isCurrent = member == currentMember
            let roleDetail = isCurrent
                ? "当前默认角色，绑定玩法：\(currentCharacterPlayMode.title)"
                : "点击后会变成进入游戏的默认角色。"
            return OverlayMenuItem(
                title: displayName(member),
                subtitle: isCurrent ? "默认角色" : avatar(member).title,
                detail: "\(displaySymbol(member)) \(displayName(member))\n\(avatar(member).detail)\n\(roleDetail)",
                icon: avatar(member).symbol,
                badge: isCurrent ? currentCharacterPlayMode.title : nil,
                accentColor: accent(member).color,
                isDimmed: false
            )
        }
        let settingsItem = OverlayMenuItem(
            title: "角色设置",
            subtitle: "修改名字和头像",
            detail: "进入当前默认角色的设置入口。现在可以继续改昵称、头像和颜色，后面会继续扩展虚拟头像等角色定义能力。",
            icon: "⚙️",
            badge: "入口",
            accentColor: currentCharacterAccent.color,
            isDimmed: false
        )

        return OverlayMenuState(
            title: "小游乐场",
            subtitle: "默认角色：\(currentCharacterAvatar.symbol) \(currentCharacterName)",
            detail: "选择游戏后直接进入，下方可切换默认角色",
            items: gameItems + roleItems + [settingsItem],
            tabs: [],
            selectedIndex: selectedIndex,
            footer: "上/下选择游戏 · 左/右切换角色 · 空格确认 · Esc 退出应用",
            layout: .gameSelectionCards
        )
    }

    static func gameConstruction() -> OverlayMenuState {
        OverlayMenuState(
            title: "打砖块",
            subtitle: "建设中",
            detail: "这个入口已经预留好，后面会接成新的亲子小游戏。",
            items: [
                OverlayMenuItem(
                    title: "返回游戏合集",
                    subtitle: nil,
                    detail: "回到游戏列表，继续选择贪吃蛇或等待新游戏上线。",
                    icon: "⌂",
                    badge: nil,
                    isDimmed: false
                )
            ],
            tabs: [],
            selectedIndex: 0,
            footer: "空格返回 · Esc 返回",
            layout: .list
        )
    }

    static func snakeModeSelection(selectedIndex: Int) -> OverlayMenuState {
        let items = SnakeEntryModeOption.allCases.map { option in
            switch option {
            case .singlePlayer:
                return OverlayMenuItem(
                    title: option.title,
                    subtitle: nil,
                    detail: nil,
                    icon: "🧍",
                    badge: "单人",
                    isDimmed: false
                )
            case .battle:
                return OverlayMenuItem(
                    title: option.title,
                    subtitle: nil,
                    detail: nil,
                    icon: "⚔️",
                    badge: "多人",
                    isDimmed: false
                )
            }
        }

        return OverlayMenuState(
            title: "贪吃蛇",
            subtitle: "先选择要进入的玩法模式",
            detail: "单人和对战会进入不同的配置菜单",
            items: items,
            tabs: [],
            selectedIndex: selectedIndex,
            footer: "上/下选择 · 空格确认 · Esc 返回游戏目录",
            layout: .list
        )
    }

    static func mainMenu(
        settings: GameSettings,
        currentMemberName: String,
        currentMemberSymbol: String,
        currentMemberAvatarSymbol: String,
        currentMemberAccent: FamilyAccent,
        dailyChallenge: DailyChallengeDefinition,
        dailyCompleted: Bool,
        rewardSummary: String,
        recentDiscoveries: String,
        mainMenuSelection: Int,
        hasResumableRun: Bool,
        leaderboardSubtitle: String,
        leaderboardDetail: String,
        leaderboardBadge: String,
        leaderboardEntriesEmpty: Bool,
        codexDiscoveredCount: Int,
        codexTotalCount: Int
        ) -> OverlayMenuState {
        let modeSubtitle: String
        if settings.manualStepModeEnabled {
            modeSubtitle = "\(currentMemberSymbol) \(currentMemberName) · 极简手动 · 只有按方向才会前进"
        } else if settings.simpleModeEnabled {
            modeSubtitle = "\(currentMemberSymbol) \(currentMemberName) · 极简模式 · 更慢更简单"
        } else {
            modeSubtitle = "\(currentMemberSymbol) \(currentMemberName) · 随机地图、随机词条、随机任务"
        }
        return OverlayMenuState(
            title: "贪吃蛇 · 单人模式",
            subtitle: modeSubtitle,
            detail: "图标和角标表示当前状态",
            items: MainMenuOption.allCases.map { option in
                switch option {
                case .resume:
                    return OverlayMenuItem(
                        title: option.title,
                        subtitle: nil,
                        detail: nil,
                        icon: "⟲",
                        badge: hasResumableRun ? "可恢复" : "暂无",
                        isDimmed: !hasResumableRun
                    )
                case .start:
                    return OverlayMenuItem(
                        title: option.title,
                        subtitle: nil,
                        detail: nil,
                        icon: "▶",
                        badge: "单人",
                        isDimmed: false
                    )
                case .gameCollection:
                    return OverlayMenuItem(
                        title: option.title,
                        subtitle: nil,
                        detail: nil,
                        icon: "🎮",
                        badge: "主页",
                        isDimmed: false
                    )
                case .dailyChallenge:
                    return OverlayMenuItem(
                        title: option.title,
                        subtitle: nil,
                        detail: nil,
                        icon: "📅",
                        badge: dailyCompleted ? "完成" : dailyChallenge.symbol,
                        isDimmed: false
                    )
                case .reroll:
                    return OverlayMenuItem(title: option.title, subtitle: nil, detail: nil, icon: "↻", badge: nil, isDimmed: false)
                case .achievements:
                    return OverlayMenuItem(title: option.title, subtitle: nil, detail: nil, icon: "★", badge: rewardSummary, isDimmed: false)
                case .familyOverview:
                    return OverlayMenuItem(
                        title: option.title,
                        subtitle: nil,
                        detail: nil,
                        icon: "🧑",
                        badge: currentMemberAvatarSymbol,
                        accentColor: currentMemberAccent.color,
                        isDimmed: false
                    )
                case .leaderboard:
                    return OverlayMenuItem(
                        title: option.title,
                        subtitle: nil,
                        detail: nil,
                        icon: "🏆",
                        badge: leaderboardBadge,
                        accentColor: currentMemberAccent.color,
                        isDimmed: leaderboardEntriesEmpty
                    )
                case .codex:
                    return OverlayMenuItem(
                        title: option.title,
                        subtitle: nil,
                        detail: nil,
                        icon: "📘",
                        badge: "\(codexDiscoveredCount)/\(codexTotalCount)",
                        isDimmed: false
                    )
                case .help:
                    return OverlayMenuItem(title: option.title, subtitle: nil, detail: nil, icon: "?", badge: nil, isDimmed: false)
                case .settings:
                    return OverlayMenuItem(title: option.title, subtitle: nil, detail: nil, icon: "⚙", badge: nil, isDimmed: false)
                case .quit:
                    return OverlayMenuItem(title: option.title, subtitle: nil, detail: nil, icon: "⌂", badge: "主页", isDimmed: false)
                }
            },
            tabs: [],
            selectedIndex: mainMenuSelection,
            footer: "上/下选择 · 空格确认 · Esc 关闭子页",
            layout: .list
        )
    }

    static func battleSetup(
        config: BattleConfig,
        selectedIndex: Int,
        displayName: (FamilyMember) -> String,
        displaySymbol: (FamilyMember) -> String,
        playMode: (FamilyMember) -> FamilyPlayMode,
        accent: (FamilyMember) -> FamilyAccent,
        familyEntries: [FamilyLeaderboardEntry]
    ) -> OverlayMenuState {
        let participantItems = FamilyMember.allCases.map { member in
            let summary = familyEntries.first(where: { $0.member == member })
            let selected = config.contains(member)
            let memberPlayMode = playMode(member)
            return OverlayMenuItem(
                title: displayName(member),
                subtitle: summary.map { "\(memberPlayMode.title) · 最佳 \($0.bestScore) 分 · \(selected ? "已出战" : "休息")" } ?? "\(memberPlayMode.title) · \(selected ? "已出战" : "休息")",
                detail: summary.map {
                    "\(displaySymbol(member)) \(displayName(member)) · \(memberPlayMode.title)\n最佳成绩 \($0.bestScore) 分 · 最长 \($0.bestLength) 节\n出战 \($0.runCount) 局 · 每日挑战 \($0.dailyChallengeCount) 局\n空格可切换是否参加本次对战。"
                } ?? "\(displaySymbol(member)) \(displayName(member)) · \(memberPlayMode.title)\n还没有历史成绩。\n空格可切换是否参加本次对战。",
                icon: displaySymbol(member),
                badge: selected ? memberPlayMode.title : "休息",
                accentColor: accent(member).color,
                isDimmed: false
            )
        }

        let setupItems = participantItems + [
            OverlayMenuItem(
                title: "比赛轮次",
                subtitle: "\(config.roundCount) 轮",
                detail: "每位出战成员都会在每一轮各玩一局。儿童成员会保留自己的模式绑定，手动步进成员也会照常按键一步一步走。",
                icon: "🏁",
                badge: "共 \(config.totalMatches) 场",
                isDimmed: false
            ),
            OverlayMenuItem(
                title: "开始对战",
                subtitle: config.isValid ? "已选 \(config.participants.count) 位成员" : "至少选择 2 位成员",
                detail: config.isValid
                    ? "开始家庭对战。系统会按顺序让每位成员轮流出战，最后汇总总分、单局最佳和轮次胜场。"
                    : "至少要选择 2 位家庭成员才能开始对战。",
                icon: "▶",
                badge: config.isValid ? "开始" : "未就绪",
                isDimmed: !config.isValid
            ),
            OverlayMenuItem(
                title: "取消",
                subtitle: nil,
                detail: "退出对战设置，回到主菜单。",
                icon: "⌂",
                badge: nil,
                isDimmed: false
            )
        ]

        return OverlayMenuState(
            title: "角色对战",
            subtitle: "选择出战成员和轮次",
            detail: "悬停条目查看说明",
            items: setupItems,
            tabs: [],
            selectedIndex: selectedIndex,
            footer: "上/下选择 · 左/右调轮次 · 空格切换/确认 · Esc 返回主菜单",
            layout: .list
        )
    }

    static func battleSummary(
        summary: BattleSummary,
        results: [BattleRoundResult],
        displayName: (FamilyMember) -> String,
        displaySymbol: (FamilyMember) -> String,
        accent: (FamilyMember) -> FamilyAccent
    ) -> OverlayMenuState {
        let items = summary.standings.enumerated().map { index, standing in
            let memberResults = results
                .filter { $0.member == standing.member }
                .sorted { $0.round < $1.round }
                .map { "第\($0.round)轮 \($0.score)分/\($0.length)节" }
                .joined(separator: " · ")
            return OverlayMenuItem(
                title: "#\(index + 1)  \(displaySymbol(standing.member)) \(displayName(standing.member))",
                subtitle: "总分 \(standing.totalScore) · 胜场 \(standing.roundWins) · 场均 \(standing.averageScore)",
                detail: "单局最佳 \(standing.bestScore) 分 · 最长 \(standing.bestLength) 节\n总长度 \(standing.totalLength) · 共 \(standing.roundsPlayed) 局\n分轮表现: \(memberResults)",
                icon: GameScenePresentationBuilder.rankIcon(for: index),
                badge: index == 0 ? "冠军" : "\(standing.roundWins) 胜",
                accentColor: accent(standing.member).color,
                isDimmed: false
            )
        }

        return OverlayMenuState(
            title: "对战汇总",
            subtitle: summary.champion.map { "冠军：\(displaySymbol($0.member)) \(displayName($0.member)) · \(summary.totalRounds) 轮 \(summary.totalMatches) 场" } ?? "本次对战已结束",
            detail: "悬停成绩查看每轮表现",
            items: items,
            tabs: [],
            selectedIndex: nil,
            footer: "空格或 Esc 返回主菜单",
            layout: .list
        )
    }

    static func familyOverview(
        currentMember: FamilyMember,
        familyOverviewSelection: Int,
        selectionFlow: CharacterSelectionFlow,
        familyLeaderboardEntries: [FamilyLeaderboardEntry],
        displayName: (FamilyMember) -> String,
        displaySymbol: (FamilyMember) -> String,
        avatar: (FamilyMember) -> FamilyAvatar,
        accent: (FamilyMember) -> FamilyAccent
    ) -> OverlayMenuState {
        let items = FamilyMember.allCases.map { member in
            let entry = familyLeaderboardEntries.first(where: { $0.member == member })
            let bestScore = entry?.bestScore ?? 0
            let bestLength = entry?.bestLength ?? 0
            let runCount = entry?.runCount ?? 0
            let statusBadge: String
            if member == currentMember {
                statusBadge = selectionFlow == .launchSnake ? "默认角色" : "当前角色"
            } else if runCount == 0 {
                statusBadge = selectionFlow == .launchSnake ? "可选角色" : "未出战"
            } else {
                statusBadge = "\(runCount) 局"
            }
            let subtitle = runCount == 0
                ? "\(displaySymbol(member)) \(member.title)"
                : "最佳 \(bestScore) 分 · 长度 \(bestLength)"
            let detail = """
            \(displaySymbol(member)) \(displayName(member))
            默认档位: \(member.title)
            头像: \(avatar(member).title) · 颜色: \(accent(member).title)
            出战: \(runCount) 局\(entry.map { " · 每日挑战 \($0.dailyChallengeCount) 局" } ?? "")
            \(runCount == 0 ? "还没有这位成员的对局记录。" : "空格或点击即可切换为当前成员。")
            """
            return OverlayMenuItem(
                title: displayName(member),
                subtitle: subtitle,
                detail: detail,
                icon: displaySymbol(member),
                badge: statusBadge,
                accentColor: accent(member).color,
                isDimmed: runCount == 0 && member != currentMember
            )
        }
        return OverlayMenuState(
            title: selectionFlow == .launchSnake ? "选择角色" : "角色总览",
            subtitle: selectionFlow == .launchSnake
                ? "当前默认：\(displaySymbol(currentMember)) \(displayName(currentMember))"
                : "当前角色：\(displaySymbol(currentMember)) \(displayName(currentMember))",
            detail: selectionFlow == .launchSnake ? "选一个角色进入贪吃蛇" : "悬停角色卡片查看详情",
            items: items,
            tabs: [],
            selectedIndex: familyOverviewSelection,
            footer: selectionFlow == .launchSnake
                ? "方向键切换 · 空格使用该角色进入游戏 · Esc 返回游戏合集"
                : "方向键切换 · 空格查看详情 · Esc 返回主菜单",
            layout: .achievementGrid
        )
    }

    static func familyDetail(
        member: FamilyMember,
        items: [OverlayMenuItem],
        subtitle: String,
        displayName: (FamilyMember) -> String,
        displaySymbol: (FamilyMember) -> String,
        selectedIndex: Int
    ) -> OverlayMenuState {
        OverlayMenuState(
            title: "\(displaySymbol(member)) \(displayName(member))",
            subtitle: subtitle,
            detail: "悬停条目查看详情",
            items: items,
            tabs: [],
            selectedIndex: selectedIndex,
            footer: "上/下选择 · 空格确认 · Esc 返回总览",
            layout: .list
        )
    }

    static func leaderboard(
        scope: LeaderboardScope,
        familyEntries: [FamilyLeaderboardEntry],
        leaderboardEntries: [RunLeaderboardEntry],
        headline: String,
        displayName: (FamilyMember) -> String,
        displaySymbol: (FamilyMember) -> String,
        accent: (FamilyMember) -> FamilyAccent,
        familyDetail: (FamilyLeaderboardEntry, Int) -> String,
        familyBadge: (FamilyLeaderboardEntry, Int) -> String,
        entryDetail: (RunLeaderboardEntry, Int) -> String,
        entryBadge: (RunLeaderboardEntry) -> String,
        rankIcon: (Int) -> String,
        formattedDate: (TimeInterval) -> String
    ) -> OverlayMenuState {
        let items: [OverlayMenuItem]
        switch scope {
        case .family:
            items = familyEntries.isEmpty
                ? [
                    OverlayMenuItem(
                        title: "暂无家庭成绩",
                        subtitle: "先切换成员开始几局",
                        detail: "家庭榜会按成员汇总最佳分数、最长长度和出战局数。",
                        icon: "—",
                        badge: nil,
                        isDimmed: true
                    )
                ]
                : familyEntries.enumerated().map { index, entry in
                    OverlayMenuItem(
                        title: "#\(index + 1)  \(displaySymbol(entry.member)) \(displayName(entry.member))",
                        subtitle: "\(entry.bestScore) 分 · \(entry.bestLength) 节 · \(entry.runCount) 局",
                        detail: familyDetail(entry, index + 1),
                        icon: rankIcon(index),
                        badge: familyBadge(entry, index + 1),
                        accentColor: accent(entry.member).color,
                        isDimmed: false
                    )
                }
        case .overall, .dailyChallenge:
            items = leaderboardEntries.isEmpty
                ? [
                    OverlayMenuItem(
                        title: "暂无成绩",
                        subtitle: "先开始几局再来看看",
                        detail: "排行榜会记录本机前 10 名成绩，按分数优先、长度次之排序。",
                        icon: "—",
                        badge: nil,
                        isDimmed: true
                    )
                ]
                : leaderboardEntries.enumerated().map { index, entry in
                    OverlayMenuItem(
                        title: "#\(index + 1)  \(entry.score) 分",
                        subtitle: "\(entry.length) 节 · \(entry.levelName)",
                        detail: entryDetail(entry, index + 1),
                        icon: rankIcon(index),
                        badge: entryBadge(entry),
                        isDimmed: false
                    )
                }
        }
        return OverlayMenuState(
            title: "排行榜",
            subtitle: headline,
            detail: "悬停成绩查看详情",
            items: items,
            tabs: LeaderboardScope.allCases.map { itemScope in
                OverlayTabItem(title: itemScope.title, icon: itemScope.symbol, isSelected: itemScope == scope)
            },
            selectedIndex: nil,
            footer: "空格或 Esc 返回主菜单",
            layout: .list
        )
    }

    static func achievements(
        selectedIndex: Int,
        unlockedCount: Int,
        totalCount: Int,
        items: [OverlayMenuItem]
    ) -> OverlayMenuState {
        OverlayMenuState(
            title: "成就图鉴",
            subtitle: "已解锁 \(unlockedCount)/\(totalCount)",
            detail: "悬停成就查看条件",
            items: items,
            tabs: [],
            selectedIndex: selectedIndex,
            footer: "方向键切换 · 空格查看详情 · Esc 返回主菜单",
            layout: .achievementGrid
        )
    }

    static func achievementDetail(
        achievement: AchievementDefinition,
        progress: AchievementProgress,
        rewardText: String
    ) -> OverlayMenuState {
        OverlayMenuState(
            title: "\(achievement.symbol) \(achievement.title)",
            subtitle: "\(achievement.category.title) · \(progress.isUnlocked ? "已解锁" : "未解锁")",
            detail: achievement.detail,
            items: [
                OverlayMenuItem(title: "当前进度", subtitle: progress.summaryText, detail: "这项成就当前的最佳推进进度。", icon: "◔", badge: progress.isUnlocked ? "完成" : "目标 \(achievement.targetValue)", isDimmed: false),
                OverlayMenuItem(title: "类型", subtitle: achievement.category.title, detail: "这项成就属于 \(achievement.category.title) 分类。", icon: achievement.category.symbol, badge: nil, isDimmed: false),
                OverlayMenuItem(title: "奖励", subtitle: rewardText, detail: rewardText == "暂无专属皮肤奖励" ? "这项成就当前不会单独解锁皮肤。" : "解锁后会开放对应主题皮肤。", icon: "🎁", badge: nil, isDimmed: false)
            ],
            tabs: [],
            selectedIndex: nil,
            footer: "Esc 返回成就图鉴",
            layout: .list
        )
    }

    static func codex(
        section: CodexSection,
        discoveredCount: Int,
        totalCount: Int,
        completionText: String,
        detail: String,
        items: [OverlayMenuItem],
        selectedIndex: Int
    ) -> OverlayMenuState {
        OverlayMenuState(
            title: "收藏图鉴",
            subtitle: "\(section.symbol) \(section.title) · 已发现 \(discoveredCount)/\(totalCount) · 完成度 \(completionText)",
            detail: detail,
            items: items,
            tabs: CodexSection.allCases.map { tab in
                OverlayTabItem(title: tab.title, icon: tab.symbol, isSelected: tab == section)
            },
            selectedIndex: selectedIndex,
            footer: "左/右切换条目 · 上/下切换分类 · 空格查看详情 · Esc 返回主菜单",
            layout: .achievementGrid
        )
    }

    static func codexDetail(
        section: CodexSection,
        discovered: Bool,
        entry: CodexEntryDefinition?,
        unlockHint: String
    ) -> OverlayMenuState {
        OverlayMenuState(
            title: discovered ? "\(entry?.symbol ?? "•") \(entry?.title ?? "未知条目")" : "❔ 未发现条目",
            subtitle: "\(section.symbol) \(section.title) · \(discovered ? "已发现" : "未发现")",
            detail: discovered
                ? entry?.detail
                : "继续游玩来解锁这个条目。图鉴只会记录你真正见过的水果、特效、机关和地图。",
            items: [
                OverlayMenuItem(title: "状态", subtitle: discovered ? "已记录进图鉴" : "尚未发现", detail: discovered ? "这个条目已经进入你的收藏图鉴。" : "继续游玩，真正遇见它后才会点亮。", icon: discovered ? "✓" : "…", badge: nil, isDimmed: !discovered),
                OverlayMenuItem(title: "分类", subtitle: section.title, detail: "当前条目属于 \(section.title) 分类。", icon: section.symbol, badge: nil, isDimmed: false),
                OverlayMenuItem(title: "解锁方式", subtitle: unlockHint, detail: unlockHint, icon: "⌁", badge: nil, isDimmed: false)
            ],
            tabs: CodexSection.allCases.map { tab in
                OverlayTabItem(title: tab.title, icon: tab.symbol, isSelected: tab == section)
            },
            selectedIndex: nil,
            footer: "左/右切换条目 · 上/下切换分类 · 空格或 Esc 返回图鉴",
            layout: .list
        )
    }

    static func help(simpleModeEnabled: Bool) -> OverlayMenuState {
        let items = simpleModeEnabled
            ? [
                OverlayMenuItem(title: "火车模式", subtitle: nil, detail: "吃到什么水果，就在尾巴后面增加对应的水果车厢。", icon: "🚂", badge: nil, isDimmed: false),
                OverlayMenuItem(title: "只抽基础地图", subtitle: nil, detail: "不会出现机关图和塌陷地板，更适合小朋友。", icon: "☁", badge: nil, isDimmed: false),
                OverlayMenuItem(title: "速度更慢", subtitle: nil, detail: "只保留轻松和标准两档，并额外再放慢一点。", icon: "☺", badge: nil, isDimmed: false),
                OverlayMenuItem(title: "手动步进", subtitle: nil, detail: "打开设置里的手动步进后，蛇不会自动走，只会在你每次按方向时前进一步。", icon: "👣", badge: nil, isDimmed: false),
                OverlayMenuItem(title: "安全刹车", subtitle: nil, detail: "第一次撞到危险时不会立刻失败，会自动停下提醒你换方向。", icon: "🛑", badge: nil, isDimmed: false),
                OverlayMenuItem(title: "车站送货", subtitle: nil, detail: "收齐指定水果车厢后，把火车开到目标车站完成送货。", icon: "🚉", badge: nil, isDimmed: false),
                OverlayMenuItem(title: "喷射加速", subtitle: nil, detail: "长按空格或手柄右肩键，5 秒最多一次，会甩掉一节尾巴。", icon: "⚡", badge: nil, isDimmed: false)
            ]
            : [
                OverlayMenuItem(title: "柚子 +2，其它水果 +1", subtitle: nil, detail: "柚子收益最高，路线规划时要考虑更快变长。", icon: "🍊", badge: nil, isDimmed: false),
                OverlayMenuItem(title: "机关图危险更高", subtitle: nil, detail: "动态障碍会实时变化，但通常也会给你更高收益路线。", icon: "⚙", badge: nil, isDimmed: false),
                OverlayMenuItem(title: "倒计时水果和连击", subtitle: nil, detail: "它们会逼你更激进地走位；塌陷地板时尽量别原路折返。", icon: "⏳", badge: nil, isDimmed: false),
                OverlayMenuItem(title: "每日挑战", subtitle: nil, detail: "每天固定一套地图、词条和任务，完成后会留下记录。", icon: "📅", badge: nil, isDimmed: false),
                OverlayMenuItem(title: "喷射加速", subtitle: nil, detail: "长按空格快速冲刺，但会甩掉一节尾巴并留下短暂残留。", icon: "⚡", badge: nil, isDimmed: false)
            ]
        return OverlayMenuState(
            title: "玩法帮助",
            subtitle: simpleModeEnabled ? "先熟悉方向，再慢慢提高难度" : "先活下来，再追求更高收益",
            detail: "悬停条目查看说明",
            items: items,
            tabs: [],
            selectedIndex: nil,
            footer: "空格或 Esc 返回主菜单",
            layout: .list
        )
    }

    static func settings(
        settings: GameSettings,
        items: [OverlayMenuItem],
        selectedIndex: Int
    ) -> OverlayMenuState {
        OverlayMenuState(
            title: "设置",
            subtitle: "修改会立即生效",
            detail: "悬停条目查看说明",
            items: items,
            tabs: [],
            selectedIndex: selectedIndex,
            footer: "上/下切换 · 左/右调整 · 空格确认 · Esc 返回",
            layout: .list
        )
    }

    static func gameOver(
        snapshot: GameSnapshot,
        personalBestText: String,
        gapText: String,
        selectedIndex: Int,
        items: [OverlayMenuItem]
    ) -> OverlayMenuState {
        OverlayMenuState(
            title: snapshot.statusText,
            subtitle: "本局得分 \(snapshot.score) · 最高 \(snapshot.highScore) · 任务 \(snapshot.missionProgress.summaryText)\(personalBestText)\(gapText)",
            detail: "悬停条目查看说明",
            items: items,
            tabs: [],
            selectedIndex: selectedIndex,
            footer: "上/下选择 · 空格确认 · Esc 返回主菜单",
            layout: .list
        )
    }
}
