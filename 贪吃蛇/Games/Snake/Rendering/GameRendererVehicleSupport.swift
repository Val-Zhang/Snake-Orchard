//
//  GameRendererVehicleSupport.swift
//  贪吃蛇
//
//  Created by Codex on 2026/3/8.
//

import SpriteKit

enum GameRendererVehicleSupport {
    static func renderMotorcade(
        on layer: SKNode,
        snake: [GridPoint],
        isSimpleModeEnabled: Bool,
        trainCarriages: [FruitKind?],
        direction: Direction,
        boostStatus: BoostStatusSnapshot,
        isBoosting: Bool,
        cellSize: CGFloat,
        theme: VisualTheme,
        headColor: SKColor,
        bodyColor: SKColor,
        pointFor: (GridPoint) -> CGPoint
    ) {
        for (index, segment) in snake.enumerated() {
            if index > 0 {
                let previousSegment = snake[index - 1]
                let coupler = themedCoupler(
                    from: pointFor(previousSegment),
                    to: pointFor(segment),
                    theme: theme,
                    cellSize: cellSize
                )
                layer.addChild(coupler)
            }

            let isHead = index == 0
            let carNode = SKShapeNode(
                rectOf: CGSize(width: cellSize * (isHead ? 0.92 : 0.82), height: cellSize * 0.62),
                cornerRadius: cellSize * 0.14
            )
            carNode.position = pointFor(segment)
            carNode.zRotation = isHead ? direction.rotationAngle : carriageRotation(for: snake, at: index)
            carNode.fillColor = isHead ? headColor : bodyColor
            carNode.strokeColor = SKColor(calibratedWhite: 0.08, alpha: 0.28)
            carNode.lineWidth = 1
            layer.addChild(carNode)

            decorateMotorcadeCar(
                carNode,
                kind: isHead ? nil : (index - 1 < trainCarriages.count ? trainCarriages[index - 1] : nil),
                isHead: isHead,
                isSimpleModeEnabled: isSimpleModeEnabled,
                theme: theme,
                cellSize: cellSize
            )

            if isHead {
                if boostStatus.isReady {
                    addBoostReadyEffect(to: carNode, size: cellSize * 0.96)
                }
                if isBoosting {
                    addBoostTrail(to: carNode, direction: direction, theme: theme, intensity: 0.94, cellSize: cellSize)
                }
            }

            let label = SKLabelNode(fontNamed: "AppleColorEmoji")
            label.fontSize = cellSize * (isHead ? 0.34 : 0.30)
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            label.text = isHead
                ? headVehicleSymbol(for: theme)
                : vehicleSymbol(for: index - 1 < trainCarriages.count ? trainCarriages[index - 1] : nil, theme: theme)
            label.position = CGPoint(x: 0, y: -cellSize * 0.02)
            carNode.addChild(label)
        }
    }

    static func renderTrain(
        on layer: SKNode,
        snake: [GridPoint],
        trainCarriages: [FruitKind?],
        direction: Direction,
        boostStatus: BoostStatusSnapshot,
        isBoosting: Bool,
        cellSize: CGFloat,
        theme: VisualTheme,
        headColor: SKColor,
        bodyColor: SKColor,
        pointFor: (GridPoint) -> CGPoint
    ) {
        for (index, segment) in snake.enumerated() {
            if index > 0 {
                let previousSegment = snake[index - 1]
                let coupler = themedCoupler(
                    from: pointFor(previousSegment),
                    to: pointFor(segment),
                    theme: theme,
                    cellSize: cellSize
                )
                layer.addChild(coupler)
            }

            if index == 0 {
                let engineNode = SKShapeNode(
                    rectOf: CGSize(width: cellSize * 0.94, height: cellSize * 0.78),
                    cornerRadius: cellSize * 0.16
                )
                engineNode.position = pointFor(segment)
                engineNode.zRotation = direction.rotationAngle
                engineNode.fillColor = headColor
                engineNode.strokeColor = SKColor(calibratedWhite: 0.08, alpha: 0.28)
                engineNode.lineWidth = 1.2
                layer.addChild(engineNode)

                if boostStatus.isReady {
                    addBoostReadyEffect(to: engineNode, size: cellSize)
                }
                if isBoosting {
                    addBoostTrail(to: engineNode, direction: direction, theme: theme, intensity: 1.0, cellSize: cellSize)
                }

                let cabin = SKShapeNode(
                    rectOf: CGSize(width: cellSize * 0.34, height: cellSize * 0.30),
                    cornerRadius: cellSize * 0.08
                )
                cabin.position = CGPoint(x: cellSize * 0.08, y: cellSize * 0.16)
                cabin.fillColor = SKColor(calibratedRed: 1.0, green: 0.90, blue: 0.66, alpha: 1.0)
                cabin.strokeColor = .clear
                engineNode.addChild(cabin)

                let chimney = SKShapeNode(
                    rectOf: CGSize(width: cellSize * 0.12, height: cellSize * 0.20),
                    cornerRadius: cellSize * 0.04
                )
                chimney.position = CGPoint(x: -cellSize * 0.16, y: cellSize * 0.20)
                chimney.fillColor = SKColor(calibratedWhite: 0.18, alpha: 1.0)
                chimney.strokeColor = .clear
                engineNode.addChild(chimney)

                decorateTrainEngine(engineNode, theme: theme, cellSize: cellSize)
                addTrainWheels(to: engineNode, xOffsets: [-0.20, 0.18], cellSize: cellSize)
                continue
            }

            let carriageKind = index - 1 < trainCarriages.count ? trainCarriages[index - 1] : nil
            let carriageNode = SKShapeNode(
                rectOf: CGSize(width: cellSize * 0.82, height: cellSize * 0.64),
                cornerRadius: cellSize * 0.14
            )
            carriageNode.position = pointFor(segment)
            carriageNode.zRotation = carriageRotation(for: snake, at: index)
            carriageNode.fillColor = carriageKind?.color ?? bodyColor
            carriageNode.strokeColor = SKColor(calibratedWhite: 0.08, alpha: 0.22)
            carriageNode.lineWidth = 1.0
            layer.addChild(carriageNode)

            decorateTrainCarriage(carriageNode, kind: carriageKind, cellSize: cellSize)

            let roof = SKShapeNode(
                rectOf: CGSize(width: cellSize * 0.72, height: cellSize * 0.14),
                cornerRadius: cellSize * 0.08
            )
            roof.position = CGPoint(x: 0, y: cellSize * 0.20)
            roof.fillColor = SKColor(calibratedWhite: 1.0, alpha: 0.20)
            roof.strokeColor = .clear
            carriageNode.addChild(roof)

            addTrainWheels(to: carriageNode, xOffsets: [-0.18, 0.18], cellSize: cellSize)

            let label = SKLabelNode(fontNamed: carriageKind == nil ? "AvenirNext-Bold" : "AppleColorEmoji")
            label.fontSize = cellSize * 0.28
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            label.fontColor = SKColor(calibratedWhite: 1.0, alpha: 0.92)
            label.text = carriageKind?.symbol ?? "C"
            label.position = CGPoint(x: 0, y: -cellSize * 0.02)
            carriageNode.addChild(label)
        }
    }

