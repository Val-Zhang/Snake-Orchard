//
//  GameRenderer.swift
//  贪吃蛇
//
//  Created by zhangwang on 2026/3/6.
//

import SpriteKit

final class GameRenderer {
    private struct LevelPalette {
        let background: SKColor
        let board: SKColor
        let obstacle: SKColor
        let snakeHead: SKColor
        let snakeBody: SKColor
        let accent: SKColor
    }

    private let backdropLayer = SKNode()
    private let boardContainer = SKNode()
    private let boardNode = SKShapeNode()
    private let obstacleLayer = SKNode()
    private let dynamicObstacleLayer = SKNode()
    private let temporaryHazardLayer = SKNode()
    private let snakeLayer = SKNode()
    private let fruitLayer = SKNode()
    private let hudLayer = SKNode()
    private let overlayLayer = SKNode()
    private let overlayPanel = SKShapeNode()
    private let overlayTitle = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let overlaySubtitle = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
    private let overlayMeta = SKLabelNode(fontNamed: "AvenirNext-Regular")
    private let overlayFooter = SKLabelNode(fontNamed: "AvenirNext-Regular")
    private let overlayOptionNodes = (0 ..< 8).map { _ in SKLabelNode(fontNamed: "AvenirNext-DemiBold") }
    private let overlayBadgeLayer = SKNode()

    private let levelLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let modifierLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
    private let scoreLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
    private let fruitLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
    private let missionLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
    private let statusLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let hintLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")

    private var boardFrame = CGRect.zero
    private var cellSize: CGFloat = 24
    private var attached = false
    private var renderedSceneSize = CGSize.zero
    private var renderedLevel: LevelDefinition?
    private var currentPalette = LevelPalette(
        background: SKColor(calibratedRed: 0.06, green: 0.08, blue: 0.12, alpha: 1.0),
        board: SKColor(calibratedRed: 0.10, green: 0.14, blue: 0.18, alpha: 1.0),
        obstacle: SKColor(calibratedRed: 0.36, green: 0.42, blue: 0.48, alpha: 1.0),
        snakeHead: SKColor(calibratedRed: 0.36, green: 0.88, blue: 0.53, alpha: 1.0),
        snakeBody: SKColor(calibratedRed: 0.20, green: 0.67, blue: 0.40, alpha: 1.0),
        accent: SKColor(calibratedRed: 0.84, green: 0.93, blue: 1.0, alpha: 1.0)
    )

    func attach(to scene: SKScene) {
        guard !attached else {
            return
        }

        scene.addChild(backdropLayer)
        boardNode.strokeColor = SKColor(calibratedWhite: 1.0, alpha: 0.16)
        boardNode.lineWidth = 2
        boardNode.fillColor = currentPalette.board

        scene.addChild(boardContainer)
        boardContainer.addChild(boardNode)
        boardContainer.addChild(obstacleLayer)
        boardContainer.addChild(dynamicObstacleLayer)
        boardContainer.addChild(temporaryHazardLayer)
        boardContainer.addChild(fruitLayer)
        boardContainer.addChild(snakeLayer)
        scene.addChild(hudLayer)
        scene.addChild(overlayLayer)

        configureLabel(levelLabel, size: 24, alignment: .left)
        configureLabel(modifierLabel, size: 18, alignment: .right)
        configureLabel(scoreLabel, size: 18, alignment: .left)
        configureLabel(fruitLabel, size: 18, alignment: .right)
        configureLabel(missionLabel, size: 17, alignment: .center)
        configureLabel(statusLabel, size: 28, alignment: .center)
        configureLabel(hintLabel, size: 16, alignment: .center)

        hudLayer.addChild(levelLabel)
        hudLayer.addChild(modifierLabel)
        hudLayer.addChild(scoreLabel)
        hudLayer.addChild(fruitLabel)
        hudLayer.addChild(missionLabel)
        hudLayer.addChild(statusLabel)
        hudLayer.addChild(hintLabel)

        overlayPanel.fillColor = SKColor(calibratedRed: 0.02, green: 0.04, blue: 0.08, alpha: 0.82)
        overlayPanel.strokeColor = SKColor(calibratedWhite: 1.0, alpha: 0.12)
        overlayPanel.lineWidth = 2
        overlayLayer.addChild(overlayPanel)

        configureLabel(overlayTitle, size: 30, alignment: .center)
        configureLabel(overlaySubtitle, size: 18, alignment: .center)
        configureLabel(overlayMeta, size: 15, alignment: .center)
        configureLabel(overlayFooter, size: 14, alignment: .center)
        overlayMeta.fontColor = SKColor(calibratedWhite: 0.92, alpha: 0.78)
        overlayFooter.fontColor = SKColor(calibratedWhite: 0.92, alpha: 0.68)
        overlayLayer.addChild(overlayTitle)
        overlayLayer.addChild(overlaySubtitle)
        overlayLayer.addChild(overlayMeta)
        overlayLayer.addChild(overlayFooter)
        overlayLayer.addChild(overlayBadgeLayer)
        for node in overlayOptionNodes {
            configureLabel(node, size: 18, alignment: .center)
            overlayLayer.addChild(node)
        }

        attached = true
    }

    func backgroundColor(for level: LevelDefinition) -> SKColor {
        palette(for: level).background
    }

