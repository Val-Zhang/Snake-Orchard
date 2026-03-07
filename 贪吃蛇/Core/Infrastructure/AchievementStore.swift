//
//  AchievementStore.swift
//  贪吃蛇
//
//  Created by zhangwang on 2026/3/7.
//

import Foundation

final class AchievementStore {
    private let key = "snake_orchard.achievement_ids"
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