    static func addBoostReadyEffect(to node: SKNode, size: CGFloat) {
        let aura = SKShapeNode(circleOfRadius: size * 0.58)
        aura.strokeColor = SKColor(calibratedRed: 1.0, green: 0.86, blue: 0.34, alpha: 0.95)
        aura.fillColor = SKColor(calibratedRed: 1.0, green: 0.86, blue: 0.34, alpha: 0.10)
        aura.lineWidth = 2
        aura.zPosition = -1
        node.addChild(aura)
        aura.run(.repeatForever(.sequence([
            .group([
                .scale(to: 1.14, duration: 0.22),
                .fadeAlpha(to: 0.42, duration: 0.22)
            ]),
            .group([
                .scale(to: 0.94, duration: 0.22),
                .fadeAlpha(to: 0.92, duration: 0.22)
            ])
        ])))

        let sparkle = SKLabelNode(fontNamed: "AvenirNext-Bold")
        sparkle.fontSize = size * 0.34
        sparkle.fontColor = SKColor(calibratedRed: 1.0, green: 0.92, blue: 0.46, alpha: 0.96)
        sparkle.text = "⚡"
        sparkle.position = CGPoint(x: 0, y: size * 0.54)
        node.addChild(sparkle)
        sparkle.run(.repeatForever(.sequence([
            .group([
                .moveBy(x: 0, y: size * 0.08, duration: 0.28),
                .fadeAlpha(to: 0.68, duration: 0.28)
            ]),
            .group([
                .moveBy(x: 0, y: -size * 0.08, duration: 0.28),
                .fadeAlpha(to: 1.0, duration: 0.28)
            ])
        ])))
    }