    func updateLayout(sceneSize: CGSize, level: LevelDefinition) {
        guard attached else {
            return
        }

        guard renderedSceneSize != sceneSize || renderedLevel != level else {
            return
        }

        renderedSceneSize = sceneSize
        renderedLevel = level
        currentPalette = palette(for: level)

        let horizontalInset: CGFloat = 36
        let verticalInset: CGFloat = 110
        let usableWidth = max(sceneSize.width - horizontalInset * 2, 320)
        let usableHeight = max(sceneSize.height - verticalInset * 2, 240)

        cellSize = floor(min(
            usableWidth / CGFloat(level.columns),
            usableHeight / CGFloat(level.rows)
        ))

        let boardWidth = CGFloat(level.columns) * cellSize
        let boardHeight = CGFloat(level.rows) * cellSize
        boardFrame = CGRect(
            x: -boardWidth / 2,
            y: -boardHeight / 2,
            width: boardWidth,
            height: boardHeight
        )

        boardNode.path = CGPath(
            roundedRect: boardFrame.insetBy(dx: -8, dy: -8),
            cornerWidth: 16,
            cornerHeight: 16,
            transform: nil
        )
        boardNode.fillColor = currentPalette.board
        boardNode.strokeColor = currentPalette.accent.withAlphaComponent(0.20)

        levelLabel.position = CGPoint(x: boardFrame.minX, y: boardFrame.maxY + 56)
        modifierLabel.position = CGPoint(x: boardFrame.maxX, y: boardFrame.maxY + 56)
        scoreLabel.position = CGPoint(x: boardFrame.minX, y: boardFrame.maxY + 28)
        fruitLabel.position = CGPoint(x: boardFrame.maxX, y: boardFrame.maxY + 28)
        missionLabel.position = CGPoint(x: 0, y: boardFrame.minY - 20)
        statusLabel.position = CGPoint(x: 0, y: boardFrame.minY - 52)
        hintLabel.position = CGPoint(x: 0, y: boardFrame.minY - 82)

        let overlayWidth = min(boardFrame.width * 0.90, 520)
        let overlayHeight: CGFloat = 420
        let overlayRect = CGRect(x: -overlayWidth / 2, y: -overlayHeight / 2, width: overlayWidth, height: overlayHeight)
        overlayPanel.path = CGPath(roundedRect: overlayRect, cornerWidth: 20, cornerHeight: 20, transform: nil)
        overlayTitle.position = CGPoint(x: 0, y: 150)
        overlaySubtitle.position = CGPoint(x: 0, y: 116)
        overlayMeta.position = CGPoint(x: 0, y: 78)
        overlayFooter.position = CGPoint(x: 0, y: -184)
        for (index, node) in overlayOptionNodes.enumerated() {
            node.position = CGPoint(x: 0, y: 18 - CGFloat(index) * 30)
        }

        renderBackdrop(sceneSize: sceneSize)
        renderBoard(for: level)
        renderObstacles(for: level)
    }

    func render(
        snapshot: GameSnapshot,
        boostStatus: BoostStatusSnapshot,
        mode: SceneMode,
        progress: GameProgressSummary,
        overlayMenu: OverlayMenuState?
    ) {
        renderSnake(
            snapshot.snake,
            isSimpleModeEnabled: snapshot.isSimpleModeEnabled,
            trainCarriages: snapshot.trainCarriages,
            direction: snapshot.currentDirection,
            boostStatus: boostStatus
        )
        renderDynamicObstacles(snapshot.dynamicObstacle)
        renderTemporaryHazards(snapshot.temporaryHazards)
        renderFruit(position: snapshot.fruitPosition, fruit: snapshot.fruit, countdown: snapshot.fruitCountdown)
        updateHUD(snapshot, boostStatus: boostStatus)
        updateOverlay(snapshot: snapshot, mode: mode, progress: progress, overlayMenu: overlayMenu)
    }

    func play(_ event: GameEvent) {
        switch event {
        case .ateFruit(let fruit, let point, let points):
            playFruitEffect(at: point, fruit: fruit, points: points)
        case .comboAdvanced(let count, let bonus):
            showToast(text: "连击 x\(count) 额外 +\(bonus)", color: SKColor(calibratedRed: 1.0, green: 0.74, blue: 0.26, alpha: 1.0))
        case .fruitExpired(let fruit):
            showToast(text: "\(fruit.name) 消失了", color: SKColor(calibratedRed: 0.90, green: 0.78, blue: 0.38, alpha: 1.0))
        case .bombTriggered:
            showToast(text: "爆裂果实引爆周围地块", color: SKColor(calibratedRed: 1.0, green: 0.45, blue: 0.28, alpha: 1.0))
        case .boostActivated:
            showToast(text: "喷射加速！尾巴甩出了一团便便", color: SKColor(calibratedRed: 1.0, green: 0.83, blue: 0.34, alpha: 1.0))
        case .floorCollapsed:
            showToast(text: "地砖开始塌陷", color: SKColor(calibratedRed: 0.74, green: 0.84, blue: 1.0, alpha: 1.0))
        case .safetyBrake:
            showToast(text: "安全刹车发动，快换个方向", color: SKColor(calibratedRed: 1.0, green: 0.90, blue: 0.36, alpha: 1.0))
        case .gameOver:
            shakeBoard()
        case .highScoreUpdated:
            pulseHighScore()
        case .missionCompleted(let mission):
            pulseMission()
            showToast(text: "任务完成: \(mission.title)", color: SKColor(calibratedRed: 0.48, green: 0.90, blue: 0.62, alpha: 1.0))
        case .achievementUnlocked(let achievement):
            showToast(text: "成就解锁: \(achievement.title)", color: SKColor(calibratedRed: 1.0, green: 0.86, blue: 0.30, alpha: 1.0))
        }
    }

