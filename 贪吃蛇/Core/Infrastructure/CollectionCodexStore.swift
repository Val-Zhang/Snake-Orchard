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

    func record(level: LevelDefinition) {
        save(CodexCatalog.levelID(for: level.name), key: Key.levelIDs)
        if let mechanicID = CodexCatalog.mechanicID(for: level) {
            save(mechanicID, key: Key.mechanicIDs)
        }
    }

    func record(fruit: FruitDefinition) {
        save(CodexCatalog.fruitID(for: fruit.kind), key: Key.fruitIDs)
        save(CodexCatalog.effectID(for: fruit.effect), key: Key.effectIDs)
    }

    private func save(_ id: String, key: String) {
        var values = Set(defaults.stringArray(forKey: key) ?? [])
        guard !values.contains(id) else {
            return
        }
        values.insert(id)
        defaults.set(Array(values).sorted(), forKey: key)
    }
}
