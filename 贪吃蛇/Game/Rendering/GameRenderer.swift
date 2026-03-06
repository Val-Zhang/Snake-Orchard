//
//  GameRenderer.swift
//  贪吃蛇
//
//  Created by zhangwang on 2026/3/6.
//

import SpriteKit

final class GameRenderer {
    private let boardContainer = SKNode()
    private let boardNode = SKShapeNode()
    private let obstacleLayer = SKNode()
    private let dynamicObstacleLayer = SKNode()
    private let snakeLayer = SKNode()
    private let fruitLayer = SKNode()
    private let hudLayer = SKNode()
    private let overlayLayer = SKNode()
    private let overlayPanel = SKShapeNode()
    private let overlayTitle = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let overlaySubtitle = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
    private let overlayMeta = SKLabelNode(fontNamed: "AvenirNext-Regular")

    private let levelLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let scoreLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
    private let fruitLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
    private let statusLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let hintLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")

    private var boardFrame = CGRect.zero
    private var cellSize: CGFloat = 24
    private var attached = false
    private var renderedSceneSize = CGSize.zero
    private var renderedLevel: LevelDefinition?

    func attach(to scene: SKScene) {
        guard !attached else {
            return
        }

        boardNode.strokeColor = SKColor(calibratedWhite: 1.0, alpha: 0.16)
        boardNode.lineWidth = 2
        boardNode.fillColor = SKColor(calibratedRed: 0.10, green: 0.14, blue: 0.18, alpha: 1.0)

        scene.addChild(boardContainer)
        boardContainer.addChild(boardNode)
        boardContainer.addChild(obstacleLayer)
        boardContainer.addChild(dynamicObstacleLayer)
        boardContainer.addChild(fruitLayer)
        boardContainer.addChild(snakeLayer)
        scene.addChild(hudLayer)
        scene.addChild(overlayLayer)

        configureLabel(levelLabel, size: 24, alignment: .left)
        configureLabel(scoreLabel, size: 18, alignment: .left)
        configureLabel(fruitLabel, size: 18, alignment: .right)
        configureLabel(statusLabel, size: 28, alignment: .center)
        configureLabel(hintLabel, size: 16, alignment: .center)

        hudLayer.addChild(levelLabel)
        hudLayer.addChild(scoreLabel)
        hudLayer.addChild(fruitLabel)
        hudLayer.addChild(statusLabel)
        hudLayer.addChild(hintLabel)

        overlayPanel.fillColor = SKColor(calibratedRed: 0.02, green: 0.04, blue: 0.08, alpha: 0.82)
        overlayPanel.strokeColor = SKColor(calibratedWhite: 1.0, alpha: 0.12)
        overlayPanel.lineWidth = 2
        overlayLayer.addChild(overlayPanel)

        configureLabel(overlayTitle, size: 30, alignment: .center)
        configureLabel(overlaySubtitle, size: 18, alignment: .center)
        configureLabel(overlayMeta, size: 15, alignment: .center)
        overlayMeta.fontColor = SKColor(calibratedWhite: 0.92, alpha: 0.78)
        overlayLayer.addChild(overlayTitle)
        overlayLayer.addChild(overlaySubtitle)
        overlayLayer.addChild(overlayMeta)

        attached = true
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

        levelLabel.position = CGPoint(x: boardFrame.minX, y: boardFrame.maxY + 56)
        scoreLabel.position = CGPoint(x: boardFrame.minX, y: boardFrame.maxY + 28)
        fruitLabel.position = CGPoint(x: boardFrame.maxX, y: boardFrame.maxY + 28)
        statusLabel.position = CGPoint(x: 0, y: boardFrame.minY - 48)
        hintLabel.position = CGPoint(x: 0, y: boardFrame.minY - 76)

        let overlayWidth = min(boardFrame.width * 0.82, 420)
        let overlayHeight: CGFloat = 160
        let overlayRect = CGRect(x: -overlayWidth / 2, y: -overlayHeight / 2, width: overlayWidth, height: overlayHeight)
        overlayPanel.path = CGPath(roundedRect: overlayRect, cornerWidth: 20, cornerHeight: 20, transform: nil)
        overlayTitle.position = CGPoint(x: 0, y: 28)
        overlaySubtitle.position = CGPoint(x: 0, y: -4)
        overlayMeta.position = CGPoint(x: 0, y: -40)

        renderBoard(for: level)
        renderObstacles(for: level)
    }

    func render(snapshot: GameSnapshot, mode: SceneMode) {
        renderSnake(snapshot.snake)
        renderDynamicObstacles(snapshot.dynamicObstacle)
        renderFruit(position: snapshot.fruitPosition, fruit: snapshot.fruit)
        updateHUD(snapshot)
        updateOverlay(snapshot: snapshot, mode: mode)
    }