    static func addBoostTrail(to node: SKNode, direction: Direction, theme: VisualTheme, intensity: CGFloat, cellSize: CGFloat) {
        let offset = boostTrailOffset(for: direction, distance: cellSize * 0.44)
        let colors = boostTrailColors(for: theme)

        for index in 0 ..< 3 {
            let flame = SKShapeNode(circleOfRadius: cellSize * (0.10 + CGFloat(index) * 0.04) * intensity)
            flame.position = CGPoint(
                x: offset.x - CGFloat(index) * offset.x * 0.34,
                y: offset.y - CGFloat(index) * offset.y * 0.34
            )
            flame.fillColor = colors[min(index, colors.count - 1)].withAlphaComponent(0.86 - CGFloat(index) * 0.18)
            flame.strokeColor = .clear
            flame.zPosition = -1
            node.addChild(flame)
            flame.run(.repeatForever(.sequence([
                .group([
                    .scale(to: 1.24, duration: 0.16),
                    .fadeAlpha(to: 0.34, duration: 0.16)
                ]),
                .group([
                    .scale(to: 0.88, duration: 0.16),
                    .fadeAlpha(to: 0.92, duration: 0.16)
                ])
            ])))
        }

        if theme == .racing {
            let lineOffsets: [CGFloat] = [-0.16, 0, 0.16]
            for (index, yOffset) in lineOffsets.enumerated() {
                let forwardOffset = boostTrailOffset(for: direction, distance: cellSize * 0.10)
                let motion = CGVector(dx: forwardOffset.x, dy: forwardOffset.y)
                let line = SKShapeNode(
                    rectOf: CGSize(
                        width: cellSize * (0.28 - CGFloat(index) * 0.04) * intensity,
                        height: cellSize * 0.04
                    ),
                    cornerRadius: cellSize * 0.02
                )
                line.position = CGPoint(
                    x: offset.x * (0.74 + CGFloat(index) * 0.18),
                    y: offset.y * (0.74 + CGFloat(index) * 0.18) + cellSize * yOffset
                )
                line.fillColor = colors[min(index, colors.count - 1)].withAlphaComponent(0.82 - CGFloat(index) * 0.16)
                line.strokeColor = .clear
                line.zRotation = direction == .up || direction == .down ? .pi / 2 : 0
                line.zPosition = -2
                node.addChild(line)
                line.run(.repeatForever(.sequence([
                    .group([
                        .move(by: motion, duration: 0.12),
                        .fadeAlpha(to: 0.12, duration: 0.12),
                        .scaleX(to: 1.18, duration: 0.12)
                    ]),
                    .group([
                        .move(by: CGVector(dx: -motion.dx, dy: -motion.dy), duration: 0.12),
                        .fadeAlpha(to: 0.74, duration: 0.12),
                        .scaleX(to: 0.92, duration: 0.12)
                    ])
                ])))
            }

            let flag = SKLabelNode(fontNamed: "AvenirNext-Bold")
            flag.fontSize = cellSize * 0.14
            flag.fontColor = SKColor(calibratedWhite: 0.98, alpha: 0.92)
            flag.text = "▣"
            flag.position = CGPoint(x: offset.x * 0.90, y: offset.y * 0.90)
            flag.zPosition = -1
            node.addChild(flag)
            flag.run(.repeatForever(.sequence([
                .group([
                    .fadeAlpha(to: 0.26, duration: 0.12),
                    .scale(to: 1.16, duration: 0.12)
                ]),
                .group([
                    .fadeAlpha(to: 0.88, duration: 0.12),
                    .scale(to: 0.94, duration: 0.12)
                ])
            ])))
        }
    }

    private static func addTrainWheels(to node: SKNode, xOffsets: [CGFloat], cellSize: CGFloat) {
        for xOffset in xOffsets {
            let wheel = SKShapeNode(circleOfRadius: cellSize * 0.07)
            wheel.fillColor = SKColor(calibratedWhite: 0.14, alpha: 1.0)
            wheel.strokeColor = SKColor(calibratedWhite: 0.75, alpha: 0.32)
            wheel.lineWidth = 1
            wheel.position = CGPoint(x: cellSize * xOffset, y: -cellSize * 0.24)
            node.addChild(wheel)
        }
    }

