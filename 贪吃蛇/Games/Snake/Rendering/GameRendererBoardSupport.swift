//
//  GameRendererBoardSupport.swift
//  贪吃蛇
//
//  Created by Codex on 2026/3/8.
//

import SpriteKit

enum GameRendererBoardSupport {
    static func renderBoard(
        obstacleLayer: SKNode,
        dynamicObstacleLayer: SKNode,
        temporaryHazardLayer: SKNode,
        stationLayer: SKNode,
        snakeLayer: SKNode,
        fruitLayer: SKNode,
        boardFrame: CGRect,
        cellSize: CGFloat,
        level: LevelDefinition
    ) {
        obstacleLayer.removeAllChildren()
        dynamicObstacleLayer.removeAllChildren()
        temporaryHazardLayer.removeAllChildren()
        stationLayer.removeAllChildren()
        snakeLayer.removeAllChildren()
        fruitLayer.removeAllChildren()

        let gridPath = CGMutablePath()
        for column in 0 ... level.columns {
            let x = boardFrame.minX + CGFloat(column) * cellSize
            gridPath.move(to: CGPoint(x: x, y: boardFrame.minY))
            gridPath.addLine(to: CGPoint(x: x, y: boardFrame.maxY))
        }
        for row in 0 ... level.rows {
            let y = boardFrame.minY + CGFloat(row) * cellSize
            gridPath.move(to: CGPoint(x: boardFrame.minX, y: y))
            gridPath.addLine(to: CGPoint(x: boardFrame.maxX, y: y))
        }

        let gridNode = SKShapeNode(path: gridPath)
        gridNode.strokeColor = SKColor(calibratedWhite: 1.0, alpha: 0.08)
        gridNode.lineWidth = 1
        obstacleLayer.addChild(gridNode)
    }

    static func renderObstacles(
        on layer: SKNode,
        level: LevelDefinition,
        cellSize: CGFloat,
        obstacleColor: SKColor,
        accentColor: SKColor,
        pointFor: (GridPoint) -> CGPoint
    ) {
        for obstacle in level.obstacles {
            let node = SKShapeNode(
                rectOf: CGSize(width: cellSize * 0.82, height: cellSize * 0.82),
                cornerRadius: cellSize * 0.16
            )
            node.position = pointFor(obstacle)
            node.fillColor = obstacleColor
            node.strokeColor = accentColor.withAlphaComponent(0.12)
            node.lineWidth = 1
            layer.addChild(node)
        }
    }

