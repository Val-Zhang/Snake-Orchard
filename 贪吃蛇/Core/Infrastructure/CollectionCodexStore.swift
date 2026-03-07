//
//  CollectionCodexStore.swift
//  贪吃蛇
//
//  Created by Codex on 2026/3/7.
//

import Foundation

final class CollectionCodexStore {
    private enum Key {
        static let fruitIDs = "snake_orchard.codex.fruit_ids"
        static let effectIDs = "snake_orchard.codex.effect_ids"
        static let mechanicIDs = "snake_orchard.codex.mechanic_ids"
        static let levelIDs = "snake_orchard.codex.level_ids"
        static let recentIDs = "snake_orchard.codex.recent_ids"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var discoveredFruitIDs: Set<String> {
        Set(defaults.stringArray(forKey: Key.fruitIDs) ?? [])
    }

    var discoveredEffectIDs: Set<String> {
        Set(defaults.stringArray(forKey: Key.effectIDs) ?? [])
    }

    var discoveredMechanicIDs: Set<String> {
        Set(defaults.stringArray(forKey: Key.mechanicIDs) ?? [])
    }

    var discoveredLevelIDs: Set<String> {
        Set(defaults.stringArray(forKey: Key.levelIDs) ?? [])
    }

    var totalDiscoveredCount: Int {
        discoveredFruitIDs.count + discoveredEffectIDs.count + discoveredMechanicIDs.count + discoveredLevelIDs.count
    }

    var recentDiscoveryIDs: [String] {
        defaults.stringArray(forKey: Key.recentIDs) ?? []
    }

    func discoveredIDs(for section: CodexSection) -> Set<String> {
        switch section {
        case .fruits:
            return discoveredFruitIDs
        case .effects:
            return discoveredEffectIDs
        case .mechanics:
            return discoveredMechanicIDs
        case .levels:
            return discoveredLevelIDs
        }
    }

    @discardableResult
    func record(level: LevelDefinition) -> [String] {
        var discovered: [String] = []
        if save(CodexCatalog.levelID(for: level.name), key: Key.levelIDs) {
            discovered.append(CodexCatalog.levelID(for: level.name))
        }
        if let mechanicID = CodexCatalog.mechanicID(for: level) {
            if save(mechanicID, key: Key.mechanicIDs) {
                discovered.append(mechanicID)
            }
        }
        return discovered
    }

    @discardableResult
    func record(fruit: FruitDefinition) -> [String] {
        var discovered: [String] = []
        let fruitID = CodexCatalog.fruitID(for: fruit.kind)
        let effectID = CodexCatalog.effectID(for: fruit.effect)
        if save(fruitID, key: Key.fruitIDs) {
            discovered.append(fruitID)
        }
        if save(effectID, key: Key.effectIDs) {
            discovered.append(effectID)
        }
        return discovered
    }

    private func save(_ id: String, key: String) -> Bool {
        var values = Set(defaults.stringArray(forKey: key) ?? [])
        guard !values.contains(id) else {
            return false
        }
        values.insert(id)
        defaults.set(Array(values).sorted(), forKey: key)
        pushRecent(id)
        return true
    }

    private func pushRecent(_ id: String) {
        var values = recentDiscoveryIDs.filter { $0 != id }
        values.insert(id, at: 0)
        defaults.set(Array(values.prefix(4)), forKey: Key.recentIDs)
    }
}
