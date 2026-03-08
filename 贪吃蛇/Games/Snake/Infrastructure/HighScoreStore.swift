//
//  HighScoreStore.swift
//  贪吃蛇
//
//  Created by zhangwang on 2026/3/6.
//

import Foundation

final class HighScoreStore {
    private let key = "greedy_snake.high_score"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var highScore: Int {
        defaults.integer(forKey: key)
    }

    @discardableResult
    func saveIfNeeded(score: Int) -> Bool {
        guard score > highScore else {
            return false
        }

        defaults.set(score, forKey: key)
        return true
    }
}