    static func renderDynamicObstacles(
        on layer: SKNode,
        snapshot: DynamicObstacleSnapshot?,
        cellSize: CGFloat,
        pointFor: (GridPoint) -> CGPoint
    ) {
        layer.removeAllChildren()

        guard let snapshot else {
            return
        }

        for obstaclePoint in snapshot.points {
            let node = SKShapeNode(
                rectOf: CGSize(width: cellSize * 0.84, height: cellSize * 0.84),
                cornerRadius: cellSize * 0.18
            )
            node.position = pointFor(obstaclePoint)

            switch snapshot.style {
            case .sweeper:
                node.fillColor = SKColor(calibratedRed: 0.96, green: 0.50, blue: 0.19, alpha: 1.0)
                node.strokeColor = SKColor(calibratedRed: 1.0, green: 0.85, blue: 0.52, alpha: 0.95)
                node.run(.repeatForever(.sequence([
                    .fadeAlpha(to: 0.65, duration: 0.22),
                    .fadeAlpha(to: 1.0, duration: 0.22)
                ])))
            case .gate:
                node.fillColor = SKColor(calibratedRed: 0.28, green: 0.76, blue: 0.98, alpha: 1.0)
                node.strokeColor = SKColor(calibratedWhite: 1.0, alpha: 0.92)
                node.run(.repeatForever(.sequence([
                    .group([
                        .scale(to: 1.06, duration: 0.32),
                        .fadeAlpha(to: 0.72, duration: 0.32)
                    ]),
                    .group([
                        .scale(to: 0.96, duration: 0.32),
                        .fadeAlpha(to: 1.0, duration: 0.32)
                    ])
                ])))
            case .rotor:
                node.fillColor = SKColor(calibratedRed: 0.95, green: 0.30, blue: 0.33, alpha: 1.0)
                node.strokeColor = SKColor(calibratedRed: 1.0, green: 0.92, blue: 0.74, alpha: 0.95)
                node.run(.repeatForever(.sequence([
                    .group([
                        .rotate(byAngle: .pi / 6, duration: 0.16),
                        .scale(to: 1.04, duration: 0.16)
                    ]),
                    .group([
                        .rotate(byAngle: -.pi / 6, duration: 0.16),
                        .scale(to: 0.96, duration: 0.16)
                    ])
                ])))
            case .crusher:
                node.fillColor = SKColor(calibratedRed: 0.70, green: 0.28, blue: 0.92, alpha: 1.0)
                node.strokeColor = SKColor(calibratedRed: 0.94, green: 0.85, blue: 1.0, alpha: 0.95)
                node.run(.repeatForever(.sequence([
                    .group([
                        .scaleX(to: 1.10, duration: 0.28),
                        .fadeAlpha(to: 0.72, duration: 0.28)
                    ]),
                    .group([
                        .scaleX(to: 0.94, duration: 0.28),
                        .fadeAlpha(to: 1.0, duration: 0.28)
                    ])
                ])))
            }

            node.lineWidth = 1.6
            layer.addChild(node)
        }
    }

    static func renderTemporaryHazards(
        on layer: SKNode,
        hazards: [TemporaryHazardSnapshot],
        theme: VisualTheme,
        cellSize: CGFloat,
        pointFor: (GridPoint) -> CGPoint
    ) {
        layer.removeAllChildren()

        for hazard in hazards {
            for hazardPoint in hazard.points {
                let node = SKShapeNode(
                    rectOf: CGSize(width: cellSize * 0.72, height: cellSize * 0.72),
                    cornerRadius: cellSize * 0.14
                )
                node.position = pointFor(hazardPoint)

                switch hazard.style {
                case .collapse:
                    node.fillColor = SKColor(calibratedRed: 0.56, green: 0.70, blue: 0.92, alpha: 0.62)
                    node.strokeColor = SKColor(calibratedRed: 0.82, green: 0.92, blue: 1.0, alpha: 0.78)
                    node.lineWidth = 1.2
                    node.run(.repeatForever(.sequence([
                        .fadeAlpha(to: 0.42, duration: 0.24),
                        .fadeAlpha(to: 0.82, duration: 0.24)
                    ])))
                case .bomb:
                    node.fillColor = SKColor(calibratedRed: 0.98, green: 0.38, blue: 0.22, alpha: 0.72)
                    node.strokeColor = SKColor(calibratedRed: 1.0, green: 0.88, blue: 0.62, alpha: 0.82)
                    node.lineWidth = 1.5
                    node.run(.repeatForever(.sequence([
                        .group([
                            .scale(to: 1.10, duration: 0.16),
                            .fadeAlpha(to: 1.0, duration: 0.16)
                        ]),
                        .group([
                            .scale(to: 0.92, duration: 0.16),
                            .fadeAlpha(to: 0.58, duration: 0.16)
                        ])
                    ])))
                case .poop:
                    node.fillColor = SKColor(calibratedRed: 0.48, green: 0.30, blue: 0.18, alpha: 0.88)
                    node.strokeColor = SKColor(calibratedRed: 0.78, green: 0.62, blue: 0.42, alpha: 0.82)
                    node.lineWidth = 1.2
                    let label = SKLabelNode(fontNamed: "AppleColorEmoji")
                    label.fontSize = cellSize * 0.46
                    label.verticalAlignmentMode = .center
                    label.horizontalAlignmentMode = .center
                    label.text = theme.residueSymbol
                    label.position = CGPoint(x: 0, y: -cellSize * 0.03)
                    node.addChild(label)
                    node.run(.repeatForever(.sequence([
                        .fadeAlpha(to: 0.56, duration: 0.22),
                        .fadeAlpha(to: 0.92, duration: 0.22)
                    ])))
                }

                layer.addChild(node)
            }
        }
    }

