//
//  GameControllerInputManager.swift
//  贪吃蛇
//
//  Created by Codex on 2026/3/7.
//

import Foundation
import GameController

final class GameControllerInputManager {
    private final class ControllerState {
        var lastDirection: Direction?
    }

    private let threshold: Float = 0.55
    private var actions: [GameInputAction] = []
    private var controllerStates: [ObjectIdentifier: ControllerState] = [:]
    private var notificationObservers: [NSObjectProtocol] = []

    func start() {
        guard notificationObservers.isEmpty else {
            return
        }

        let center = NotificationCenter.default
        notificationObservers = [
            center.addObserver(
                forName: .GCControllerDidConnect,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                guard let controller = notification.object as? GCController else {
                    return
                }
                self?.configure(controller: controller)
            },
            center.addObserver(
                forName: .GCControllerDidDisconnect,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                guard let controller = notification.object as? GCController else {
                    return
                }
                self?.remove(controller: controller)
            }
        ]

        GCController.controllers().forEach { configure(controller: $0) }
    }

    func stop() {
        let center = NotificationCenter.default
        notificationObservers.forEach { center.removeObserver($0) }
        notificationObservers.removeAll()

        for controller in GCController.controllers() {
            controller.extendedGamepad?.valueChangedHandler = nil
            controller.microGamepad?.valueChangedHandler = nil
        }

        controllerStates.removeAll()
        actions.removeAll()
    }

    func drainActions() -> [GameInputAction] {
        defer { actions.removeAll() }
        return actions
    }

    private func configure(controller: GCController) {
        let identifier = ObjectIdentifier(controller)
        let state = controllerStates[identifier] ?? ControllerState()
        controllerStates[identifier] = state

        if let extendedGamepad = controller.extendedGamepad {
            extendedGamepad.valueChangedHandler = { [weak self, weak controller] _, element in
                guard let self, let controller else {
                    return
                }

                let state = self.controllerState(for: controller)
                self.handleDirectionalChange(for: controller.extendedGamepad, state: state, changedElement: element)
                self.handleButtonChange(for: controller.extendedGamepad, changedElement: element)
            }
            return
        }

        if let microGamepad = controller.microGamepad {
            microGamepad.allowsRotation = true
            microGamepad.reportsAbsoluteDpadValues = true
            microGamepad.valueChangedHandler = { [weak self, weak controller] _, element in
                guard let self, let controller else {
                    return
                }

                let state = self.controllerState(for: controller)
                self.handleDirectionalChange(for: microGamepad, state: state, changedElement: element)
                self.handleButtonChange(for: microGamepad, changedElement: element)
            }
        }
    }

    private func remove(controller: GCController) {
        controller.extendedGamepad?.valueChangedHandler = nil
        controller.microGamepad?.valueChangedHandler = nil
        controllerStates.removeValue(forKey: ObjectIdentifier(controller))
    }

    private func controllerState(for controller: GCController) -> ControllerState {
        let identifier = ObjectIdentifier(controller)
        if let existing = controllerStates[identifier] {
            return existing
        }

        let state = ControllerState()
        controllerStates[identifier] = state
        return state
    }

    private func handleDirectionalChange(
        for gamepad: GCExtendedGamepad?,
        state: ControllerState,
        changedElement: GCControllerElement
    ) {
        guard let gamepad else {
            return
        }

        let dpad = gamepad.dpad
        let leftThumbstick = gamepad.leftThumbstick
        let relatedElements = [dpad, leftThumbstick].compactMap { $0 }
        guard relatedElements.contains(where: { $0 == changedElement || $0.xAxis == changedElement || $0.yAxis == changedElement }) else {
            return
        }

        let direction = resolvedDirection(primary: leftThumbstick, secondary: dpad)
        if direction != state.lastDirection {
            state.lastDirection = direction
            if let direction {
                enqueue(.changeDirection(direction))
            }
        }
    }

    private func handleDirectionalChange(
        for gamepad: GCMicroGamepad,
        state: ControllerState,
        changedElement: GCControllerElement
    ) {
        let dpad = gamepad.dpad
        guard dpad == changedElement || dpad.xAxis == changedElement || dpad.yAxis == changedElement else {
            return
        }

        let direction = resolvedDirection(primary: dpad, secondary: nil)
        if direction != state.lastDirection {
            state.lastDirection = direction
            if let direction {
                enqueue(.changeDirection(direction))
            }
        }
    }

    private func handleButtonChange(
        for gamepad: GCExtendedGamepad?,
        changedElement: GCControllerElement
    ) {
        guard let gamepad else {
            return
        }

        if gamepad.buttonA == changedElement, gamepad.buttonA.isPressed {
            enqueue(.primaryAction)
        } else if gamepad.buttonB == changedElement, gamepad.buttonB.isPressed {
            enqueue(.secondaryAction)
        } else if gamepad.buttonMenu == changedElement, gamepad.buttonMenu.isPressed {
            enqueue(.togglePause)
        } else if gamepad.buttonOptions == changedElement, gamepad.buttonOptions?.isPressed == true {
            enqueue(.togglePause)
        } else if gamepad.leftShoulder == changedElement, gamepad.leftShoulder.isPressed {
            enqueue(.togglePause)
        } else if gamepad.rightShoulder == changedElement {
            enqueue(gamepad.rightShoulder.isPressed ? .boostPressed : .boostReleased)
        } else if gamepad.rightTrigger == changedElement {
            enqueue(gamepad.rightTrigger.isPressed ? .boostPressed : .boostReleased)
        } else if gamepad.buttonX == changedElement {
            enqueue(gamepad.buttonX.isPressed ? .boostPressed : .boostReleased)
        }
    }

    private func handleButtonChange(
        for gamepad: GCMicroGamepad,
        changedElement: GCControllerElement
    ) {
        if gamepad.buttonA == changedElement, gamepad.buttonA.isPressed {
            enqueue(.primaryAction)
        } else if gamepad.buttonMenu == changedElement, gamepad.buttonMenu.isPressed {
            enqueue(.togglePause)
        } else if gamepad.buttonX == changedElement, gamepad.buttonX.isPressed {
            enqueue(.secondaryAction)
        }
    }

    private func resolvedDirection(primary: GCControllerDirectionPad?, secondary: GCControllerDirectionPad?) -> Direction? {
        if let direction = dominantDirection(from: primary) {
            return direction
        }
        return dominantDirection(from: secondary)
    }

    private func dominantDirection(from pad: GCControllerDirectionPad?) -> Direction? {
        guard let pad else {
            return nil
        }

        let x = pad.xAxis.value
        let y = pad.yAxis.value
        guard max(abs(x), abs(y)) >= threshold else {
            return nil
        }

        if abs(x) > abs(y) {
            return x > 0 ? .right : .left
        }
        return y > 0 ? .up : .down
    }

    private func enqueue(_ action: GameInputAction) {
        actions.append(action)
    }
}
