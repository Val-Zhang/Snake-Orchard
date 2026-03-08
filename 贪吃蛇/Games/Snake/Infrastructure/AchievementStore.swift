//
//  AchievementStore.swift
//  贪吃蛇
//
//  Created by zhangwang on 2026/3/7.
//

import Foundation

final class AchievementStore {
    private let key = "snake_orchard.achievement_ids"
    private let progressKey = "snake_orchard.achievement_progress"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var unlockedIDs: Set<AchievementID> {
        let rawValues = defaults.stringArray(forKey: key) ?? []
        return Set(rawValues.compactMap(AchievementID.init(rawValue:)))
    }

    var unlockedCount: Int {
        unlockedIDs.count
    }

    var unlockedAchievements: [AchievementDefinition] {
        AchievementCatalog.all.filter { unlockedIDs.contains($0.id) }
    }

    var bestProgressByID: [AchievementID: Int] {
        let stored = defaults.dictionary(forKey: progressKey) as? [String: Int] ?? [:]
        var resolved: [AchievementID: Int] = [:]
        for (rawID, value) in stored {
            guard let id = AchievementID(rawValue: rawID) else {
                continue
            }
            resolved[id] = value
        }
        return resolved
    }

    func progress(for achievement: AchievementDefinition) -> AchievementProgress {
        let bestValue = bestProgressByID[achievement.id, default: 0]
        return AchievementProgress(current: min(bestValue, achievement.targetValue), target: achievement.targetValue)
    }

    func updateProgress(snapshot: GameSnapshot, runStats: GameRunStats) {
        var stored = defaults.dictionary(forKey: progressKey) as? [String: Int] ?? [:]
        var changed = false

        for achievement in AchievementCatalog.all {
            let progress = AchievementCatalog.progress(for: achievement.id, snapshot: snapshot, runStats: runStats)
            let currentBest = stored[achievement.id.rawValue] ?? 0
            let clamped = min(progress.current, achievement.targetValue)
            if clamped > currentBest {
                stored[achievement.id.rawValue] = clamped
                changed = true
            }
        }

        if changed {
            defaults.set(stored, forKey: progressKey)
        }
    }

    @discardableResult
    func unlock(_ achievements: [AchievementDefinition]) -> [AchievementDefinition] {
        guard !achievements.isEmpty else {
            return []
        }

        var storedIDs = unlockedIDs
        var newlyUnlocked: [AchievementDefinition] = []

        for achievement in achievements where !storedIDs.contains(achievement.id) {
            storedIDs.insert(achievement.id)
            newlyUnlocked.append(achievement)
        }

        if !newlyUnlocked.isEmpty {
            defaults.set(storedIDs.map(\.rawValue).sorted(), forKey: key)
        }

        return newlyUnlocked
    }
}
