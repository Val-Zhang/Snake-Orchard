//
//  GameModels.swift
//  贪吃蛇
//
//  Created by zhangwang on 2026/3/6.
//

import SpriteKit

struct GridPoint: Hashable {
    let x: Int
    let y: Int

    func moved(_ direction: Direction) -> GridPoint {
        GridPoint(x: x + direction.dx, y: y + direction.dy)
    }
}

enum Direction {
    case up
    case down
    case left
    case right

    var dx: Int {
        switch self {
        case .left:
            return -1
        case .right:
            return 1
        default:
            return 0
        }
    }

    var dy: Int {
        switch self {
        case .down:
            return -1
        case .up:
            return 1
        default:
            return 0
        }
    }

    func isOpposite(to other: Direction) -> Bool {
        (dx + other.dx == 0) && (dy + other.dy == 0)
    }
}

enum FruitKind: CaseIterable {
    case banana
    case apple
    case pomelo
    case watermelon
    case peach

    var name: String {
        switch self {
        case .banana:
            return "香蕉"
        case .apple:
            return "苹果"
        case .pomelo:
            return "柚子"
        case .watermelon:
            return "西瓜"
        case .peach:
            return "桃子"
        }
    }

    var symbol: String {
        switch self {
        case .banana:
            return "🍌"
        case .apple:
            return "🍎"
        case .pomelo:
            return "🍊"
        case .watermelon:
            return "🍉"
        case .peach:
            return "🍑"
        }
    }

    var growth: Int {
        switch self {
        case .pomelo:
            return 2
        default:
            return 1
        }
    }

    var color: SKColor {
        switch self {
        case .banana:
            return SKColor(calibratedRed: 0.96, green: 0.82, blue: 0.25, alpha: 1.0)
        case .apple:
            return SKColor(calibratedRed: 0.84, green: 0.24, blue: 0.27, alpha: 1.0)
        case .pomelo:
            return SKColor(calibratedRed: 0.96, green: 0.88, blue: 0.55, alpha: 1.0)
        case .watermelon:
            return SKColor(calibratedRed: 0.22, green: 0.68, blue: 0.32, alpha: 1.0)
        case .peach:
            return SKColor(calibratedRed: 0.96, green: 0.60, blue: 0.63, alpha: 1.0)
        }
    }
}

enum FruitEffect: CaseIterable {
    case normal
    case golden
    case frost

    var title: String {
        switch self {
        case .normal:
            return ""
        case .golden:
            return "金彩"
        case .frost:
            return "冰镇"
        }
    }

    var badge: String {
        switch self {
        case .normal:
            return ""
        case .golden:
            return "★"
        case .frost:
            return "❄"
        }
    }

    var ringColor: SKColor {
        switch self {
        case .normal:
            return SKColor(calibratedWhite: 1.0, alpha: 0.18)
        case .golden:
            return SKColor(calibratedRed: 1.0, green: 0.88, blue: 0.28, alpha: 1.0)
        case .frost:
            return SKColor(calibratedRed: 0.52, green: 0.84, blue: 1.0, alpha: 1.0)
        }
    }

    var scoreMultiplier: Int {
        switch self {
        case .normal:
            return 1
        case .golden:
            return 2
        case .frost:
            return 1
        }
    }

    var slowMoveBonus: Int {
        switch self {
        case .frost:
            return 10
        default:
            return 0
        }
    }
}

struct FruitDefinition {
    let kind: FruitKind
    let effect: FruitEffect

    var name: String {
        effect == .normal ? kind.name : "\(effect.title)\(kind.name)"
    }

    var symbol: String {
        kind.symbol
    }

    var growth: Int {
        kind.growth
    }

    var color: SKColor {
        kind.color
    }

    var scoreValue: Int {
        10 * growth * effect.scoreMultiplier
    }
}

struct LevelDefinition: Equatable {
    let name: String
    let columns: Int
    let rows: Int
    let tickDuration: TimeInterval
    let obstacles: Set<GridPoint>
}

struct GameSnapshot {
    let level: LevelDefinition
    let snake: [GridPoint]
    let fruitPosition: GridPoint?
    let fruit: FruitDefinition?
    let score: Int
    let highScore: Int
    let fruitsEaten: Int
    let isGameOver: Bool
    let statusText: String
    let hintText: String
    let activeEffectText: String?
}

enum SceneMode {
    case ready
    case playing
    case paused
    case gameOver
}

enum GameEvent {
    case ateFruit(fruit: FruitDefinition, at: GridPoint, points: Int)
    case gameOver
    case highScoreUpdated(Int)
}