    static func renderDeliveryStation(
        on layer: SKNode,
        station: DeliveryStationSnapshot?,
        cellSize: CGFloat,
        accentColor: SKColor,
        pointFor: (GridPoint) -> CGPoint
    ) {
        layer.removeAllChildren()

        guard let station else {
            return
        }

        let node = SKShapeNode(
            rectOf: CGSize(width: cellSize * 0.84, height: cellSize * 0.84),
            cornerRadius: cellSize * 0.18
        )
        node.position = pointFor(station.point)
        node.fillColor = station.isCompleted
            ? SKColor(calibratedRed: 0.40, green: 0.84, blue: 0.56, alpha: 0.26)
            : accentColor.withAlphaComponent(station.isReadyForDelivery ? 0.24 : 0.15)
        node.strokeColor = station.isCompleted
            ? SKColor(calibratedRed: 0.58, green: 0.96, blue: 0.74, alpha: 0.96)
            : accentColor.withAlphaComponent(0.86)
        node.lineWidth = 1.8

        if station.isReadyForDelivery && !station.isCompleted {
            node.run(.repeatForever(.sequence([
                .group([
                    .scale(to: 1.08, duration: 0.22),
                    .fadeAlpha(to: 1.0, duration: 0.22)
                ]),
                .group([
                    .scale(to: 0.94, duration: 0.22),
                    .fadeAlpha(to: 0.82, duration: 0.22)
                ])
            ])))
        }

        let icon = SKLabelNode(fontNamed: "AppleColorEmoji")
        icon.fontSize = cellSize * 0.44
        icon.verticalAlignmentMode = .center
        icon.horizontalAlignmentMode = .center
        icon.text = station.route.station.symbol
        icon.position = CGPoint(x: 0, y: -cellSize * 0.03)
        node.addChild(icon)

        let badge = SKLabelNode(fontNamed: "AvenirNext-Bold")
        badge.fontSize = cellSize * 0.18
        badge.verticalAlignmentMode = .center
        badge.horizontalAlignmentMode = .center
        badge.fontColor = station.isCompleted
            ? SKColor(calibratedRed: 0.82, green: 1.0, blue: 0.88, alpha: 1.0)
            : SKColor(calibratedWhite: 0.98, alpha: 0.92)
        badge.text = station.isCompleted ? "已送达" : "送货"
        badge.position = CGPoint(x: 0, y: cellSize * 0.36)
        node.addChild(badge)

        layer.addChild(node)
    }