    private static func themedCoupler(from start: CGPoint, to end: CGPoint, theme: VisualTheme, cellSize: CGFloat) -> SKNode {
        let container = SKNode()

        let base = SKShapeNode(path: couplerPath(from: start, to: end))
        base.lineWidth = cellSize * 0.14
        base.lineCap = .round

        switch theme {
        case .orchard:
            base.strokeColor = SKColor(calibratedWhite: 0.14, alpha: 0.72)
        case .sunset:
            base.strokeColor = SKColor(calibratedRed: 0.72, green: 0.42, blue: 0.18, alpha: 0.84)
        case .mint:
            base.strokeColor = SKColor(calibratedRed: 0.38, green: 0.76, blue: 0.66, alpha: 0.84)
        case .neon:
            base.strokeColor = SKColor(calibratedRed: 0.34, green: 0.96, blue: 1.0, alpha: 0.84)
            base.glowWidth = cellSize * 0.12
        case .motorcade:
            base.strokeColor = SKColor(calibratedRed: 0.42, green: 0.48, blue: 0.56, alpha: 0.88)
        case .police:
            base.strokeColor = SKColor(calibratedRed: 0.18, green: 0.28, blue: 0.44, alpha: 0.92)
        case .construction:
            base.strokeColor = SKColor(calibratedRed: 0.58, green: 0.42, blue: 0.10, alpha: 0.92)
        case .racing:
            base.strokeColor = SKColor(calibratedRed: 0.74, green: 0.18, blue: 0.16, alpha: 0.92)
        }
        container.addChild(base)

        let midPoint = CGPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2)
        switch theme {
        case .orchard:
            let clasp = SKShapeNode(circleOfRadius: cellSize * 0.05)
            clasp.position = midPoint
            clasp.fillColor = SKColor(calibratedRed: 0.52, green: 0.34, blue: 0.18, alpha: 0.92)
            clasp.strokeColor = .clear
            container.addChild(clasp)
        case .sunset:
            let plate = SKShapeNode(
                rectOf: CGSize(width: cellSize * 0.18, height: cellSize * 0.08),
                cornerRadius: cellSize * 0.03
            )
            plate.position = midPoint
            plate.fillColor = SKColor(calibratedRed: 1.0, green: 0.78, blue: 0.38, alpha: 0.90)
            plate.strokeColor = .clear
            container.addChild(plate)
        case .mint:
            let mintDot = SKShapeNode(circleOfRadius: cellSize * 0.055)
            mintDot.position = midPoint
            mintDot.fillColor = SKColor(calibratedRed: 0.92, green: 1.0, blue: 0.96, alpha: 0.96)
            mintDot.strokeColor = .clear
            container.addChild(mintDot)
        case .neon:
            let spark = SKLabelNode(fontNamed: "AvenirNext-Bold")
            spark.fontSize = cellSize * 0.18
            spark.fontColor = SKColor(calibratedRed: 1.0, green: 0.54, blue: 0.92, alpha: 0.96)
            spark.text = "✦"
            spark.position = CGPoint(x: midPoint.x, y: midPoint.y - cellSize * 0.03)
            container.addChild(spark)
        case .motorcade:
            let plate = SKShapeNode(
                rectOf: CGSize(width: cellSize * 0.18, height: cellSize * 0.10),
                cornerRadius: cellSize * 0.03
            )
            plate.position = midPoint
            plate.fillColor = SKColor(calibratedRed: 0.96, green: 0.92, blue: 0.74, alpha: 0.92)
            plate.strokeColor = .clear
            container.addChild(plate)
        case .police:
            let light = SKShapeNode(
                rectOf: CGSize(width: cellSize * 0.18, height: cellSize * 0.06),
                cornerRadius: cellSize * 0.02
            )
            light.position = midPoint
            light.fillColor = SKColor(calibratedRed: 0.76, green: 0.14, blue: 0.14, alpha: 0.94)
            light.strokeColor = .clear
            container.addChild(light)

            let blueHalf = SKShapeNode(
                rectOf: CGSize(width: cellSize * 0.08, height: cellSize * 0.06),
                cornerRadius: cellSize * 0.02
            )
            blueHalf.position = CGPoint(x: midPoint.x + cellSize * 0.04, y: midPoint.y)
            blueHalf.fillColor = SKColor(calibratedRed: 0.28, green: 0.52, blue: 1.0, alpha: 0.96)
            blueHalf.strokeColor = .clear
            container.addChild(blueHalf)
        case .construction:
            let stripe = SKLabelNode(fontNamed: "AvenirNext-Bold")
            stripe.fontSize = cellSize * 0.16
            stripe.fontColor = SKColor(calibratedRed: 0.96, green: 0.84, blue: 0.24, alpha: 0.96)
            stripe.text = "▥"
            stripe.position = CGPoint(x: midPoint.x, y: midPoint.y - cellSize * 0.03)
            container.addChild(stripe)
        case .racing:
            let flag = SKLabelNode(fontNamed: "AvenirNext-Bold")
            flag.fontSize = cellSize * 0.16
            flag.fontColor = SKColor(calibratedWhite: 0.98, alpha: 0.96)
            flag.text = "▣"
            flag.position = CGPoint(x: midPoint.x, y: midPoint.y - cellSize * 0.03)
            container.addChild(flag)
        }