    func play(_ event: GameEvent) {
        switch event {
        case .ateFruit(let fruit, let point, let points):
            playFruitEffect(at: point, fruit: fruit, points: points)
        case .gameOver:
            shakeBoard()
        case .highScoreUpdated:
            pulseHighScore()
        }
    }

    private func renderBoard(for level: LevelDefinition) {
        obstacleLayer.removeAllChildren()
        dynamicObstacleLayer.removeAllChildren()
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
            node.fillColor = SKColor(calibratedRed: 0.36, green: 0.42, blue: 0.48, alpha: 1.0)
            node.strokeColor = SKColor(calibratedWhite: 1.0, alpha: 0.10)
            node.lineWidth = 1
            obstacleLayer.addChild(node)
        }
    }

    private func renderSnake(_ snake: [GridPoint]) {
        snakeLayer.removeAllChildren()

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
                ? SKColor(calibratedRed: 0.36, green: 0.88, blue: 0.53, alpha: 1.0)
                : SKColor(calibratedRed: 0.20, green: 0.67, blue: 0.40, alpha: 1.0)
            node.strokeColor = SKColor(calibratedWhite: 0.0, alpha: 0.18)
            node.lineWidth = 1
            snakeLayer.addChild(node)

            if isHead {
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
            }

            node.lineWidth = 1.6
            dynamicObstacleLayer.addChild(node)
        }
    }

    private func renderFruit(position: GridPoint?, fruit: FruitDefinition?) {
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
            aura.run(.repeatForever(.sequence([
                .group([
                    .scale(to: 1.12, duration: 0.55),
                    .fadeAlpha(to: 0.35, duration: 0.55)
                ]),
                .group([
                    .scale(to: 0.92, duration: 0.55),
                    .fadeAlpha(to: 0.85, duration: 0.55)
                ])
            ])))
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
    }

    private func updateHUD(_ snapshot: GameSnapshot) {
        levelLabel.text = "关卡: \(snapshot.level.name)"
        scoreLabel.text = "得分: \(snapshot.score)   最高: \(snapshot.highScore)   长度: \(snapshot.snake.count)"

        if let fruit = snapshot.fruit {
            let effectText = fruit.effect == .normal ? "" : " \(fruit.effect.badge)"
            let stateText = snapshot.activeEffectText.map { "   \($0)" } ?? ""
            fruitLabel.text = "当前水果: \(fruit.symbol) \(fruit.name)\(effectText)  +\(fruit.growth)\(stateText)"
        } else {
            fruitLabel.text = "当前水果: 无"
        }

        statusLabel.text = snapshot.statusText
        statusLabel.alpha = snapshot.isGameOver ? 1.0 : 0.95
        let mechanic = snapshot.mechanicText.map { " · \($0)" } ?? ""
        hintLabel.text = snapshot.hintText + mechanic
        hintLabel.alpha = snapshot.isGameOver ? 1.0 : 0.8
    }

    private func updateOverlay(snapshot: GameSnapshot, mode: SceneMode) {
        switch mode {
        case .playing:
            overlayLayer.alpha = 0
            overlayLayer.isHidden = true
        case .ready:
            overlayLayer.isHidden = false
            overlayLayer.alpha = 1
            overlayTitle.text = "贪吃蛇"
            overlaySubtitle.text = "随机关卡: \(snapshot.level.name)"
            let mechanic = snapshot.mechanicText.map { "\n\($0)" } ?? ""
            overlayMeta.text = "空格开始  ·  P 暂停  ·  方向键 / WASD 移动\(mechanic)"
        case .paused:
            overlayLayer.isHidden = false
            overlayLayer.alpha = 1
            overlayTitle.text = "已暂停"
            overlaySubtitle.text = "当前得分 \(snapshot.score)，再吃一个冲击新纪录"
            overlayMeta.text = "按 P 或空格继续"
        case .gameOver:
            overlayLayer.isHidden = false
            overlayLayer.alpha = 1
            overlayTitle.text = snapshot.statusText
            overlaySubtitle.text = "本局得分 \(snapshot.score) · 最高 \(snapshot.highScore)"
            overlayMeta.text = "空格重新开始，关卡会重新随机"
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
        scoreNode.fontColor = fruit.effect == .golden
            ? SKColor(calibratedRed: 1.0, green: 0.88, blue: 0.28, alpha: 1.0)
            : SKColor(calibratedWhite: 0.98, alpha: 1.0)
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
}
