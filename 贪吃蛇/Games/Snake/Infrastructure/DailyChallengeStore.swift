//
//  DailyChallengeStore.swift
//  贪吃蛇
//
//  Created by Codex on 2026/3/8.
//

import Foundation

final class DailyChallengeStore {
    private enum Key {
        static let completedIDs = "snake_orchard.daily_challenge.completed_ids"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var completedIDs: Set<String> {
        Set(defaults.stringArray(forKey: Key.completedIDs) ?? [])
    }

    var completedCount: Int {
        completedIDs.count
    }

    func isCompleted(_ challenge: DailyChallengeDefinition) -> Bool {
        completedIDs.contains(challenge.id)
    }

    @discardableResult
    func markCompleted(_ challenge: DailyChallengeDefinition) -> Bool {
        var ids = completedIDs
        guard !ids.contains(challenge.id) else {
            return false
        }
        ids.insert(challenge.id)
        defaults.set(ids.sorted(), forKey: Key.completedIDs)
        return true
    }
}