    private func renderBoard(for level: LevelDefinition) {
        obstacleLayer.removeAllChildren()
        dynamicObstacleLayer.removeAllChildren()
        temporaryHazardLayer.removeAllChildren()
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

    private func renderObstacles(for level: LevelDefinition) {
        for obstacle in level.obstacles {
            let node = SKShapeNode(
                rectOf: CGSize(width: cellSize * 0.82, height: cellSize * 0.82),
                cornerRadius: cellSize * 0.16
            )
            node.position = point(for: obstacle)
            node.fillColor = currentPalette.obstacle
            node.strokeColor = currentPalette.accent.withAlphaComponent(0.12)
            node.lineWidth = 1
            obstacleLayer.addChild(node)
        }
    }

    private func renderSnake(
        _ snake: [GridPoint],
        isSimpleModeEnabled: Bool,
        trainCarriages: [FruitKind?],
        direction: Direction,
        boostStatus: BoostStatusSnapshot
    ) {
        snakeLayer.removeAllChildren()

        if isSimpleModeEnabled {
            renderTrain(snake: snake, trainCarriages: trainCarriages, direction: direction, boostStatus: boostStatus)
            return
        }

        for (index, segment) in snake.enumerated() {
            let isHead = index == 0
            let node = SKShapeNode(
                rectOf: CGSize(
                    width: cellSize * (isHead ? 0.9 : 0.78),
                    height: cellSize * (isHead ? 0.9 : 0.78)
                ),
                cornerRadius: cellSize * (isHead ? 0.22 : 0.18)
            )
            node.position = point(for: segment)
            node.fillColor = isHead
                ? currentPalette.snakeHead
                : currentPalette.snakeBody
            node.strokeColor = SKColor(calibratedWhite: 0.0, alpha: 0.18)
            node.lineWidth = 1
            snakeLayer.addChild(node)

            if isHead {
                if boostStatus.isReady {
                    addBoostReadyEffect(to: node, size: cellSize * 0.94)
                }
                let eyeOffset = cellSize * 0.16
                let leftEye = SKShapeNode(circleOfRadius: cellSize * 0.05)
                leftEye.fillColor = .black
                leftEye.strokeColor = .clear
                leftEye.position = CGPoint(x: -eyeOffset, y: eyeOffset)
                node.addChild(leftEye)

                let rightEye = SKShapeNode(circleOfRadius: cellSize * 0.05)
                rightEye.fillColor = .black
                rightEye.strokeColor = .clear
                rightEye.position = CGPoint(x: eyeOffset, y: eyeOffset)
                node.addChild(rightEye)
            }
        }
    }

    private func renderTrain(
        snake: [GridPoint],
        trainCarriages: [FruitKind?],
        direction: Direction,
        boostStatus: BoostStatusSnapshot
    ) {
        for (index, segment) in snake.enumerated() {
            if index > 0 {
                let previousSegment = snake[index - 1]
                let coupler = SKShapeNode(path: couplerPath(from: point(for: previousSegment), to: point(for: segment)))
                coupler.strokeColor = SKColor(calibratedWhite: 0.14, alpha: 0.72)
                coupler.lineWidth = cellSize * 0.14
                coupler.lineCap = .round
                snakeLayer.addChild(coupler)
            }

            if index == 0 {
                let engineNode = SKShapeNode(
                    rectOf: CGSize(width: cellSize * 0.94, height: cellSize * 0.78),
                    cornerRadius: cellSize * 0.16
                )
                engineNode.position = point(for: segment)
                engineNode.zRotation = direction.rotationAngle
                engineNode.fillColor = SKColor(calibratedRed: 0.92, green: 0.26, blue: 0.22, alpha: 1.0)
                engineNode.strokeColor = SKColor(calibratedWhite: 0.08, alpha: 0.28)
                engineNode.lineWidth = 1.2
                snakeLayer.addChild(engineNode)

                if boostStatus.isReady {
                    addBoostReadyEffect(to: engineNode, size: cellSize)
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

                addTrainWheels(to: engineNode, xOffsets: [-0.20, 0.18])
                continue
            }

            let carriageKind = index - 1 < trainCarriages.count ? trainCarriages[index - 1] : nil
            let carriageNode = SKShapeNode(
                rectOf: CGSize(width: cellSize * 0.82, height: cellSize * 0.64),
                cornerRadius: cellSize * 0.14
            )
            carriageNode.position = point(for: segment)
            carriageNode.zRotation = carriageRotation(for: snake, at: index)
            carriageNode.fillColor = carriageKind?.color ?? SKColor(calibratedRed: 0.24, green: 0.56, blue: 0.88, alpha: 1.0)
            carriageNode.strokeColor = SKColor(calibratedWhite: 0.08, alpha: 0.22)
            carriageNode.lineWidth = 1.0
            snakeLayer.addChild(carriageNode)

            decorateTrainCarriage(carriageNode, kind: carriageKind)

            let roof = SKShapeNode(
                rectOf: CGSize(width: cellSize * 0.72, height: cellSize * 0.14),
                cornerRadius: cellSize * 0.08
            )
            roof.position = CGPoint(x: 0, y: cellSize * 0.20)
            roof.fillColor = SKColor(calibratedWhite: 1.0, alpha: 0.20)
            roof.strokeColor = .clear
            carriageNode.addChild(roof)

            addTrainWheels(to: carriageNode, xOffsets: [-0.18, 0.18])

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

    private func addBoostReadyEffect(to node: SKNode, size: CGFloat) {
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

    private func addTrainWheels(to node: SKNode, xOffsets: [CGFloat]) {
        for xOffset in xOffsets {
            let wheel = SKShapeNode(circleOfRadius: cellSize * 0.07)
            wheel.fillColor = SKColor(calibratedWhite: 0.14, alpha: 1.0)
            wheel.strokeColor = SKColor(calibratedWhite: 0.75, alpha: 0.32)
            wheel.lineWidth = 1
            wheel.position = CGPoint(x: cellSize * xOffset, y: -cellSize * 0.24)
            node.addChild(wheel)
        }
    }

    private func decorateTrainCarriage(_ carriageNode: SKShapeNode, kind: FruitKind?) {
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

    private func carriageRotation(for snake: [GridPoint], at index: Int) -> CGFloat {
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

    private func couplerPath(from start: CGPoint, to end: CGPoint) -> CGPath {
        let path = CGMutablePath()
        path.move(to: start)
        path.addLine(to: end)
        return path
    }

    private func starPath(radius: CGFloat) -> CGPath {
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

    private func renderDynamicObstacles(_ snapshot: DynamicObstacleSnapshot?) {
        dynamicObstacleLayer.removeAllChildren()

        guard let snapshot else {
            return
        }

        for obstaclePoint in snapshot.points {
            let node = SKShapeNode(
                rectOf: CGSize(width: cellSize * 0.84, height: cellSize * 0.84),
                cornerRadius: cellSize * 0.18
            )
            node.position = point(for: obstaclePoint)

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
            dynamicObstacleLayer.addChild(node)
        }
    }

    private func renderTemporaryHazards(_ hazards: [TemporaryHazardSnapshot]) {
        temporaryHazardLayer.removeAllChildren()

        for hazard in hazards {
            for hazardPoint in hazard.points {
                let node = SKShapeNode(
                    rectOf: CGSize(width: cellSize * 0.72, height: cellSize * 0.72),
                    cornerRadius: cellSize * 0.14
                )
                node.position = point(for: hazardPoint)

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
                    label.text = "💩"
                    label.position = CGPoint(x: 0, y: -cellSize * 0.03)
                    node.addChild(label)
                    node.run(.repeatForever(.sequence([
                        .fadeAlpha(to: 0.56, duration: 0.22),
                        .fadeAlpha(to: 0.92, duration: 0.22)
                    ])))
                }

                temporaryHazardLayer.addChild(node)
            }
        }
    }

    private func renderFruit(position: GridPoint?, fruit: FruitDefinition?, countdown: Int?) {
        fruitLayer.removeAllChildren()

        guard let position, let fruit else {
            return
        }

        let fruitNode = SKShapeNode(circleOfRadius: cellSize * 0.38)
        fruitNode.position = point(for: position)
        fruitNode.fillColor = fruit.color.withAlphaComponent(0.18)
        fruitNode.strokeColor = fruit.effect.ringColor.withAlphaComponent(0.82)
        fruitNode.lineWidth = 1
        fruitLayer.addChild(fruitNode)

        if fruit.effect != .normal {
            let aura = SKShapeNode(circleOfRadius: cellSize * 0.48)
            aura.strokeColor = fruit.effect.ringColor.withAlphaComponent(0.75)
            aura.fillColor = .clear
            aura.lineWidth = 2
            fruitNode.addChild(aura)
            aura.run(auraAction(for: fruit.effect))
        }

        let shadow = SKLabelNode(fontNamed: "AppleColorEmoji")
        shadow.fontSize = cellSize * 0.82
        shadow.verticalAlignmentMode = .center
        shadow.horizontalAlignmentMode = .center
        shadow.alpha = 0.2
        shadow.text = fruit.symbol
        shadow.position = CGPoint(x: 1.5, y: -cellSize * 0.08)
        fruitNode.addChild(shadow)

        let label = SKLabelNode(fontNamed: "AppleColorEmoji")
        label.fontSize = cellSize * 0.82
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.text = fruit.symbol
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

    private func updateHUD(_ snapshot: GameSnapshot, boostStatus: BoostStatusSnapshot) {
        let modeText = snapshot.isSimpleModeEnabled ? " · 极简模式" : ""
        levelLabel.text = "关卡: \(snapshot.level.name)\(modeText)"
        let boostHint: String
        if snapshot.boostMovesRemaining > 0 {
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
        scoreLabel.text = "得分: \(snapshot.score)   最高: \(snapshot.highScore)   长度: \(snapshot.snake.count)\(comboText)"

        if let fruit = snapshot.fruit {
            let timerText = snapshot.fruitCountdown.map { "  ⏳\($0)" } ?? ""
            let effectText = fruit.effect == .normal ? "" : " \(fruit.effect.badge)"
            let stateText = snapshot.activeEffectText.map { "   \($0)" } ?? ""
            fruitLabel.text = "当前水果: \(fruit.symbol) \(fruit.name)\(effectText)  +\(fruit.growth)\(timerText)\(stateText)"
        } else {
            fruitLabel.text = "当前水果: 无"
        }

        missionLabel.text = "任务: \(snapshot.mission.title) · \(snapshot.missionProgress.summaryText)"
        missionLabel.fontColor = snapshot.missionProgress.isCompleted
            ? SKColor(calibratedRed: 0.52, green: 0.90, blue: 0.64, alpha: 1.0)
            : SKColor(calibratedWhite: 0.92, alpha: 0.94)
        statusLabel.text = snapshot.statusText
        statusLabel.alpha = snapshot.isGameOver ? 1.0 : 0.95
        let mechanic = snapshot.mechanicText.map { " · \($0)" } ?? ""
        let collapseHint = snapshot.level.hasCollapsingTiles ? " · 走过的尾迹会短暂塌陷" : ""
        hintLabel.text = snapshot.hintText + " · \(snapshot.mission.detail)" + mechanic + collapseHint
        hintLabel.alpha = snapshot.isGameOver ? 1.0 : 0.8
    }

    private func updateOverlay(
        snapshot: GameSnapshot,
        mode: SceneMode,
        progress: GameProgressSummary,
        overlayMenu: OverlayMenuState?
    ) {
        overlayOptionNodes.forEach { $0.isHidden = true }
        overlayBadgeLayer.removeAllChildren()
        overlayFooter.isHidden = true

        switch mode {
        case .playing:
            overlayLayer.alpha = 0
            overlayLayer.isHidden = true
        case .mainMenu, .achievements, .codex, .help, .settings, .gameOver:
            guard let overlayMenu else {
                overlayLayer.alpha = 0
                overlayLayer.isHidden = true
                return
            }
            overlayLayer.isHidden = false
            overlayLayer.alpha = 1
            overlayTitle.text = overlayMenu.title
            overlaySubtitle.text = overlayMenu.subtitle
            overlayMeta.text = overlayMenu.detail
            overlayFooter.isHidden = false
            overlayFooter.text = overlayMenu.footer
            switch overlayMenu.layout {
            case .list:
                configureListOverlay(items: overlayMenu.items, selectedIndex: overlayMenu.selectedIndex)
            case .achievementGrid:
                renderAchievementBadges(items: overlayMenu.items)
            }
        case .ready:
            overlayLayer.isHidden = false
            overlayLayer.alpha = 1
            overlayTitle.text = "贪吃蛇"
            let modeText = snapshot.isSimpleModeEnabled ? "  ·  极简模式" : ""
            overlaySubtitle.text = "关卡: \(snapshot.level.name)  ·  词条: \(snapshot.modifier.title)\(modeText)"
            let mechanic = snapshot.mechanicText.map { "\n机关: \($0)" } ?? ""
            overlayMeta.text = "任务: \(snapshot.mission.title) - \(snapshot.mission.detail)\n已解锁成就: \(progress.unlockedAchievements)/\(progress.totalAchievements)\n空格开始  ·  P 暂停  ·  方向键 / WASD 移动\(mechanic)"
        case .paused:
            overlayLayer.isHidden = false
            overlayLayer.alpha = 1
            overlayTitle.text = "已暂停"
            overlaySubtitle.text = "当前得分 \(snapshot.score) · 任务 \(snapshot.missionProgress.summaryText)"
            overlayMeta.text = "词条: \(snapshot.modifier.title)\n按 P 或空格继续"
        }
    }

    private func configureListOverlay(items: [OverlayMenuItem], selectedIndex: Int?) {
        for (index, node) in overlayOptionNodes.enumerated() {
            guard index < items.count else {
                node.isHidden = true
                continue
            }

            let item = items[index]
            node.isHidden = false
            let selected = selectedIndex == index
            let icon = item.icon.map { "\($0) " } ?? ""
            let detail = item.subtitle.map { "  ·  \($0)" } ?? ""
            let badge = item.badge.map { "  [\($0)]" } ?? ""
            node.text = selected
                ? "▶ \(icon)\(item.title)\(detail)\(badge)"
                : "\(icon)\(item.title)\(detail)\(badge)"
            node.fontColor = item.isDimmed
                ? SKColor(calibratedWhite: 0.72, alpha: 0.52)
                : (selected ? currentPalette.accent : SKColor(calibratedWhite: 0.92, alpha: 0.90))
            node.setScale(selected ? 1.04 : 1.0)
        }
    }

    private func renderAchievementBadges(items: [OverlayMenuItem]) {
        let panelWidth = max(overlayPanel.frame.width, 280)
        let columns: Int
        if items.count > 8 {
            columns = panelWidth >= 260 ? 3 : 2
        } else {
            columns = panelWidth >= 430 ? 3 : 2
        }
        let horizontalPadding: CGFloat = panelWidth < 340 ? 18 : 24
        let spacingX: CGFloat = columns == 3 ? 10 : (panelWidth < 340 ? 10 : 14)
        let spacingY: CGFloat = columns == 3 ? 8 : (items.count > 8 ? 10 : 12)
        let badgeWidth = min((panelWidth - horizontalPadding * 2 - spacingX * CGFloat(columns - 1)) / CGFloat(columns), 182)
        let badgeHeight: CGFloat = columns == 3 ? 46 : (items.count > 8 ? 56 : 66)
        let startY: CGFloat = columns == 3 ? 28 : 22

        for (index, item) in items.enumerated() {
            let row = index / columns
            let positionInRow = index % columns
            let rowItemCount = min(columns, items.count - row * columns)
            let rowWidth = CGFloat(rowItemCount) * badgeWidth + CGFloat(max(0, rowItemCount - 1)) * spacingX
            let x = -rowWidth / 2 + badgeWidth / 2 + CGFloat(positionInRow) * (badgeWidth + spacingX)
            let y = startY - CGFloat(row) * (badgeHeight + spacingY)

            let card = SKShapeNode(
                rectOf: CGSize(width: badgeWidth, height: badgeHeight),
                cornerRadius: 14
            )
            card.position = CGPoint(x: x, y: y)
            card.fillColor = item.isDimmed
                ? SKColor(calibratedWhite: 0.16, alpha: 0.84)
                : currentPalette.accent.withAlphaComponent(0.16)
            card.strokeColor = item.isDimmed
                ? SKColor(calibratedWhite: 0.80, alpha: 0.12)
                : currentPalette.accent.withAlphaComponent(0.42)
            card.lineWidth = 1.5
            overlayBadgeLayer.addChild(card)

            let iconNode = SKLabelNode(fontNamed: "AvenirNext-Bold")
            iconNode.fontSize = badgeWidth < 130 ? 22 : 24
            iconNode.text = item.icon ?? "★"
            iconNode.position = CGPoint(x: -badgeWidth * 0.33, y: 6)
            iconNode.fontColor = item.isDimmed
                ? SKColor(calibratedWhite: 0.80, alpha: 0.46)
                : currentPalette.accent
            card.addChild(iconNode)

            let titleNode = SKLabelNode(fontNamed: "AvenirNext-Bold")
            titleNode.fontSize = badgeWidth < 130 ? 12 : 14
            titleNode.horizontalAlignmentMode = .left
            titleNode.verticalAlignmentMode = .center
            titleNode.position = CGPoint(x: -badgeWidth * 0.16, y: 12)
            titleNode.text = item.title
            titleNode.fontColor = item.isDimmed
                ? SKColor(calibratedWhite: 0.88, alpha: 0.52)
                : SKColor(calibratedWhite: 0.98, alpha: 0.96)
            card.addChild(titleNode)

            let subtitleNode = SKLabelNode(fontNamed: "AvenirNext-Regular")
            subtitleNode.fontSize = badgeWidth < 130 ? 9 : 10
            subtitleNode.horizontalAlignmentMode = .left
            subtitleNode.verticalAlignmentMode = .center
            subtitleNode.position = CGPoint(x: -badgeWidth * 0.16, y: -2)
            subtitleNode.text = item.subtitle
            subtitleNode.fontColor = SKColor(calibratedWhite: 0.90, alpha: item.isDimmed ? 0.38 : 0.72)
            card.addChild(subtitleNode)

            if let badge = item.badge {
                let badgeNode = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
                badgeNode.fontSize = badgeWidth < 130 ? 8.5 : 9.5
                badgeNode.horizontalAlignmentMode = .left
                badgeNode.verticalAlignmentMode = .center
                badgeNode.position = CGPoint(x: -badgeWidth * 0.16, y: -17)
                badgeNode.text = badge
                badgeNode.fontColor = item.isDimmed
                    ? SKColor(calibratedWhite: 0.76, alpha: 0.42)
                    : SKColor(calibratedRed: 1.0, green: 0.88, blue: 0.42, alpha: 1.0)
                card.addChild(badgeNode)
            }
        }
    }

    private func point(for cell: GridPoint) -> CGPoint {
        CGPoint(
            x: boardFrame.minX + CGFloat(cell.x) * cellSize + cellSize / 2,
            y: boardFrame.minY + CGFloat(cell.y) * cellSize + cellSize / 2
        )
    }

    private func configureLabel(_ label: SKLabelNode, size: CGFloat, alignment: SKLabelHorizontalAlignmentMode) {
        label.fontSize = size
        label.horizontalAlignmentMode = alignment
        label.verticalAlignmentMode = .center
        label.fontColor = SKColor(calibratedWhite: 0.96, alpha: 1.0)
    }

    private func playFruitEffect(at gridPoint: GridPoint, fruit: FruitDefinition, points: Int) {
        let worldPoint = point(for: gridPoint)
        let ring = SKShapeNode(circleOfRadius: cellSize * 0.30)
        ring.position = worldPoint
        ring.strokeColor = fruit.effect.ringColor
        ring.lineWidth = 3
        ring.fillColor = .clear
        boardContainer.addChild(ring)
        ring.run(.sequence([
            .group([
                .scale(to: 2.2, duration: 0.28),
                .fadeOut(withDuration: 0.28)
            ]),
            .removeFromParent()
        ]))

        let scoreNode = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreNode.fontSize = cellSize * 0.34
        scoreNode.fontColor = fruit.effect == .normal
            ? SKColor(calibratedWhite: 0.98, alpha: 1.0)
            : fruit.effect.ringColor
        scoreNode.text = "+\(points)"
        scoreNode.position = CGPoint(x: worldPoint.x, y: worldPoint.y + cellSize * 0.18)
        boardContainer.addChild(scoreNode)
        scoreNode.run(.sequence([
            .group([
                .moveBy(x: 0, y: cellSize * 1.2, duration: 0.55),
                .fadeOut(withDuration: 0.55)
            ]),
            .removeFromParent()
        ]))
    }

    private func shakeBoard() {
        let offsets: [CGFloat] = [10, -8, 6, -4, 2, 0]
        let actions = offsets.map { SKAction.moveBy(x: $0, y: 0, duration: 0.04) }
        [boardContainer, hudLayer].forEach {
            $0.removeAction(forKey: "shake")
            $0.run(.sequence(actions), withKey: "shake")
        }
    }

    private func pulseHighScore() {
        scoreLabel.removeAction(forKey: "pulse")
        scoreLabel.run(.sequence([
            .group([
                .scale(to: 1.12, duration: 0.12),
                .colorize(with: SKColor(calibratedRed: 1.0, green: 0.88, blue: 0.28, alpha: 1.0), colorBlendFactor: 1.0, duration: 0.12)
            ]),
            .group([
                .scale(to: 1.0, duration: 0.20),
                .colorize(withColorBlendFactor: 0.0, duration: 0.20)
            ])
        ]), withKey: "pulse")
    }

    private func pulseMission() {
        missionLabel.removeAction(forKey: "pulse")
        missionLabel.run(.sequence([
            .group([
                .scale(to: 1.08, duration: 0.12),
                .colorize(with: SKColor(calibratedRed: 0.52, green: 0.90, blue: 0.64, alpha: 1.0), colorBlendFactor: 1.0, duration: 0.12)
            ]),
            .group([
                .scale(to: 1.0, duration: 0.20),
                .colorize(withColorBlendFactor: 0.0, duration: 0.20)
            ])
        ]), withKey: "pulse")
    }

    private func showToast(text: String, color: SKColor) {
        let toast = SKLabelNode(fontNamed: "AvenirNext-Bold")
        toast.fontSize = cellSize * 0.34
        toast.fontColor = color
        toast.text = text
        toast.position = CGPoint(x: 0, y: boardFrame.maxY + 82)
        toast.alpha = 0
        hudLayer.addChild(toast)
        toast.run(.sequence([
            .group([
                .fadeIn(withDuration: 0.12),
                .moveBy(x: 0, y: 6, duration: 0.12)
            ]),
            .wait(forDuration: 0.75),
            .group([
                .fadeOut(withDuration: 0.35),
                .moveBy(x: 0, y: 10, duration: 0.35)
            ]),
            .removeFromParent()
        ]))
    }

    private func renderBackdrop(sceneSize: CGSize) {
        backdropLayer.removeAllChildren()

        let largeCircle = SKShapeNode(circleOfRadius: max(sceneSize.width, sceneSize.height) * 0.34)
        largeCircle.fillColor = currentPalette.accent.withAlphaComponent(0.08)
        largeCircle.strokeColor = .clear
        largeCircle.position = CGPoint(x: sceneSize.width * 0.16, y: sceneSize.height * 0.08)
        backdropLayer.addChild(largeCircle)

        let mediumCircle = SKShapeNode(circleOfRadius: max(sceneSize.width, sceneSize.height) * 0.22)
        mediumCircle.fillColor = currentPalette.snakeHead.withAlphaComponent(0.07)
        mediumCircle.strokeColor = .clear
        mediumCircle.position = CGPoint(x: -sceneSize.width * 0.22, y: -sceneSize.height * 0.18)
        backdropLayer.addChild(mediumCircle)

        let ring = SKShapeNode(circleOfRadius: max(sceneSize.width, sceneSize.height) * 0.28)
        ring.strokeColor = currentPalette.accent.withAlphaComponent(0.10)
        ring.fillColor = .clear
        ring.lineWidth = 18
        ring.position = CGPoint(x: -sceneSize.width * 0.30, y: sceneSize.height * 0.20)
        backdropLayer.addChild(ring)
    }

    private func palette(for level: LevelDefinition) -> LevelPalette {
        if level.dynamicMechanic == nil {
            switch level.name {
            case "草地":
                return LevelPalette(
                    background: SKColor(calibratedRed: 0.83, green: 0.93, blue: 0.84, alpha: 1.0),
                    board: SKColor(calibratedRed: 0.94, green: 0.98, blue: 0.91, alpha: 1.0),
                    obstacle: SKColor(calibratedRed: 0.40, green: 0.62, blue: 0.34, alpha: 1.0),
                    snakeHead: SKColor(calibratedRed: 0.95, green: 0.36, blue: 0.28, alpha: 1.0),
                    snakeBody: SKColor(calibratedRed: 0.36, green: 0.72, blue: 0.50, alpha: 1.0),
                    accent: SKColor(calibratedRed: 0.98, green: 0.75, blue: 0.28, alpha: 1.0)
                )
            case "门廊":
                return LevelPalette(
                    background: SKColor(calibratedRed: 0.95, green: 0.89, blue: 0.78, alpha: 1.0),
                    board: SKColor(calibratedRed: 0.98, green: 0.95, blue: 0.87, alpha: 1.0),
                    obstacle: SKColor(calibratedRed: 0.62, green: 0.45, blue: 0.28, alpha: 1.0),
                    snakeHead: SKColor(calibratedRed: 0.88, green: 0.30, blue: 0.22, alpha: 1.0),
                    snakeBody: SKColor(calibratedRed: 0.31, green: 0.62, blue: 0.82, alpha: 1.0),
                    accent: SKColor(calibratedRed: 0.92, green: 0.62, blue: 0.24, alpha: 1.0)
                )
            case "双塔":
                return LevelPalette(
                    background: SKColor(calibratedRed: 0.84, green: 0.89, blue: 0.98, alpha: 1.0),
                    board: SKColor(calibratedRed: 0.90, green: 0.95, blue: 1.0, alpha: 1.0),
                    obstacle: SKColor(calibratedRed: 0.34, green: 0.50, blue: 0.77, alpha: 1.0),
                    snakeHead: SKColor(calibratedRed: 0.98, green: 0.55, blue: 0.32, alpha: 1.0),
                    snakeBody: SKColor(calibratedRed: 0.42, green: 0.78, blue: 0.86, alpha: 1.0),
                    accent: SKColor(calibratedRed: 0.98, green: 0.80, blue: 0.38, alpha: 1.0)
                )
            case "斗兽场":
                return LevelPalette(
                    background: SKColor(calibratedRed: 0.96, green: 0.86, blue: 0.76, alpha: 1.0),
                    board: SKColor(calibratedRed: 0.99, green: 0.93, blue: 0.84, alpha: 1.0),
                    obstacle: SKColor(calibratedRed: 0.68, green: 0.44, blue: 0.25, alpha: 1.0),
                    snakeHead: SKColor(calibratedRed: 0.86, green: 0.28, blue: 0.26, alpha: 1.0),
                    snakeBody: SKColor(calibratedRed: 0.88, green: 0.61, blue: 0.26, alpha: 1.0),
                    accent: SKColor(calibratedRed: 0.70, green: 0.31, blue: 0.24, alpha: 1.0)
                )
            default:
                break
            }
        }

        switch level.dynamicMechanic {
        case .sweeper:
            return LevelPalette(
                background: SKColor(calibratedRed: 0.11, green: 0.08, blue: 0.06, alpha: 1.0),
                board: SKColor(calibratedRed: 0.18, green: 0.13, blue: 0.10, alpha: 1.0),
                obstacle: SKColor(calibratedRed: 0.46, green: 0.35, blue: 0.24, alpha: 1.0),
                snakeHead: SKColor(calibratedRed: 0.64, green: 0.94, blue: 0.48, alpha: 1.0),
                snakeBody: SKColor(calibratedRed: 0.36, green: 0.72, blue: 0.28, alpha: 1.0),
                accent: SKColor(calibratedRed: 1.0, green: 0.78, blue: 0.42, alpha: 1.0)
            )
        case .pulseGate:
            return LevelPalette(
                background: SKColor(calibratedRed: 0.05, green: 0.09, blue: 0.14, alpha: 1.0),
                board: SKColor(calibratedRed: 0.09, green: 0.15, blue: 0.22, alpha: 1.0),
                obstacle: SKColor(calibratedRed: 0.27, green: 0.39, blue: 0.51, alpha: 1.0),
                snakeHead: SKColor(calibratedRed: 0.42, green: 0.94, blue: 0.78, alpha: 1.0),
                snakeBody: SKColor(calibratedRed: 0.20, green: 0.69, blue: 0.56, alpha: 1.0),
                accent: SKColor(calibratedRed: 0.56, green: 0.88, blue: 1.0, alpha: 1.0)
            )
        case .rotor:
            return LevelPalette(
                background: SKColor(calibratedRed: 0.13, green: 0.05, blue: 0.08, alpha: 1.0),
                board: SKColor(calibratedRed: 0.18, green: 0.08, blue: 0.12, alpha: 1.0),
                obstacle: SKColor(calibratedRed: 0.44, green: 0.24, blue: 0.28, alpha: 1.0),
                snakeHead: SKColor(calibratedRed: 0.98, green: 0.77, blue: 0.38, alpha: 1.0),
                snakeBody: SKColor(calibratedRed: 0.82, green: 0.53, blue: 0.23, alpha: 1.0),
                accent: SKColor(calibratedRed: 1.0, green: 0.90, blue: 0.68, alpha: 1.0)
            )
        case .crusher:
            return LevelPalette(
                background: SKColor(calibratedRed: 0.08, green: 0.05, blue: 0.13, alpha: 1.0),
                board: SKColor(calibratedRed: 0.13, green: 0.09, blue: 0.19, alpha: 1.0),
                obstacle: SKColor(calibratedRed: 0.34, green: 0.27, blue: 0.48, alpha: 1.0),
                snakeHead: SKColor(calibratedRed: 0.65, green: 0.93, blue: 0.55, alpha: 1.0),
                snakeBody: SKColor(calibratedRed: 0.40, green: 0.70, blue: 0.36, alpha: 1.0),
                accent: SKColor(calibratedRed: 0.90, green: 0.77, blue: 1.0, alpha: 1.0)
            )
        case nil:
            return LevelPalette(
                background: SKColor(calibratedRed: 0.06, green: 0.08, blue: 0.12, alpha: 1.0),
                board: SKColor(calibratedRed: 0.10, green: 0.14, blue: 0.18, alpha: 1.0),
                obstacle: SKColor(calibratedRed: 0.36, green: 0.42, blue: 0.48, alpha: 1.0),
                snakeHead: SKColor(calibratedRed: 0.36, green: 0.88, blue: 0.53, alpha: 1.0),
                snakeBody: SKColor(calibratedRed: 0.20, green: 0.67, blue: 0.40, alpha: 1.0),
                accent: SKColor(calibratedRed: 0.84, green: 0.93, blue: 1.0, alpha: 1.0)
            )
        }
    }

    private func auraAction(for effect: FruitEffect) -> SKAction {
        switch effect {
        case .golden:
            return .repeatForever(.sequence([
                .group([
                    .scale(to: 1.14, duration: 0.42),
                    .fadeAlpha(to: 0.30, duration: 0.42)
                ]),
                .group([
                    .scale(to: 0.90, duration: 0.42),
                    .fadeAlpha(to: 0.86, duration: 0.42)
                ])
            ]))
        case .frost:
            return .repeatForever(.sequence([
                .group([
                    .scale(to: 1.08, duration: 0.55),
                    .fadeAlpha(to: 0.34, duration: 0.55)
                ]),
                .group([
                    .scale(to: 0.94, duration: 0.55),
                    .fadeAlpha(to: 0.85, duration: 0.55)
                ])
            ]))
        case .ghost:
            return .repeatForever(.sequence([
                .group([
                    .scale(to: 1.18, duration: 0.46),
                    .fadeAlpha(to: 0.18, duration: 0.46),
                    .moveBy(x: 0, y: cellSize * 0.08, duration: 0.46)
                ]),
                .group([
                    .scale(to: 0.88, duration: 0.46),
                    .fadeAlpha(to: 0.88, duration: 0.46),
                    .moveBy(x: 0, y: -cellSize * 0.08, duration: 0.46)
                ])
            ]))
        case .warp:
            return .repeatForever(.sequence([
                .group([
                    .rotate(byAngle: .pi, duration: 0.52),
                    .scale(to: 1.06, duration: 0.52),
                    .fadeAlpha(to: 0.32, duration: 0.52)
                ]),
                .group([
                    .scale(to: 0.92, duration: 0.38),
                    .fadeAlpha(to: 0.90, duration: 0.38)
                ])
            ]))
        case .bomb:
            return .repeatForever(.sequence([
                .group([
                    .scale(to: 1.22, duration: 0.18),
                    .fadeAlpha(to: 0.24, duration: 0.18)
                ]),
                .group([
                    .scale(to: 0.86, duration: 0.18),
                    .fadeAlpha(to: 0.92, duration: 0.18)
                ])
            ]))
        case .normal:
            return .wait(forDuration: 0)
        }
    }
}