    static func renderFruit(
        on layer: SKNode,
        position: GridPoint?,
        fruit: FruitDefinition?,
        countdown: Int?,
        theme: VisualTheme,
        cellSize: CGFloat,
        pointFor: (GridPoint) -> CGPoint,
        auraAction: (FruitEffect) -> SKAction
    ) {
        layer.removeAllChildren()

        guard let position, let fruit else {
            return
        }

        let fruitNode = SKShapeNode(circleOfRadius: cellSize * 0.38)
        fruitNode.position = pointFor(position)
        fruitNode.fillColor = fruit.color.withAlphaComponent(0.18)
        fruitNode.strokeColor = fruit.effect.ringColor.withAlphaComponent(0.82)
        fruitNode.lineWidth = 1
        layer.addChild(fruitNode)

        if fruit.effect != .normal {
            let aura = SKShapeNode(circleOfRadius: cellSize * 0.48)
            aura.strokeColor = fruit.effect.ringColor.withAlphaComponent(0.75)
            aura.fillColor = .clear
            aura.lineWidth = 2
            fruitNode.addChild(aura)
            aura.run(auraAction(fruit.effect))
        }

        let shadow = SKLabelNode(fontNamed: "AppleColorEmoji")
        shadow.fontSize = cellSize * 0.82
        shadow.verticalAlignmentMode = .center
        shadow.horizontalAlignmentMode = .center
        shadow.alpha = 0.2
        shadow.text = theme.collectibleSymbol(for: fruit.kind)
        shadow.position = CGPoint(x: 1.5, y: -cellSize * 0.08)
        fruitNode.addChild(shadow)

        let label = SKLabelNode(fontNamed: "AppleColorEmoji")
        label.fontSize = cellSize * 0.82
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.text = theme.collectibleSymbol(for: fruit.kind)
        label.position = CGPoint(x: 0, y: -cellSize * 0.10)
        fruitNode.addChild(label)

        if fruit.effect != .normal {
            let badge = SKLabelNode(fontNamed: "AvenirNext-Bold")
            badge.fontSize = cellSize * 0.22
            badge.verticalAlignmentMode = .center
            badge.horizontalAlignmentMode = .center
            badge.fontColor = fruit.effect.ringColor
            badge.text = fruit.effect.badge
            badge.position = CGPoint(x: cellSize * 0.34, y: cellSize * 0.28)
            fruitNode.addChild(badge)
        }

        if let countdown {
            let timer = SKLabelNode(fontNamed: "AvenirNext-Bold")
            timer.fontSize = cellSize * 0.24
            timer.verticalAlignmentMode = .center
            timer.horizontalAlignmentMode = .center
            timer.fontColor = countdown <= 3
                ? SKColor(calibratedRed: 1.0, green: 0.74, blue: 0.32, alpha: 1.0)
                : SKColor(calibratedWhite: 0.98, alpha: 0.92)
            timer.text = "\(countdown)"
            timer.position = CGPoint(x: 0, y: cellSize * 0.46)
            fruitNode.addChild(timer)
        }
    }

    static func updateHUD(
        levelLabel: SKLabelNode,
        modifierLabel: SKLabelNode,
        scoreLabel: SKLabelNode,
        fruitLabel: SKLabelNode,
        missionLabel: SKLabelNode,
        statusLabel: SKLabelNode,
        hintLabel: SKLabelNode,
        snapshot: GameSnapshot,
        boostStatus: BoostStatusSnapshot,
        theme: VisualTheme
    ) {
        let modeText: String
        if snapshot.isManualStepModeEnabled {
            modeText = " · 极简手动"
        } else if snapshot.isSimpleModeEnabled {
            modeText = " · 极简模式"
        } else {
            modeText = ""
        }
        levelLabel.text = "关卡: \(snapshot.level.name)\(modeText)"

        let boostHint: String
        if snapshot.isManualStepModeEnabled {
            boostHint = "   手动步进中"
        } else if snapshot.boostMovesRemaining > 0 {
            boostHint = "   加速喷射中"
        } else if !boostStatus.hasEnoughLength {
            boostHint = "   加速需至少 4 节"
        } else if boostStatus.isReady {
            boostHint = boostStatus.isHeld ? "   加速触发中" : "   加速 Ready"
        } else {
            boostHint = String(format: "   聚能 %.0f%%", boostStatus.chargeProgress * 100)
        }
        modifierLabel.text = "词条: \(snapshot.modifier.badge) \(snapshot.modifier.title)\(boostHint)"

        let comboText = snapshot.comboCount >= 2 ? "   连击 x\(snapshot.comboCount) +\(snapshot.comboBonus)" : ""
        let heartText = heartText(current: snapshot.remainingHitPoints, maximum: snapshot.maxHitPoints)
        scoreLabel.text = "得分: \(snapshot.score)   最高: \(snapshot.highScore)   长度: \(snapshot.snake.count)   血量: \(heartText)\(comboText)"

        if let fruit = snapshot.fruit {
            let timerText = snapshot.fruitCountdown.map { "  ⏳\($0)" } ?? ""
            let effectText = fruit.effect == .normal ? "" : " \(fruit.effect.badge)"
            let stateText = snapshot.activeEffectText.map { "   \($0)" } ?? ""
            fruitLabel.text = "\(theme.collectibleLabelTitle): \(theme.collectibleSymbol(for: fruit.kind)) \(theme.collectibleName(for: fruit.kind))\(effectText)  +\(fruit.growth)\(timerText)\(stateText)"
        } else {
            fruitLabel.text = "\(theme.collectibleLabelTitle): 无"
        }

        let deliveryProgressText = snapshot.deliveryStation.map { station in
            let collected = Set(station.collectedKinds).count
            let total = Set(station.route.requiredKinds).count
            if station.isCompleted {
                return "   \(station.route.station.symbol) 已送达"
            }
            return "   \(station.route.station.symbol) 送货 \(collected)/\(total)"
        } ?? ""
        missionLabel.text = "任务: \(snapshot.mission.title) · \(snapshot.missionProgress.summaryText)\(deliveryProgressText)"
        missionLabel.fontColor = snapshot.missionProgress.isCompleted
            ? SKColor(calibratedRed: 0.52, green: 0.90, blue: 0.64, alpha: 1.0)
            : SKColor(calibratedWhite: 0.92, alpha: 0.94)

        statusLabel.text = snapshot.statusText
        statusLabel.alpha = snapshot.isGameOver ? 1.0 : 0.95

        let compactHint = compactHintText(for: snapshot)
        hintLabel.text = compactHint
        hintLabel.alpha = snapshot.isGameOver ? 1.0 : 0.72
        hintLabel.isHidden = compactHint == nil
    }

