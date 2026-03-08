//
//  RunHistoryStore.swift
//  贪吃蛇
//
//  Created by zhangwang on 2026/3/7.
//

import Foundation

final class RunHistoryStore {
    private enum Key {
        static let totalRuns = "snake_orchard.history.total_runs"
        static let bestLength = "snake_orchard.history.best_length"
        static let lastScore = "snake_orchard.history.last_score"
        static let lastLength = "snake_orchard.history.last_length"
        static let lastLevelName = "snake_orchard.history.last_level_name"
        static let lastMissionTitle = "snake_orchard.history.last_mission_title"
        static let lastMissionCompleted = "snake_orchard.history.last_mission_completed"
        static let historyEntries = "snake_orchard.history.all_entries"
        static let leaderboardEntries = "snake_orchard.history.leaderboard_entries"
    }

    private static let historyLimit = 160
    private static let leaderboardLimit = 10

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var summary: RunHistorySummary {
        RunHistorySummary(
            totalRuns: defaults.integer(forKey: Key.totalRuns),
            bestLength: defaults.integer(forKey: Key.bestLength),
            lastScore: defaults.integer(forKey: Key.lastScore),
            lastLength: defaults.integer(forKey: Key.lastLength),
            lastLevelName: defaults.string(forKey: Key.lastLevelName) ?? RunHistorySummary.empty.lastLevelName,
            lastMissionTitle: defaults.string(forKey: Key.lastMissionTitle) ?? RunHistorySummary.empty.lastMissionTitle,
            lastMissionCompleted: defaults.bool(forKey: Key.lastMissionCompleted)
        )
    }

    var leaderboard: [RunLeaderboardEntry] {
        guard let data = defaults.data(forKey: Key.leaderboardEntries),
              let entries = try? JSONDecoder().decode([RunLeaderboardEntry].self, from: data)
        else {
            return []
        }
        return entries
    }

    private var historyEntries: [RunLeaderboardEntry] {
        if let data = defaults.data(forKey: Key.historyEntries),
           let entries = try? JSONDecoder().decode([RunLeaderboardEntry].self, from: data) {
            return entries
        }
        return leaderboard
    }

    func leaderboardEntries(for scope: LeaderboardScope) -> [RunLeaderboardEntry] {
        switch scope {
        case .overall:
            return Array(sorted(historyEntries).prefix(Self.leaderboardLimit))
        case .dailyChallenge:
            return Array(sorted(historyEntries.filter(\.isDailyChallenge)).prefix(Self.leaderboardLimit))
        case .family:
            return []
        }
    }

    func familyLeaderboard() -> [FamilyLeaderboardEntry] {
        let groups = Dictionary(grouping: historyEntries, by: \.familyMember)
        return FamilyMember.allCases.compactMap { member in
            guard let entries = groups[member], !entries.isEmpty else {
                return nil
            }
            let sortedEntries = sorted(entries)
            guard let best = sortedEntries.first else {
                return nil
            }
            return FamilyLeaderboardEntry(
                member: member,
                bestScore: best.score,
                bestLength: best.length,
                runCount: entries.count,
                latestTimestamp: entries.map(\.timestamp).max() ?? best.timestamp,
                dailyChallengeCount: entries.filter(\.isDailyChallenge).count
            )
        }
        .sorted { lhs, rhs in
            if lhs.bestScore != rhs.bestScore {
                return lhs.bestScore > rhs.bestScore
            }
            if lhs.bestLength != rhs.bestLength {
                return lhs.bestLength > rhs.bestLength
            }
            return lhs.latestTimestamp > rhs.latestTimestamp
        }
    }

    func recentEntries(for familyMember: FamilyMember, limit: Int = 5) -> [RunLeaderboardEntry] {
        Array(
            historyEntries
                .filter { $0.familyMember == familyMember }
                .sorted { $0.timestamp > $1.timestamp }
                .prefix(limit)
        )
    }

    @discardableResult
    func recordRun(snapshot: GameSnapshot, familyMember: FamilyMember) -> RunLeaderboardPlacement {
        let previousPersonalBest = historyEntries
            .filter { $0.familyMember == familyMember }
            .sorted { lhs, rhs in
                if lhs.score != rhs.score {
                    return lhs.score > rhs.score
                }
                if lhs.length != rhs.length {
                    return lhs.length > rhs.length
                }
                return lhs.timestamp > rhs.timestamp
            }
            .first
        let nextRunCount = defaults.integer(forKey: Key.totalRuns) + 1
        defaults.set(nextRunCount, forKey: Key.totalRuns)
        defaults.set(max(defaults.integer(forKey: Key.bestLength), snapshot.snake.count), forKey: Key.bestLength)
        defaults.set(snapshot.score, forKey: Key.lastScore)
        defaults.set(snapshot.snake.count, forKey: Key.lastLength)
        defaults.set(snapshot.level.name, forKey: Key.lastLevelName)
        defaults.set(snapshot.mission.title, forKey: Key.lastMissionTitle)
        defaults.set(snapshot.missionProgress.isCompleted, forKey: Key.lastMissionCompleted)

        let entry = RunLeaderboardEntry(
            score: snapshot.score,
            length: snapshot.snake.count,
            levelName: snapshot.level.name,
            missionTitle: snapshot.mission.title,
            missionCompleted: snapshot.missionProgress.isCompleted,
            isDailyChallenge: snapshot.dailyChallenge != nil,
            isSimpleModeEnabled: snapshot.isSimpleModeEnabled,
            familyMember: familyMember,
            timestamp: Date().timeIntervalSince1970
        )
        var allEntries = historyEntries
        allEntries.append(entry)
        allEntries = sorted(allEntries)
        allEntries = Array(allEntries.prefix(Self.historyLimit))
        if let historyData = try? JSONEncoder().encode(allEntries) {
            defaults.set(historyData, forKey: Key.historyEntries)
        }

        let totalEntries = Array(allEntries.prefix(Self.leaderboardLimit))
        let totalRank = rank(of: entry, in: allEntries)
        if let data = try? JSONEncoder().encode(totalEntries) {
            defaults.set(data, forKey: Key.leaderboardEntries)
        }

        let dailyRank: Int?
        if entry.isDailyChallenge {
            dailyRank = rank(of: entry, in: sorted(allEntries.filter(\.isDailyChallenge)))
        } else {
            dailyRank = nil
        }

        let personalBestImproved: Bool
        if let previousPersonalBest {
            personalBestImproved = entry.score > previousPersonalBest.score
                || (entry.score == previousPersonalBest.score && entry.length > previousPersonalBest.length)
        } else {
            personalBestImproved = true
        }

        return RunLeaderboardPlacement(
            totalRank: totalRank,
            dailyRank: dailyRank,
            personalBestImproved: personalBestImproved,
            previousBestScore: previousPersonalBest?.score,
            previousBestLength: previousPersonalBest?.length
        )
    }

    private func sorted(_ entries: [RunLeaderboardEntry]) -> [RunLeaderboardEntry] {
        entries.sorted { lhs, rhs in
            if lhs.score != rhs.score {
                return lhs.score > rhs.score
            }
            if lhs.length != rhs.length {
                return lhs.length > rhs.length
            }
            return lhs.timestamp > rhs.timestamp
        }
    }

    private func rank(of entry: RunLeaderboardEntry, in entries: [RunLeaderboardEntry]) -> Int? {
        guard let index = entries.firstIndex(where: {
            $0.timestamp == entry.timestamp &&
            $0.score == entry.score &&
            $0.length == entry.length
        }) else {
            return nil
        }
        let rank = index + 1
        return rank <= Self.leaderboardLimit ? rank : nil
    }
}
