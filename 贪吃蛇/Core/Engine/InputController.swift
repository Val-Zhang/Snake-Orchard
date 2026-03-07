//
//  InputController.swift
//  贪吃蛇
//
//  Created by zhangwang on 2026/3/6.
//

import AppKit

enum GameInputAction {
    case changeDirection(Direction)
    case primaryAction
    case togglePause
    case secondaryAction
}

struct GameInputController {
    func action(for event: NSEvent) -> GameInputAction? {
        switch event.keyCode {
        case 49:
            return .primaryAction
        case 35:
            return .togglePause
        case 53:
            return .secondaryAction
        case 123:
            return .changeDirection(.left)
        case 124:
            return .changeDirection(.right)
        case 125:
            return .changeDirection(.down)
        case 126:
            return .changeDirection(.up)
        default:
            break
        }

        let characters = event.charactersIgnoringModifiers?.lowercased() ?? ""
        switch characters {
        case "a":
            return .changeDirection(.left)
        case "d":
            return .changeDirection(.right)
        case "s":
            return .changeDirection(.down)
        case "w":
            return .changeDirection(.up)
        case "\r", " ":
            return .primaryAction
        case "p":
            return .togglePause
        case "m":
            return .secondaryAction
        default:
            return nil
        }
    }
}