    private static func compactHintText(for snapshot: GameSnapshot) -> String? {
        if snapshot.isGameOver {
            return snapshot.hintText
        }

        if snapshot.isManualStepModeEnabled {
            return "按一下方向，前进一步"
        }

        if let station = snapshot.deliveryStation {
            if station.isCompleted {
                return "\(station.route.station.symbol) 已送达"
            }
            if station.isReadyForDelivery {
                return "\(station.route.station.symbol) 开到\(station.route.station.title)"
            }
        }

        if let mechanicText = snapshot.mechanicText {
            return mechanicText
        }

        if snapshot.level.hasCollapsingTiles {
            return "注意塌陷地板"
        }

        if snapshot.statusText.contains("安全刹车") {
            return snapshot.statusText
        }

        return nil
    }

    private static func heartText(current: Int, maximum: Int) -> String {
        let filled = String(repeating: "❤️", count: max(0, current))
        let empty = String(repeating: "🤍", count: max(0, maximum - current))
        return filled + empty
    }

    static func renderBackdrop(
        on layer: SKNode,
        sceneSize: CGSize,
        accentColor: SKColor,
        snakeHeadColor: SKColor
    ) {
        layer.removeAllChildren()

        let largeCircle = SKShapeNode(circleOfRadius: max(sceneSize.width, sceneSize.height) * 0.34)
        largeCircle.fillColor = accentColor.withAlphaComponent(0.08)
        largeCircle.strokeColor = .clear
        largeCircle.position = CGPoint(x: sceneSize.width * 0.16, y: sceneSize.height * 0.08)
        layer.addChild(largeCircle)

        let mediumCircle = SKShapeNode(circleOfRadius: max(sceneSize.width, sceneSize.height) * 0.22)
        mediumCircle.fillColor = snakeHeadColor.withAlphaComponent(0.07)
        mediumCircle.strokeColor = .clear
        mediumCircle.position = CGPoint(x: -sceneSize.width * 0.22, y: -sceneSize.height * 0.18)
        layer.addChild(mediumCircle)

        let ring = SKShapeNode(circleOfRadius: max(sceneSize.width, sceneSize.height) * 0.28)
        ring.strokeColor = accentColor.withAlphaComponent(0.10)
        ring.fillColor = .clear
        ring.lineWidth = 18
        ring.position = CGPoint(x: -sceneSize.width * 0.30, y: sceneSize.height * 0.20)
        layer.addChild(ring)
    }
}
