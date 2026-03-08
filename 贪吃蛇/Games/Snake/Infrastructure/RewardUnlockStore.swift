//
//  RewardUnlockStore.swift
//  贪吃蛇
//
//  Created by Codex on 2026/3/8.
//

import Foundation

final class RewardUnlockStore {
    private let key = "snake_orchard.reward_unlock.ids"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var unlockedIDs: Set<RewardUnlockID> {
        let rawValues = defaults.stringArray(forKey: key) ?? []
        return Set(rawValues.compactMap(RewardUnlockID.init(rawValue:)))
    }

    @discardableResult
    func syncUnlocked(_ rewards: [RewardUnlockDefinition]) -> [RewardUnlockDefinition] {
        guard !rewards.isEmpty else {
            return []
        }

        var ids = unlockedIDs
        var newlyUnlocked: [RewardUnlockDefinition] = []

        for reward in rewards where !ids.contains(reward.id) {
            ids.insert(reward.id)
            newlyUnlocked.append(reward)
        }

        if !newlyUnlocked.isEmpty {
            defaults.set(ids.map(\.rawValue).sorted(), forKey: key)
        }

        return newlyUnlocked
    }
}
