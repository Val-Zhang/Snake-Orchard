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
    }

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

    func recordRun(snapshot: GameSnapshot) {
        let nextRunCount = defaults.integer(forKey: Key.totalRuns) + 1
        defaults.set(nextRunCount, forKey: Key.totalRuns)
        defaults.set(max(defaults.integer(forKey: Key.bestLength), snapshot.snake.count), forKey: Key.bestLength)
        defaults.set(snapshot.score, forKey: Key.lastScore)
        defaults.set(snapshot.snake.count, forKey: Key.lastLength)
        defaults.set(snapshot.level.name, forKey: Key.lastLevelName)
        defaults.set(snapshot.mission.title, forKey: Key.lastMissionTitle)
        defaults.set(snapshot.missionProgress.isCompleted, forKey: Key.lastMissionCompleted)
    }
}