        return container
    }

    private static func boostTrailOffset(for direction: Direction, distance: CGFloat) -> CGPoint {
        switch direction {
        case .right:
            return CGPoint(x: -distance, y: 0)
        case .left:
            return CGPoint(x: distance, y: 0)
        case .up:
            return CGPoint(x: 0, y: -distance)
        case .down:
            return CGPoint(x: 0, y: distance)
        }
    }

    private static func boostTrailColors(for theme: VisualTheme) -> [SKColor] {
        switch theme {
        case .orchard:
            return [
                SKColor(calibratedRed: 1.0, green: 0.84, blue: 0.34, alpha: 1.0),
                SKColor(calibratedRed: 0.94, green: 0.56, blue: 0.26, alpha: 1.0),
                SKColor(calibratedRed: 0.72, green: 0.30, blue: 0.16, alpha: 1.0)
            ]
        case .sunset:
            return [
                SKColor(calibratedRed: 1.0, green: 0.92, blue: 0.48, alpha: 1.0),
                SKColor(calibratedRed: 1.0, green: 0.62, blue: 0.28, alpha: 1.0),
                SKColor(calibratedRed: 0.82, green: 0.30, blue: 0.22, alpha: 1.0)
            ]
        case .mint:
            return [
                SKColor(calibratedRed: 0.92, green: 1.0, blue: 0.96, alpha: 1.0),
                SKColor(calibratedRed: 0.56, green: 0.94, blue: 0.84, alpha: 1.0),
                SKColor(calibratedRed: 0.28, green: 0.74, blue: 0.66, alpha: 1.0)
            ]
        case .neon:
            return [
                SKColor(calibratedRed: 0.30, green: 0.96, blue: 1.0, alpha: 1.0),
                SKColor(calibratedRed: 1.0, green: 0.34, blue: 0.90, alpha: 1.0),
                SKColor(calibratedRed: 0.44, green: 0.20, blue: 0.98, alpha: 1.0)
            ]
        case .motorcade:
            return [
                SKColor(calibratedRed: 0.94, green: 0.96, blue: 1.0, alpha: 1.0),
                SKColor(calibratedRed: 0.62, green: 0.84, blue: 1.0, alpha: 1.0),
                SKColor(calibratedRed: 1.0, green: 0.74, blue: 0.26, alpha: 1.0)
            ]
        case .police:
            return [
                SKColor(calibratedRed: 0.96, green: 0.14, blue: 0.14, alpha: 1.0),
                SKColor(calibratedRed: 0.26, green: 0.52, blue: 1.0, alpha: 1.0),
                SKColor(calibratedRed: 0.94, green: 0.96, blue: 1.0, alpha: 1.0)
            ]
        case .construction:
            return [
                SKColor(calibratedRed: 0.98, green: 0.84, blue: 0.22, alpha: 1.0),
                SKColor(calibratedRed: 0.96, green: 0.56, blue: 0.16, alpha: 1.0),
                SKColor(calibratedRed: 0.34, green: 0.30, blue: 0.20, alpha: 1.0)
            ]
        case .racing:
            return [
                SKColor(calibratedWhite: 1.0, alpha: 1.0),
                SKColor(calibratedRed: 1.0, green: 0.16, blue: 0.16, alpha: 1.0),
                SKColor(calibratedRed: 0.16, green: 0.16, blue: 0.18, alpha: 1.0)
            ]
        }
    }

    private static func decorateTrainEngine(_ engineNode: SKShapeNode, theme: VisualTheme, cellSize: CGFloat) {
        switch theme {
        case .orchard:
            let bumper = SKShapeNode(
                rectOf: CGSize(width: cellSize * 0.22, height: cellSize * 0.10),
                cornerRadius: cellSize * 0.03
            )
            bumper.position = CGPoint(x: cellSize * 0.34, y: -cellSize * 0.08)
            bumper.fillColor = SKColor(calibratedRed: 0.58, green: 0.40, blue: 0.20, alpha: 0.96)
            bumper.strokeColor = .clear
            engineNode.addChild(bumper)

            let leaf = SKShapeNode(
                rectOf: CGSize(width: cellSize * 0.16, height: cellSize * 0.08),
                cornerRadius: cellSize * 0.04
            )
            leaf.position = CGPoint(x: cellSize * 0.06, y: cellSize * 0.30)
            leaf.zRotation = .pi / 5
            leaf.fillColor = SKColor(calibratedRed: 0.32, green: 0.74, blue: 0.28, alpha: 0.94)
            leaf.strokeColor = .clear
            engineNode.addChild(leaf)
        case .sunset:
            let stripe = SKShapeNode(
                rectOf: CGSize(width: cellSize * 0.64, height: cellSize * 0.10),
                cornerRadius: cellSize * 0.05
            )
            stripe.position = CGPoint(x: 0, y: -cellSize * 0.02)
            stripe.fillColor = SKColor(calibratedRed: 1.0, green: 0.80, blue: 0.42, alpha: 0.92)
            stripe.strokeColor = .clear
            engineNode.addChild(stripe)

            let sunHalo = SKShapeNode(circleOfRadius: cellSize * 0.14)
            sunHalo.position = CGPoint(x: cellSize * 0.26, y: cellSize * 0.18)
            sunHalo.fillColor = SKColor(calibratedRed: 1.0, green: 0.90, blue: 0.56, alpha: 0.28)
            sunHalo.strokeColor = SKColor(calibratedRed: 1.0, green: 0.86, blue: 0.42, alpha: 0.68)
            sunHalo.lineWidth = 1.2
            engineNode.addChild(sunHalo)
        case .mint:
            let candyStripeA = SKShapeNode(
                rectOf: CGSize(width: cellSize * 0.14, height: cellSize * 0.74),
                cornerRadius: cellSize * 0.04
            )
            candyStripeA.position = CGPoint(x: -cellSize * 0.12, y: 0)
            candyStripeA.zRotation = -.pi / 8
            candyStripeA.fillColor = SKColor(calibratedRed: 0.92, green: 1.0, blue: 0.96, alpha: 0.92)
            candyStripeA.strokeColor = .clear
            engineNode.addChild(candyStripeA)

            let candyStripeB = candyStripeA.copy() as? SKShapeNode ?? SKShapeNode()
            candyStripeB.position = CGPoint(x: cellSize * 0.10, y: 0)
            engineNode.addChild(candyStripeB)

            let bell = SKShapeNode(circleOfRadius: cellSize * 0.07)
            bell.position = CGPoint(x: -cellSize * 0.24, y: cellSize * 0.28)
            bell.fillColor = SKColor(calibratedRed: 0.98, green: 0.92, blue: 0.64, alpha: 1.0)
            bell.strokeColor = SKColor(calibratedRed: 0.80, green: 0.66, blue: 0.24, alpha: 0.7)
            bell.lineWidth = 1
            engineNode.addChild(bell)
        case .neon:
            let rail = SKShapeNode(
                rectOf: CGSize(width: cellSize * 0.70, height: cellSize * 0.08),
                cornerRadius: cellSize * 0.04
            )
            rail.position = CGPoint(x: 0, y: cellSize * 0.26)
            rail.fillColor = SKColor(calibratedRed: 0.30, green: 0.96, blue: 1.0, alpha: 0.88)
            rail.strokeColor = .clear
            engineNode.addChild(rail)

            let noseGlow = SKShapeNode(circleOfRadius: cellSize * 0.10)
            noseGlow.position = CGPoint(x: cellSize * 0.34, y: 0)
            noseGlow.fillColor = SKColor(calibratedRed: 1.0, green: 0.34, blue: 0.88, alpha: 0.30)
            noseGlow.strokeColor = SKColor(calibratedRed: 1.0, green: 0.60, blue: 0.92, alpha: 0.92)
            noseGlow.lineWidth = 1.2
            engineNode.addChild(noseGlow)

            let star = SKLabelNode(fontNamed: "AvenirNext-Bold")
            star.fontSize = cellSize * 0.18
            star.fontColor = SKColor(calibratedRed: 0.96, green: 0.90, blue: 1.0, alpha: 0.96)
            star.text = "✦"
            star.position = CGPoint(x: -cellSize * 0.02, y: cellSize * 0.30)
            engineNode.addChild(star)
        case .motorcade:
            let hood = SKShapeNode(
                rectOf: CGSize(width: cellSize * 0.24, height: cellSize * 0.18),
                cornerRadius: cellSize * 0.08
            )
            hood.position = CGPoint(x: cellSize * 0.26, y: -cellSize * 0.02)
            hood.fillColor = SKColor(calibratedRed: 0.98, green: 0.88, blue: 0.22, alpha: 0.96)
            hood.strokeColor = .clear
            engineNode.addChild(hood)

            let windshield = SKShapeNode(
                rectOf: CGSize(width: cellSize * 0.26, height: cellSize * 0.16),
                cornerRadius: cellSize * 0.05
            )
            windshield.position = CGPoint(x: -cellSize * 0.08, y: cellSize * 0.12)
            windshield.fillColor = SKColor(calibratedRed: 0.82, green: 0.92, blue: 1.0, alpha: 0.90)
            windshield.strokeColor = .clear
            engineNode.addChild(windshield)
        case .police, .construction, .racing:
            let hood = SKShapeNode(
                rectOf: CGSize(width: cellSize * 0.24, height: cellSize * 0.18),
                cornerRadius: cellSize * 0.08
            )
            hood.position = CGPoint(x: cellSize * 0.26, y: -cellSize * 0.02)
            switch theme {
            case .police:
                hood.fillColor = SKColor(calibratedRed: 0.94, green: 0.96, blue: 1.0, alpha: 0.96)
            case .construction:
                hood.fillColor = SKColor(calibratedRed: 0.98, green: 0.82, blue: 0.22, alpha: 0.96)
            case .racing:
                hood.fillColor = SKColor(calibratedRed: 1.0, green: 0.18, blue: 0.18, alpha: 0.96)
            default:
                hood.fillColor = .clear
            }
            hood.strokeColor = .clear
            engineNode.addChild(hood)
        }
    }

    private static func decorateMotorcadeCar(
        _ node: SKShapeNode,
        kind: FruitKind?,
        isHead: Bool,
        isSimpleModeEnabled: Bool,
        theme: VisualTheme,
        cellSize: CGFloat
    ) {
        let windshield = SKShapeNode(
            rectOf: CGSize(width: cellSize * 0.28, height: cellSize * 0.16),
            cornerRadius: cellSize * 0.05
        )
        windshield.position = CGPoint(x: -cellSize * 0.06, y: cellSize * 0.10)
        windshield.fillColor = SKColor(calibratedRed: 0.84, green: 0.94, blue: 1.0, alpha: 0.88)
        windshield.strokeColor = .clear
        node.addChild(windshield)

        let rearGlass = SKShapeNode(
            rectOf: CGSize(width: cellSize * 0.18, height: cellSize * 0.12),
            cornerRadius: cellSize * 0.04
        )
        rearGlass.position = CGPoint(x: cellSize * 0.16, y: cellSize * 0.08)
        rearGlass.fillColor = SKColor(calibratedRed: 0.80, green: 0.90, blue: 0.98, alpha: 0.72)
        rearGlass.strokeColor = .clear
        node.addChild(rearGlass)

        addTrainWheels(to: node, xOffsets: [-0.22, 0.22], cellSize: cellSize)

        if isHead {
            switch theme {
            case .motorcade:
                let headlight = SKShapeNode(circleOfRadius: cellSize * 0.04)
                headlight.position = CGPoint(x: cellSize * 0.32, y: -cellSize * 0.04)
                headlight.fillColor = SKColor(calibratedRed: 1.0, green: 0.96, blue: 0.72, alpha: 0.98)
                headlight.strokeColor = .clear
                node.addChild(headlight)
            case .police:
                let lightBar = SKShapeNode(
                    rectOf: CGSize(width: cellSize * 0.30, height: cellSize * 0.07),
                    cornerRadius: cellSize * 0.03
                )
                lightBar.position = CGPoint(x: 0, y: cellSize * 0.22)
                lightBar.fillColor = SKColor(calibratedWhite: 0.92, alpha: 0.18)
                lightBar.strokeColor = .clear
                node.addChild(lightBar)

                let redCap = SKShapeNode(
                    rectOf: CGSize(width: cellSize * 0.14, height: cellSize * 0.07),
                    cornerRadius: cellSize * 0.03
                )
                redCap.position = CGPoint(x: -cellSize * 0.08, y: cellSize * 0.22)
                redCap.fillColor = SKColor(calibratedRed: 0.86, green: 0.16, blue: 0.16, alpha: 0.98)
                redCap.strokeColor = .clear
                node.addChild(redCap)

                let blueCap = SKShapeNode(
                    rectOf: CGSize(width: cellSize * 0.14, height: cellSize * 0.07),
                    cornerRadius: cellSize * 0.03
                )
                blueCap.position = CGPoint(x: cellSize * 0.08, y: cellSize * 0.22)
                blueCap.fillColor = SKColor(calibratedRed: 0.28, green: 0.52, blue: 1.0, alpha: 0.98)
                blueCap.strokeColor = .clear
                node.addChild(blueCap)

                let flashDuration = 0.18
                redCap.run(.repeatForever(.sequence([
                    .fadeAlpha(to: 1.0, duration: flashDuration),
                    .fadeAlpha(to: 0.26, duration: flashDuration)
                ])))
                blueCap.run(.repeatForever(.sequence([
                    .fadeAlpha(to: 0.24, duration: flashDuration),
                    .fadeAlpha(to: 1.0, duration: flashDuration)
                ])))
            case .construction:
                let boom = SKShapeNode(
                    rectOf: CGSize(width: cellSize * 0.30, height: cellSize * 0.08),
                    cornerRadius: cellSize * 0.03
                )
                boom.position = CGPoint(x: cellSize * 0.16, y: cellSize * 0.18)
                boom.zRotation = -.pi / 7
                boom.fillColor = SKColor(calibratedRed: 0.96, green: 0.74, blue: 0.18, alpha: 0.96)
                boom.strokeColor = .clear
                node.addChild(boom)

                let hook = SKShapeNode(circleOfRadius: cellSize * 0.035)
                hook.position = CGPoint(x: cellSize * 0.14, y: cellSize * 0.08)
                hook.fillColor = SKColor(calibratedRed: 0.26, green: 0.22, blue: 0.18, alpha: 0.96)
                hook.strokeColor = .clear
                boom.addChild(hook)

                let stripe = SKLabelNode(fontNamed: "AvenirNext-Bold")
                stripe.fontSize = cellSize * 0.17
                stripe.fontColor = SKColor(calibratedRed: 0.20, green: 0.18, blue: 0.14, alpha: 0.74)
                stripe.text = "▨"
                stripe.position = CGPoint(x: 0, y: -cellSize * 0.04)
                node.addChild(stripe)

                boom.run(.repeatForever(.sequence([
                    .rotate(toAngle: -.pi / 10, duration: 0.32, shortestUnitArc: true),
                    .rotate(toAngle: -.pi / 5, duration: 0.32, shortestUnitArc: true)
                ])))
            case .racing:
                let spoiler = SKShapeNode(
                    rectOf: CGSize(width: cellSize * 0.24, height: cellSize * 0.05),
                    cornerRadius: cellSize * 0.02
                )
                spoiler.position = CGPoint(x: -cellSize * 0.28, y: cellSize * 0.18)
                spoiler.fillColor = SKColor(calibratedRed: 0.10, green: 0.10, blue: 0.12, alpha: 0.96)
                spoiler.strokeColor = .clear
                node.addChild(spoiler)

                let flagStripe = SKLabelNode(fontNamed: "AvenirNext-Bold")
                flagStripe.fontSize = cellSize * 0.18
                flagStripe.fontColor = SKColor(calibratedWhite: 0.96, alpha: 0.82)
                flagStripe.text = "▣"
                flagStripe.position = CGPoint(x: 0, y: -cellSize * 0.02)
                node.addChild(flagStripe)

                let speedLine = SKShapeNode(
                    rectOf: CGSize(width: cellSize * 0.18, height: cellSize * 0.03),
                    cornerRadius: cellSize * 0.015
                )
                speedLine.position = CGPoint(x: -cellSize * 0.34, y: -cellSize * 0.04)
                speedLine.fillColor = SKColor(calibratedWhite: 0.96, alpha: 0.74)
                speedLine.strokeColor = .clear
                node.addChild(speedLine)
                speedLine.run(.repeatForever(.sequence([
                    .group([
                        .moveBy(x: -cellSize * 0.08, y: 0, duration: 0.12),
                        .fadeAlpha(to: 0.18, duration: 0.12)
                    ]),
                    .group([
                        .moveBy(x: cellSize * 0.08, y: 0, duration: 0.12),
                        .fadeAlpha(to: 0.74, duration: 0.12)
                    ])
                ])))
            default:
                break
            }
            return
        }

        if isSimpleModeEnabled, let kind {
            let stripe = SKShapeNode(
                rectOf: CGSize(width: cellSize * 0.54, height: cellSize * 0.08),
                cornerRadius: cellSize * 0.04
            )
            stripe.position = CGPoint(x: 0, y: -cellSize * 0.18)
            stripe.fillColor = kind.color.withAlphaComponent(0.36)
            stripe.strokeColor = .clear
            node.addChild(stripe)
        }
    }

    private static func vehicleSymbol(for kind: FruitKind?, theme: VisualTheme) -> String {
        guard let kind else {
            return headVehicleSymbol(for: theme)
        }
        return theme.collectibleSymbol(for: kind)
    }

    private static func headVehicleSymbol(for theme: VisualTheme) -> String {
        switch theme {
        case .police:
            return "🚔"
        case .construction:
            return "🚜"
        case .racing:
            return "🏎️"
        default:
            return "🚘"
        }
    }

    private static func decorateTrainCarriage(_ carriageNode: SKShapeNode, kind: FruitKind?, cellSize: CGFloat) {
        switch kind {
        case .banana:
            let stripe = SKShapeNode(
                rectOf: CGSize(width: cellSize * 0.62, height: cellSize * 0.12),
                cornerRadius: cellSize * 0.06
            )
            stripe.position = CGPoint(x: 0, y: 0)
            stripe.fillColor = SKColor(calibratedRed: 0.58, green: 0.42, blue: 0.10, alpha: 0.28)
            stripe.strokeColor = .clear
            carriageNode.addChild(stripe)
        case .apple:
            let leaf = SKShapeNode(
                rectOf: CGSize(width: cellSize * 0.14, height: cellSize * 0.08),
                cornerRadius: cellSize * 0.04
            )
            leaf.position = CGPoint(x: cellSize * 0.12, y: cellSize * 0.10)
            leaf.zRotation = .pi / 5
            leaf.fillColor = SKColor(calibratedRed: 0.30, green: 0.72, blue: 0.24, alpha: 0.96)
            leaf.strokeColor = .clear
            carriageNode.addChild(leaf)
        case .pomelo:
            let star = SKShapeNode(path: starPath(radius: cellSize * 0.12))
            star.position = CGPoint(x: 0, y: 0)
            star.fillColor = SKColor(calibratedWhite: 1.0, alpha: 0.34)
            star.strokeColor = .clear
            carriageNode.addChild(star)
        case .watermelon:
            let rind = SKShapeNode(
                rectOf: CGSize(width: cellSize * 0.66, height: cellSize * 0.10),
                cornerRadius: cellSize * 0.05
            )
            rind.position = CGPoint(x: 0, y: -cellSize * 0.10)
            rind.fillColor = SKColor(calibratedRed: 0.08, green: 0.42, blue: 0.16, alpha: 0.88)
            rind.strokeColor = .clear
            carriageNode.addChild(rind)
        case .peach:
            let blush = SKShapeNode(circleOfRadius: cellSize * 0.09)
            blush.position = CGPoint(x: cellSize * 0.10, y: -cellSize * 0.02)
            blush.fillColor = SKColor(calibratedRed: 1.0, green: 0.82, blue: 0.86, alpha: 0.42)
            blush.strokeColor = .clear
            carriageNode.addChild(blush)
        case nil:
            let window = SKShapeNode(
                rectOf: CGSize(width: cellSize * 0.18, height: cellSize * 0.14),
                cornerRadius: cellSize * 0.04
            )
            window.position = CGPoint(x: 0, y: cellSize * 0.02)
            window.fillColor = SKColor(calibratedWhite: 1.0, alpha: 0.28)
            window.strokeColor = .clear
            carriageNode.addChild(window)
        }
    }

    private static func carriageRotation(for snake: [GridPoint], at index: Int) -> CGFloat {
        let current = snake[index]
        let previous = snake[max(0, index - 1)]
        let next = index + 1 < snake.count ? snake[index + 1] : previous

        let dx = previous.x != current.x ? previous.x - current.x : current.x - next.x
        let dy = previous.y != current.y ? previous.y - current.y : current.y - next.y

        if abs(dx) >= abs(dy) {
            return 0
        }
        return .pi / 2
    }

    private static func couplerPath(from start: CGPoint, to end: CGPoint) -> CGPath {
        let path = CGMutablePath()
        path.move(to: start)
        path.addLine(to: end)
        return path
    }

    private static func starPath(radius: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let points = 5
        let innerRadius = radius * 0.48

        for index in 0 ..< points * 2 {
            let angle = CGFloat(index) * .pi / CGFloat(points) - .pi / 2
            let currentRadius = index.isMultiple(of: 2) ? radius : innerRadius
            let point = CGPoint(x: cos(angle) * currentRadius, y: sin(angle) * currentRadius)
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }

        path.closeSubpath()
        return path
    }
}
