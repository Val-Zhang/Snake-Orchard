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

    private struct OverlaySection {
        let title: String
        let icon: String
        let startIndex: Int
    }

    private let backdropLayer = SKNode()
    private let boardContainer = SKNode()
    private let boardNode = SKShapeNode()
    private let obstacleLayer = SKNode()
    private let dynamicObstacleLayer = SKNode()
    private let temporaryHazardLayer = SKNode()
    private let stationLayer = SKNode()
    private let snakeLayer = SKNode()
    private let fruitLayer = SKNode()
    private let hudLayer = SKNode()
    private let overlayLayer = SKNode()
    private let overlayPanel = SKShapeNode()
    private let overlayTitle = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let overlaySubtitle = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
    private let overlayMeta = SKLabelNode(fontNamed: "AvenirNext-Regular")
    private let overlayFooter = SKLabelNode(fontNamed: "AvenirNext-Regular")
    private let overlayOptionNodes = (0 ..< 16).map { _ in SKLabelNode(fontNamed: "AvenirNext-DemiBold") }
    private let overlayTabLayer = SKNode()
    private let overlayBadgeLayer = SKNode()
    private let overlayDecorLayer = SKNode()

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
    private var renderedTheme: VisualTheme?
    private var currentOverlayMenu: OverlayMenuState?
    private var currentOverlayMode: SceneMode = .playing
    private var homeSelectedGame: GameCollectionOption = .snake
    private var homeAccent: FamilyAccent = .orchard
    private var overlayItemHitFrames: [CGRect] = []
    private var overlayTabHitFrames: [CGRect] = []
    private var hoveredOverlayItemIndex: Int?
    private var overlayListStartY: CGFloat = 24
    private var overlayListSpacing: CGFloat = 30
    private var overlayTabsY: CGFloat = 82
    private var overlayMetaY: CGFloat = 56
    private var overlayFooterY: CGFloat = -176
    private var overlayGridStartY: CGFloat = 28
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

        backdropLayer.zPosition = -20
        boardContainer.zPosition = 0
        hudLayer.zPosition = 100
        overlayLayer.zPosition = 200

        scene.addChild(backdropLayer)
        boardNode.strokeColor = SKColor(calibratedWhite: 1.0, alpha: 0.16)
        boardNode.lineWidth = 2
        boardNode.fillColor = currentPalette.board

        scene.addChild(boardContainer)
        boardContainer.addChild(boardNode)
        boardContainer.addChild(obstacleLayer)
        boardContainer.addChild(dynamicObstacleLayer)
        boardContainer.addChild(temporaryHazardLayer)
        boardContainer.addChild(stationLayer)
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
        configureLabel(overlayMeta, size: 15, alignment: .left)
        configureLabel(overlayFooter, size: 14, alignment: .center)
        overlayMeta.fontColor = SKColor(calibratedWhite: 0.92, alpha: 0.78)
        overlayFooter.fontColor = SKColor(calibratedWhite: 0.92, alpha: 0.68)
        overlayLayer.addChild(overlayTitle)
        overlayLayer.addChild(overlaySubtitle)
        overlayLayer.addChild(overlayMeta)
        overlayLayer.addChild(overlayFooter)
        overlayLayer.addChild(overlayDecorLayer)
        overlayLayer.addChild(overlayTabLayer)
        overlayLayer.addChild(overlayBadgeLayer)
        for node in overlayOptionNodes {
            configureLabel(node, size: 18, alignment: .left)
            overlayLayer.addChild(node)
        }

        attached = true
    }

    func backgroundColor(for level: LevelDefinition, theme: VisualTheme) -> SKColor {
        palette(for: level, theme: theme).background
    }

    func updateHomePresentation(selectedGame: GameCollectionOption, accent: FamilyAccent) {
        homeSelectedGame = selectedGame
        homeAccent = accent
    }

    func updateLayout(sceneSize: CGSize, level: LevelDefinition, theme: VisualTheme) {
        guard attached else {
            return
        }

        guard renderedSceneSize != sceneSize || renderedLevel != level || renderedTheme != theme else {
            return
        }

        renderedSceneSize = sceneSize
        renderedLevel = level
        renderedTheme = theme
        currentPalette = palette(for: level, theme: theme)

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
        applyOverlayLayout(mode: currentOverlayMode, overlayMenu: currentOverlayMenu)

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
        currentOverlayMode = mode
        currentOverlayMenu = overlayMenu
        let showsGameplay = mode != .gameSelection && mode != .gameConstruction
        backdropLayer.isHidden = false
        boardContainer.isHidden = !showsGameplay
        hudLayer.isHidden = !showsGameplay
        if showsGameplay {
            renderBackdrop(sceneSize: renderedSceneSize)
        } else {
            renderHomeBackdrop(sceneSize: renderedSceneSize, game: mode == .gameConstruction ? .brickBreaker : homeSelectedGame, accent: homeAccent)
        }
        renderSnake(
            snapshot.snake,
            isSimpleModeEnabled: snapshot.isSimpleModeEnabled,
            trainCarriages: snapshot.trainCarriages,
            direction: snapshot.currentDirection,
            boostStatus: boostStatus,
            isBoosting: snapshot.boostMovesRemaining > 0
        )
        renderDynamicObstacles(snapshot.dynamicObstacle)
        renderTemporaryHazards(snapshot.temporaryHazards)
        renderDeliveryStation(snapshot.deliveryStation)
        renderFruit(position: snapshot.fruitPosition, fruit: snapshot.fruit, countdown: snapshot.fruitCountdown)
        updateHUD(snapshot, boostStatus: boostStatus)
        updateOverlay(snapshot: snapshot, mode: mode, progress: progress, overlayMenu: overlayMenu)
    }

    @discardableResult
    func updateOverlayHover(at scenePoint: CGPoint) -> Bool {
        guard !overlayLayer.isHidden,
              supportsOverlayHover(in: currentOverlayMode)
        else {
            return clearOverlayHover()
        }

        let hoveredIndex = overlayItemHitFrames.firstIndex(where: { $0.contains(scenePoint) })
        guard hoveredIndex != hoveredOverlayItemIndex else {
            return false
        }
        hoveredOverlayItemIndex = hoveredIndex
        return true
    }

    func overlayTabIndex(at scenePoint: CGPoint) -> Int? {
        guard !overlayLayer.isHidden, supportsOverlayHover(in: currentOverlayMode) else {
            return nil
        }
        return overlayTabHitFrames.firstIndex(where: { $0.contains(scenePoint) })
    }

    func overlayItemIndex(at scenePoint: CGPoint) -> Int? {
        guard !overlayLayer.isHidden, supportsOverlayHover(in: currentOverlayMode) else {
            return nil
        }
        return overlayItemHitFrames.firstIndex(where: { $0.contains(scenePoint) })
    }

    func overlayContains(_ scenePoint: CGPoint) -> Bool {
        guard !overlayLayer.isHidden else {
            return false
        }
        return overlayPanel.frame.contains(scenePoint)
    }

    func overlayDetailNavigationStep(at scenePoint: CGPoint) -> Int? {
        guard overlayContains(scenePoint) else {
            return nil
        }

        let rect = overlayPanel.frame
        let innerTop = rect.maxY - 96
        let innerBottom = rect.minY + 54
        guard scenePoint.y <= innerTop, scenePoint.y >= innerBottom else {
            return nil
        }

        let leftThreshold = rect.minX + rect.width * 0.28
        let rightThreshold = rect.maxX - rect.width * 0.28
        if scenePoint.x <= leftThreshold {
            return -1
        }
        if scenePoint.x >= rightThreshold {
            return 1
        }
        return nil
    }

    @discardableResult
    func clearOverlayHover() -> Bool {
        guard hoveredOverlayItemIndex != nil else {
            return false
        }
        hoveredOverlayItemIndex = nil
        return true
    }

    func play(_ event: GameEvent) {
        switch event {
        case .ateFruit(let fruit, let point, let points):
            playFruitEffect(at: point, fruit: fruit, points: points)
        case .comboAdvanced(let count, let bonus):
            showToast(text: "连击 x\(count) 额外 +\(bonus)", color: SKColor(calibratedRed: 1.0, green: 0.74, blue: 0.26, alpha: 1.0))
        case .codexDiscovered(let entry):
            showToast(text: "图鉴新发现: \(entry.symbol) \(entry.title)", color: SKColor(calibratedRed: 0.64, green: 0.90, blue: 1.0, alpha: 1.0))
        case .fruitExpired(let fruit):
            showToast(text: "\(collectibleName(for: fruit.kind)) 消失了", color: SKColor(calibratedRed: 0.90, green: 0.78, blue: 0.38, alpha: 1.0))
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
        case .leaderboardRanked(let placement):
            if let totalRank = placement.totalRank, let dailyRank = placement.dailyRank {
                let suffix = placement.personalBestImproved ? " · 个人新高" : ""
                showToast(text: "冲上总榜 #\(totalRank) · 挑战榜 #\(dailyRank)\(suffix)", color: SKColor(calibratedRed: 1.0, green: 0.86, blue: 0.34, alpha: 1.0))
                if min(totalRank, dailyRank) <= 3 {
                    celebrateLeaderboardRank(min(totalRank, dailyRank))
                }
            } else if let totalRank = placement.totalRank {
                let suffix = placement.personalBestImproved ? " · 个人新高" : ""
                showToast(text: "冲上排行榜 #\(totalRank)\(suffix)", color: SKColor(calibratedRed: 1.0, green: 0.86, blue: 0.34, alpha: 1.0))
                if totalRank <= 3 {
                    celebrateLeaderboardRank(totalRank)
                }
            } else if let dailyRank = placement.dailyRank {
                let suffix = placement.personalBestImproved ? " · 个人新高" : ""
                showToast(text: "冲上挑战榜 #\(dailyRank)\(suffix)", color: SKColor(calibratedRed: 0.48, green: 0.88, blue: 0.96, alpha: 1.0))
                if dailyRank <= 3 {
                    celebrateLeaderboardRank(dailyRank)
                }
            } else if placement.personalBestImproved {
                showToast(text: "刷新当前成员个人最佳", color: SKColor(calibratedRed: 0.72, green: 0.92, blue: 0.48, alpha: 1.0))
            }
        case .missionCompleted(let mission):
            pulseMission()
            showToast(text: "任务完成: \(mission.title)", color: SKColor(calibratedRed: 0.48, green: 0.90, blue: 0.62, alpha: 1.0))
        case .dailyChallengeCompleted(let challenge):
            pulseMission()
            showToast(text: "今日挑战完成: \(challenge.title)", color: SKColor(calibratedRed: 0.42, green: 0.88, blue: 0.96, alpha: 1.0))
        case .achievementUnlocked(let achievement):
            celebrateAchievement(achievement)
            showToast(text: "成就解锁: \(achievement.title)", color: SKColor(calibratedRed: 1.0, green: 0.86, blue: 0.30, alpha: 1.0))
        case .rewardUnlocked(let reward):
            showToast(text: "奖励解锁: \(reward.symbol) \(reward.title)", color: SKColor(calibratedRed: 1.0, green: 0.78, blue: 0.34, alpha: 1.0))
        case .themeUnlocked(let theme):
            celebrateTheme(theme)
            showToast(text: "新皮肤解锁: \(theme.symbol) \(theme.title)", color: SKColor(calibratedRed: 0.96, green: 0.82, blue: 1.0, alpha: 1.0))
        }
    }

    func previewThemeTransition(to theme: VisualTheme) {
        let previewColor = currentPalette.accent
        let previewRect = overlayLayer.isHidden ? boardFrame.insetBy(dx: -10, dy: -10) : overlayPanel.frame

        let flash = SKShapeNode(rect: previewRect, cornerRadius: overlayLayer.isHidden ? 18 : 20)
        flash.fillColor = previewColor.withAlphaComponent(0.10)
        flash.strokeColor = previewColor.withAlphaComponent(0.52)
        flash.lineWidth = 2
        flash.alpha = 0
        flash.zPosition = 20
        overlayLayer.addChild(flash)
        flash.run(.sequence([
            .group([
                .fadeAlpha(to: 1.0, duration: 0.12),
                .scale(to: 1.02, duration: 0.12)
            ]),
            .group([
                .fadeOut(withDuration: 0.28),
                .scale(to: 1.06, duration: 0.28)
            ]),
            .removeFromParent()
        ]))

        let chip = SKLabelNode(fontNamed: "AvenirNext-Bold")
        chip.fontSize = cellSize * 0.28
        chip.fontColor = previewColor
        chip.text = "已切换到 \(theme.symbol) \(theme.title)"
        chip.position = CGPoint(x: 0, y: overlayLayer.isHidden ? boardFrame.maxY + 84 : overlayPanel.frame.maxY - 28)
        chip.alpha = 0
        chip.zPosition = 21
        overlayLayer.addChild(chip)
        chip.run(.sequence([
            .group([
                .fadeIn(withDuration: 0.12),
                .moveBy(x: 0, y: 6, duration: 0.12)
            ]),
            .wait(forDuration: 0.55),
            .group([
                .fadeOut(withDuration: 0.22),
                .moveBy(x: 0, y: 8, duration: 0.22)
            ]),
            .removeFromParent()
        ]))

        showToast(text: "\(theme.symbol) \(theme.title) 音画主题已切换", color: previewColor)
    }

    func announceBattleTurn(memberName: String, memberSymbol: String, modeTitle: String, accentColor: SKColor) {
        let banner = SKLabelNode(fontNamed: "AvenirNext-Bold")
        banner.fontSize = cellSize * 0.40
        banner.fontColor = accentColor
        banner.text = "轮到 \(memberSymbol) \(memberName) 了"
        banner.position = CGPoint(x: 0, y: boardFrame.maxY + 116)
        banner.alpha = 0
        hudLayer.addChild(banner)
        banner.run(.sequence([
            .group([
                .fadeIn(withDuration: 0.12),
                .moveBy(x: 0, y: 6, duration: 0.12)
            ]),
            .wait(forDuration: 0.8),
            .group([
                .fadeOut(withDuration: 0.28),
                .moveBy(x: 0, y: 10, duration: 0.28)
            ]),
            .removeFromParent()
        ]))

        showToast(text: "\(modeTitle) · 准备出发", color: accentColor)
    }

    private func renderBoard(for level: LevelDefinition) {
        GameRendererBoardSupport.renderBoard(
            obstacleLayer: obstacleLayer,
            dynamicObstacleLayer: dynamicObstacleLayer,
            temporaryHazardLayer: temporaryHazardLayer,
            stationLayer: stationLayer,
            snakeLayer: snakeLayer,
            fruitLayer: fruitLayer,
            boardFrame: boardFrame,
            cellSize: cellSize,
            level: level
        )
    }

    private func renderObstacles(for level: LevelDefinition) {
        GameRendererBoardSupport.renderObstacles(
            on: obstacleLayer,
            level: level,
            cellSize: cellSize,
            obstacleColor: currentPalette.obstacle,
            accentColor: currentPalette.accent,
            pointFor: point(for:)
        )
    }

    private func renderSnake(
        _ snake: [GridPoint],
        isSimpleModeEnabled: Bool,
        trainCarriages: [FruitKind?],
        direction: Direction,
        boostStatus: BoostStatusSnapshot,
        isBoosting: Bool
    ) {
        snakeLayer.removeAllChildren()

        if (renderedTheme ?? .orchard).usesVehicleCollectibles {
            renderMotorcade(
                snake: snake,
                isSimpleModeEnabled: isSimpleModeEnabled,
                trainCarriages: trainCarriages,
                direction: direction,
                boostStatus: boostStatus,
                isBoosting: isBoosting
            )
            return
        }

        if isSimpleModeEnabled {
            renderTrain(
                snake: snake,
                trainCarriages: trainCarriages,
                direction: direction,
                boostStatus: boostStatus,
                isBoosting: isBoosting
            )
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
                    GameRendererVehicleSupport.addBoostReadyEffect(to: node, size: cellSize * 0.94)
                }
                if isBoosting {
                    GameRendererVehicleSupport.addBoostTrail(
                        to: node,
                        direction: direction,
                        theme: renderedTheme ?? .orchard,
                        intensity: 0.82,
                        cellSize: cellSize
                    )
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

    private func renderMotorcade(
        snake: [GridPoint],
        isSimpleModeEnabled: Bool,
        trainCarriages: [FruitKind?],
        direction: Direction,
        boostStatus: BoostStatusSnapshot,
        isBoosting: Bool
    ) {
        GameRendererVehicleSupport.renderMotorcade(
            on: snakeLayer,
            snake: snake,
            isSimpleModeEnabled: isSimpleModeEnabled,
            trainCarriages: trainCarriages,
            direction: direction,
            boostStatus: boostStatus,
            isBoosting: isBoosting,
            cellSize: cellSize,
            theme: renderedTheme ?? .motorcade,
            headColor: currentPalette.snakeHead,
            bodyColor: currentPalette.snakeBody,
            pointFor: point(for:)
        )
    }

    private func renderTrain(
        snake: [GridPoint],
        trainCarriages: [FruitKind?],
        direction: Direction,
        boostStatus: BoostStatusSnapshot,
        isBoosting: Bool
    ) {
        GameRendererVehicleSupport.renderTrain(
            on: snakeLayer,
            snake: snake,
            trainCarriages: trainCarriages,
            direction: direction,
            boostStatus: boostStatus,
            isBoosting: isBoosting,
            cellSize: cellSize,
            theme: renderedTheme ?? .orchard,
            headColor: currentPalette.snakeHead,
            bodyColor: currentPalette.snakeBody,
            pointFor: point(for:)
        )
    }

    private func collectibleSymbol(for kind: FruitKind) -> String {
        (renderedTheme ?? .orchard).collectibleSymbol(for: kind)
    }

    private func collectibleName(for kind: FruitKind) -> String {
        (renderedTheme ?? .orchard).collectibleName(for: kind)
    }


    private func renderDynamicObstacles(_ snapshot: DynamicObstacleSnapshot?) {
        GameRendererBoardSupport.renderDynamicObstacles(
            on: dynamicObstacleLayer,
            snapshot: snapshot,
            cellSize: cellSize,
            pointFor: point(for:)
        )
    }

    private func renderTemporaryHazards(_ hazards: [TemporaryHazardSnapshot]) {
        GameRendererBoardSupport.renderTemporaryHazards(
            on: temporaryHazardLayer,
            hazards: hazards,
            theme: renderedTheme ?? .orchard,
            cellSize: cellSize,
            pointFor: point(for:)
        )
    }

    private func renderDeliveryStation(_ station: DeliveryStationSnapshot?) {
        GameRendererBoardSupport.renderDeliveryStation(
            on: stationLayer,
            station: station,
            cellSize: cellSize,
            accentColor: currentPalette.accent,
            pointFor: point(for:)
        )
    }

    private func renderFruit(position: GridPoint?, fruit: FruitDefinition?, countdown: Int?) {
        GameRendererBoardSupport.renderFruit(
            on: fruitLayer,
            position: position,
            fruit: fruit,
            countdown: countdown,
            theme: renderedTheme ?? .orchard,
            cellSize: cellSize,
            pointFor: point(for:),
            auraAction: auraAction(for:)
        )
    }

    private func updateHUD(_ snapshot: GameSnapshot, boostStatus: BoostStatusSnapshot) {
        GameRendererBoardSupport.updateHUD(
            levelLabel: levelLabel,
            modifierLabel: modifierLabel,
            scoreLabel: scoreLabel,
            fruitLabel: fruitLabel,
            missionLabel: missionLabel,
            statusLabel: statusLabel,
            hintLabel: hintLabel,
            snapshot: snapshot,
            boostStatus: boostStatus,
            theme: renderedTheme ?? .orchard
        )
    }

    private func updateOverlay(
        snapshot: GameSnapshot,
        mode: SceneMode,
        progress: GameProgressSummary,
        overlayMenu: OverlayMenuState?
    ) {
        overlayItemHitFrames = []
        overlayTabHitFrames = []
        overlayOptionNodes.forEach { $0.isHidden = true }
        overlayDecorLayer.removeAllChildren()
        overlayTabLayer.removeAllChildren()
        overlayBadgeLayer.removeAllChildren()
        overlayFooter.isHidden = true

        switch mode {
        case .playing:
            overlayLayer.alpha = 0
            overlayLayer.isHidden = true
        case .gameSelection, .gameConstruction, .snakeModeSelection, .mainMenu, .battleSetup, .battleSummary, .familyOverview, .familyDetail, .achievements, .achievementDetail, .leaderboard, .codex, .codexDetail, .help, .settings, .gameOver:
            guard let overlayMenu else {
                overlayLayer.alpha = 0
                overlayLayer.isHidden = true
                return
            }
            applyOverlayLayout(mode: mode, overlayMenu: overlayMenu)
            overlayLayer.isHidden = false
            overlayLayer.alpha = 1
            overlayTitle.text = overlayMenu.title
            overlaySubtitle.text = overlayMenu.subtitle
            overlayMeta.text = overlayDetailText(for: overlayMenu, mode: mode)
            overlayMeta.position = CGPoint(x: overlayPanel.frame.minX + 28, y: overlayMetaY)
            overlayFooter.isHidden = false
            overlayFooter.text = overlayMenu.footer
            renderOverlayDecorations(for: mode)
            if !overlayMenu.tabs.isEmpty {
                renderOverlayTabs(overlayMenu.tabs)
            }
            switch overlayMenu.layout {
            case .list:
                configureListOverlay(items: overlayMenu.items, selectedIndex: overlayMenu.selectedIndex, mode: mode)
            case .achievementGrid:
                renderGridSectionHeader(for: mode)
                renderAchievementBadges(items: overlayMenu.items, selectedIndex: overlayMenu.selectedIndex)
            case .gameSelectionCards:
                renderGameSelectionCards(items: overlayMenu.items, selectedIndex: overlayMenu.selectedIndex)
            }
        case .ready:
            applyOverlayLayout(mode: mode, overlayMenu: nil)
            overlayLayer.isHidden = false
            overlayLayer.alpha = 1
            overlayMeta.position = CGPoint(x: overlayPanel.frame.minX + 28, y: overlayMetaY)
            overlayTitle.text = progress.battleTitle ?? snapshot.dailyChallenge.map { "\($0.symbol) \($0.title)" } ?? "贪吃蛇"
            let modeText: String
            if snapshot.isManualStepModeEnabled {
                modeText = "  ·  极简手动"
            } else if snapshot.isSimpleModeEnabled {
                modeText = "  ·  极简模式"
            } else {
                modeText = ""
            }
            let battleDetail = progress.battleDetail.map { "\n\($0)" } ?? ""
            overlaySubtitle.text = "关卡: \(snapshot.level.name)  ·  词条: \(snapshot.modifier.title)\(modeText)\(battleDetail)"
            let mechanic = snapshot.mechanicText.map { "\n机关: \($0)" } ?? ""
            let dailyReward = snapshot.dailyChallenge.map { "\n\($0.rewardSummary)" } ?? ""
            let controls = snapshot.isManualStepModeEnabled
                ? "空格开始  ·  P 暂停  ·  每按一次方向键 / WASD 前进一步"
                : "空格开始  ·  P 暂停  ·  方向键 / WASD 移动"
            overlayMeta.text = "任务: \(snapshot.mission.title) - \(snapshot.mission.detail)\n已解锁成就: \(progress.unlockedAchievements)/\(progress.totalAchievements) · 奖励内容 \(progress.unlockedRewards)/\(progress.totalRewards)\n\(controls)\(mechanic)\(dailyReward)"
            renderOverlayDecorations(for: mode)
        case .paused:
            applyOverlayLayout(mode: mode, overlayMenu: nil)
            overlayLayer.isHidden = false
            overlayLayer.alpha = 1
            overlayMeta.position = CGPoint(x: overlayPanel.frame.minX + 28, y: overlayMetaY)
            overlayTitle.text = "已暂停"
            overlaySubtitle.text = "当前得分 \(snapshot.score) · 任务 \(snapshot.missionProgress.summaryText)"
            overlayMeta.text = "词条: \(snapshot.modifier.title)\n按 P 或空格继续"
            renderOverlayDecorations(for: mode)
        }
    }

    private func supportsOverlayHover(in mode: SceneMode) -> Bool {
        GameRendererOverlaySupport.supportsHover(in: mode)
    }

    private func overlayDetailText(for overlayMenu: OverlayMenuState, mode: SceneMode) -> String? {
        GameRendererOverlaySupport.detailText(
            for: overlayMenu,
            mode: mode,
            hoveredIndex: hoveredOverlayItemIndex
        )
    }

    private func configureListOverlay(items: [OverlayMenuItem], selectedIndex: Int?, mode: SceneMode) {
        let sections = overlaySections(for: mode)
        let groupedTitles = Dictionary(uniqueKeysWithValues: sections.map { ($0.startIndex, $0) })
        var currentY = overlayListStartY
        let leadingX = overlayPanel.frame.minX + 30
        let denseLayout = items.count >= 10
        let headerSpacing: CGFloat = denseLayout ? 18 : 22
        let itemFontSize: CGFloat = denseLayout ? 16 : 18

        for (index, node) in overlayOptionNodes.enumerated() {
            guard index < items.count else {
                node.isHidden = true
                continue
            }

            if let section = groupedTitles[index] {
                renderListSectionHeader(
                    title: section.title,
                    icon: section.icon,
                    y: currentY,
                    leadingX: leadingX,
                    emphasizeDivider: index > 0
                )
                currentY -= headerSpacing
            }

            let item = items[index]
            node.isHidden = false
            node.fontSize = itemFontSize
            node.position = CGPoint(x: leadingX, y: currentY)
            let selected = (hoveredOverlayItemIndex ?? selectedIndex) == index
            if let accentColor = item.accentColor {
                renderAccentRowDecoration(color: accentColor, y: currentY, isSelected: selected)
            }
            if mode == .leaderboard, index < 3, !item.isDimmed {
                renderLeaderboardRowDecoration(rank: index + 1, y: currentY, isSelected: selected)
            }
            let icon = item.icon.map { "\($0) " } ?? ""
            let detail = item.subtitle.map { "  ·  \($0)" } ?? ""
            let badge = item.badge.map { "  [\($0)]" } ?? ""
            node.text = selected
                ? "▶ \(icon)\(item.title)\(detail)\(badge)"
                : "\(icon)\(item.title)\(detail)\(badge)"
            node.fontColor = colorForOverlayItem(item, mode: mode, index: index, selected: selected)
            node.setScale(mode == .leaderboard && index < 3 ? (selected ? 1.06 : 1.02) : (selected ? 1.04 : 1.0))
            overlayItemHitFrames.append(node.frame.insetBy(dx: -18, dy: -8))
            currentY -= overlayListSpacing
        }
    }

    private func colorForOverlayItem(_ item: OverlayMenuItem, mode: SceneMode, index: Int, selected: Bool) -> SKColor {
        if item.isDimmed {
            return SKColor(calibratedWhite: 0.72, alpha: 0.52)
        }
        if let accentColor = item.accentColor {
            return selected ? accentColor.blended(withFraction: 0.24, of: .white) ?? accentColor : accentColor
        }
        if mode == .leaderboard {
            switch index {
            case 0:
                return selected ? SKColor(calibratedRed: 1.0, green: 0.94, blue: 0.62, alpha: 1.0) : SKColor(calibratedRed: 1.0, green: 0.88, blue: 0.42, alpha: 1.0)
            case 1:
                return selected ? SKColor(calibratedRed: 0.96, green: 0.98, blue: 1.0, alpha: 1.0) : SKColor(calibratedRed: 0.84, green: 0.90, blue: 1.0, alpha: 1.0)
            case 2:
                return selected ? SKColor(calibratedRed: 1.0, green: 0.86, blue: 0.76, alpha: 1.0) : SKColor(calibratedRed: 0.98, green: 0.74, blue: 0.56, alpha: 1.0)
            default:
                break
            }
        }
        return selected ? currentPalette.accent : SKColor(calibratedWhite: 0.92, alpha: 0.90)
    }

    private func renderAchievementBadges(items: [OverlayMenuItem], selectedIndex: Int?) {
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
        let startY = overlayGridStartY

        for (index, item) in items.enumerated() {
            let isSelected = (hoveredOverlayItemIndex ?? selectedIndex) == index
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
                ? SKColor(calibratedWhite: 0.16, alpha: isSelected ? 0.92 : 0.84)
                : currentPalette.accent.withAlphaComponent(isSelected ? 0.28 : 0.16)
            card.strokeColor = item.isDimmed
                ? SKColor(calibratedWhite: 0.80, alpha: isSelected ? 0.26 : 0.12)
                : currentPalette.accent.withAlphaComponent(isSelected ? 0.88 : 0.42)
            card.lineWidth = isSelected ? 2.4 : 1.5
            card.setScale(isSelected ? 1.03 : 1.0)
            overlayBadgeLayer.addChild(card)
            decorateBadgeCard(card, width: badgeWidth, height: badgeHeight, isSelected: isSelected, isDimmed: item.isDimmed)
            overlayItemHitFrames.append(card.frame.insetBy(dx: -6, dy: -6))

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

    private func renderGameSelectionCards(items: [OverlayMenuItem], selectedIndex: Int?) {
        let selected = hoveredOverlayItemIndex ?? selectedIndex ?? 0
        let gameCount = min(GameCollectionOption.allCases.count, items.count)
        let roleItems = Array(items.dropFirst(gameCount))
        let panelWidth = overlayPanel.frame.width
        let roleCardWidth = min((panelWidth - 92) / 4, 102)
        let roleCardHeight: CGFloat = 64
        let roleSpacing: CGFloat = 10
        let listY = overlayMetaY - 46
        let roleY = overlayFooterY + 74

        renderCardSectionHeader(
            title: "游戏",
            icon: "🎮",
            y: listY + 32
        )

        let leadingX = overlayPanel.frame.minX + 30
        let listSpacing: CGFloat = 36
        for index in 0 ..< gameCount {
            let item = items[index]
            let rowY = listY - CGFloat(index) * listSpacing
            let selectedRow = selected == index
            if let accentColor = item.accentColor {
                renderAccentRowDecoration(color: accentColor, y: rowY, isSelected: selectedRow)
            }
            let icon = item.icon.map { "\($0) " } ?? ""
            let subtitle = item.subtitle.map { "  ·  \($0)" } ?? ""
            let badge = item.badge.map { "  [\($0)]" } ?? ""
            let node = overlayOptionNodes[index]
            node.isHidden = false
            node.fontSize = 18
            node.position = CGPoint(x: leadingX, y: rowY)
            node.text = selectedRow
                ? "▶ \(icon)\(item.title)\(subtitle)\(badge)"
                : "\(icon)\(item.title)\(subtitle)\(badge)"
            node.fontColor = colorForOverlayItem(item, mode: .mainMenu, index: index, selected: selectedRow)
            node.setScale(selectedRow ? 1.04 : 1.0)
            overlayItemHitFrames.append(node.frame.insetBy(dx: -18, dy: -8))
        }

        renderCardSectionHeader(
            title: "角色",
            icon: "🧑",
            y: roleY + roleCardHeight / 2 + 24
        )

        let roleCardCount = min(roleItems.count, FamilyMember.allCases.count)
        let totalRoleWidth = CGFloat(roleCardCount) * roleCardWidth + CGFloat(max(0, roleCardCount - 1)) * roleSpacing
        let roleStartX = -totalRoleWidth / 2 + roleCardWidth / 2
        for offset in 0 ..< roleCardCount {
            let item = roleItems[offset]
            let index = gameCount + offset
            let x = roleStartX + CGFloat(offset) * (roleCardWidth + roleSpacing)
            let frame = CGRect(
                x: x - roleCardWidth / 2,
                y: roleY - roleCardHeight / 2,
                width: roleCardWidth,
                height: roleCardHeight
            )
            renderOverlayCard(
                item: item,
                frame: frame,
                isSelected: selected == index,
                compact: true
            )
            overlayItemHitFrames.append(frame.insetBy(dx: -6, dy: -6))
        }

        if roleItems.count > roleCardCount {
            let item = roleItems[roleCardCount]
            let index = gameCount + roleCardCount
            let settingsFrame = CGRect(
                x: overlayPanel.frame.maxX - 54,
                y: overlayPanel.frame.maxY - 62,
                width: 36,
                height: 36
            )
            renderSettingsIconButton(
                item: item,
                frame: settingsFrame,
                isSelected: selected == index
            )
            overlayItemHitFrames.append(settingsFrame.insetBy(dx: -6, dy: -6))
        }
    }

    private func renderSettingsIconButton(
        item: OverlayMenuItem,
        frame: CGRect,
        isSelected: Bool
    ) {
        let accentColor = item.accentColor ?? currentPalette.accent
        let button = SKShapeNode(rectOf: frame.size, cornerRadius: 12)
        button.position = CGPoint(x: frame.midX, y: frame.midY)
        button.fillColor = accentColor.withAlphaComponent(isSelected ? 0.24 : 0.14)
        button.strokeColor = accentColor.withAlphaComponent(isSelected ? 0.88 : 0.42)
        button.lineWidth = isSelected ? 2 : 1.3
        overlayBadgeLayer.addChild(button)

        let iconNode = SKLabelNode(fontNamed: "AppleColorEmoji")
        iconNode.fontSize = 17
        iconNode.text = item.icon ?? "⚙️"
        iconNode.verticalAlignmentMode = .center
        iconNode.horizontalAlignmentMode = .center
        iconNode.position = CGPoint(x: frame.midX, y: frame.midY - 1)
        overlayBadgeLayer.addChild(iconNode)
    }

    private func renderCardSectionHeader(title: String, icon: String, y: CGFloat) {
        let leadingX = overlayPanel.frame.minX + 26
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.fontSize = 11
        label.horizontalAlignmentMode = .left
        label.verticalAlignmentMode = .center
        label.fontColor = currentPalette.accent.withAlphaComponent(0.82)
        label.text = "\(icon) \(title.uppercased())"
        label.position = CGPoint(x: leadingX, y: y)
        overlayDecorLayer.addChild(label)

        let dividerPath = CGMutablePath()
        dividerPath.move(to: CGPoint(x: leadingX + 66, y: y))
        dividerPath.addLine(to: CGPoint(x: overlayPanel.frame.maxX - 24, y: y))
        let divider = SKShapeNode(path: dividerPath)
        divider.strokeColor = currentPalette.accent.withAlphaComponent(0.22)
        divider.lineWidth = 1
        overlayDecorLayer.addChild(divider)
    }

    private func renderOverlayCard(
        item: OverlayMenuItem,
        frame: CGRect,
        isSelected: Bool,
        compact: Bool
    ) {
        let card = SKShapeNode(
            rectOf: frame.size,
            cornerRadius: compact ? 16 : 18
        )
        card.position = CGPoint(x: frame.midX, y: frame.midY)
        let accentColor = item.accentColor ?? currentPalette.accent
        card.fillColor = item.isDimmed
            ? SKColor(calibratedWhite: 0.14, alpha: 0.84)
            : accentColor.withAlphaComponent(isSelected ? 0.26 : 0.14)
        card.strokeColor = item.isDimmed
            ? SKColor(calibratedWhite: 0.82, alpha: 0.14)
            : accentColor.withAlphaComponent(isSelected ? 0.86 : 0.42)
        card.lineWidth = isSelected ? 2.3 : 1.4
        overlayBadgeLayer.addChild(card)

        if let icon = item.icon {
            let iconNode = SKLabelNode(fontNamed: "AppleColorEmoji")
            iconNode.fontSize = compact ? 20 : 30
            iconNode.text = icon
            iconNode.position = CGPoint(x: frame.minX + (compact ? 18 : 26), y: frame.maxY - (compact ? 18 : 30))
            iconNode.horizontalAlignmentMode = .center
            iconNode.verticalAlignmentMode = .center
            overlayBadgeLayer.addChild(iconNode)
        }

        let titleNode = SKLabelNode(fontNamed: "AvenirNext-Bold")
        titleNode.fontSize = compact ? 11 : 18
        titleNode.horizontalAlignmentMode = .left
        titleNode.verticalAlignmentMode = .center
        titleNode.fontColor = item.isDimmed
            ? SKColor(calibratedWhite: 0.88, alpha: 0.46)
            : SKColor(calibratedWhite: 0.98, alpha: 0.96)
        titleNode.text = item.title
        titleNode.position = CGPoint(x: frame.minX + (compact ? 12 : 22), y: frame.midY + (compact ? 2 : 8))
        overlayBadgeLayer.addChild(titleNode)

        if let subtitle = item.subtitle {
            let subtitleNode = SKLabelNode(fontNamed: "AvenirNext-Regular")
            subtitleNode.fontSize = compact ? 9 : 12
            subtitleNode.horizontalAlignmentMode = .left
            subtitleNode.verticalAlignmentMode = .center
            subtitleNode.fontColor = SKColor(calibratedWhite: 0.92, alpha: item.isDimmed ? 0.34 : 0.70)
            subtitleNode.text = subtitle
            subtitleNode.position = CGPoint(x: frame.minX + (compact ? 12 : 22), y: frame.midY - (compact ? 14 : 14))
            overlayBadgeLayer.addChild(subtitleNode)
        }

        if let badge = item.badge {
            let badgeNode = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
            badgeNode.fontSize = compact ? 8.5 : 10.5
            badgeNode.horizontalAlignmentMode = .right
            badgeNode.verticalAlignmentMode = .center
            badgeNode.fontColor = item.isDimmed
                ? SKColor(calibratedWhite: 0.80, alpha: 0.38)
                : accentColor
            badgeNode.text = badge
            badgeNode.position = CGPoint(x: frame.maxX - 14, y: frame.minY + 18)
            overlayBadgeLayer.addChild(badgeNode)
        }
    }

    private func renderHomeBackdrop(sceneSize: CGSize, game: GameCollectionOption, accent: FamilyAccent) {
        guard sceneSize != .zero else {
            return
        }
        backdropLayer.removeAllChildren()

        let accentColor = accent.color
        let wash = SKShapeNode(rectOf: sceneSize)
        let baseColor: SKColor
        switch game {
        case .snake:
            baseColor = SKColor(calibratedRed: 0.09, green: 0.11, blue: 0.10, alpha: 1.0)
        case .brickBreaker:
            baseColor = SKColor(calibratedRed: 0.08, green: 0.09, blue: 0.13, alpha: 1.0)
        }
        wash.fillColor = baseColor
        wash.strokeColor = .clear
        backdropLayer.addChild(wash)

        let glow = SKShapeNode(circleOfRadius: max(sceneSize.width, sceneSize.height) * 0.34)
        glow.fillColor = accentColor.withAlphaComponent(0.14)
        glow.strokeColor = .clear
        glow.position = CGPoint(x: -sceneSize.width * 0.18, y: sceneSize.height * 0.14)
        backdropLayer.addChild(glow)

        let secondaryGlow = SKShapeNode(circleOfRadius: max(sceneSize.width, sceneSize.height) * 0.24)
        secondaryGlow.fillColor = accentColor.withAlphaComponent(0.08)
        secondaryGlow.strokeColor = .clear
        secondaryGlow.position = CGPoint(x: sceneSize.width * 0.22, y: -sceneSize.height * 0.18)
        backdropLayer.addChild(secondaryGlow)

        switch game {
        case .snake:
            renderSnakeHomeBackdrop(sceneSize: sceneSize, accentColor: accentColor)
        case .brickBreaker:
            renderBrickBreakerHomeBackdrop(sceneSize: sceneSize, accentColor: accentColor)
        }
    }

    private func renderSnakeHomeBackdrop(sceneSize: CGSize, accentColor: SKColor) {
        for index in -3 ... 3 {
            let orb = SKShapeNode(circleOfRadius: max(10, cellSize * 0.28))
            orb.fillColor = accentColor.withAlphaComponent(index.isMultiple(of: 2) ? 0.18 : 0.10)
            orb.strokeColor = .clear
            orb.position = CGPoint(
                x: CGFloat(index) * max(54, cellSize * 1.8),
                y: sceneSize.height * 0.12 + CGFloat(abs(index)) * -12
            )
            backdropLayer.addChild(orb)
        }

        let leaf = SKShapeNode(rectOf: CGSize(width: 180, height: 56), cornerRadius: 28)
        leaf.fillColor = accentColor.withAlphaComponent(0.14)
        leaf.strokeColor = accentColor.withAlphaComponent(0.20)
        leaf.zRotation = -.pi / 8
        leaf.position = CGPoint(x: sceneSize.width * 0.20, y: sceneSize.height * 0.22)
        backdropLayer.addChild(leaf)

        let apple = SKLabelNode(fontNamed: "AppleColorEmoji")
        apple.fontSize = max(32, cellSize * 1.4)
        apple.text = "🍎"
        apple.position = CGPoint(x: sceneSize.width * 0.24, y: -sceneSize.height * 0.16)
        backdropLayer.addChild(apple)
    }

    private func renderBrickBreakerHomeBackdrop(sceneSize: CGSize, accentColor: SKColor) {
        let brickSize = CGSize(width: 58, height: 22)
        for row in 0 ..< 4 {
            for column in 0 ..< 5 {
                let brick = SKShapeNode(rectOf: brickSize, cornerRadius: 6)
                brick.fillColor = accentColor.withAlphaComponent(0.10 + CGFloat(row) * 0.03)
                brick.strokeColor = accentColor.withAlphaComponent(0.22)
                let offset = row.isMultiple(of: 2) ? 0 : brickSize.width * 0.55
                brick.position = CGPoint(
                    x: -sceneSize.width * 0.18 + CGFloat(column) * (brickSize.width + 10) + offset,
                    y: sceneSize.height * 0.18 - CGFloat(row) * 32
                )
                backdropLayer.addChild(brick)
            }
        }

        let paddle = SKShapeNode(rectOf: CGSize(width: 140, height: 18), cornerRadius: 9)
        paddle.fillColor = accentColor.withAlphaComponent(0.22)
        paddle.strokeColor = accentColor.withAlphaComponent(0.30)
        paddle.position = CGPoint(x: 0, y: -sceneSize.height * 0.20)
        backdropLayer.addChild(paddle)

        let ball = SKShapeNode(circleOfRadius: 10)
        ball.fillColor = SKColor(calibratedWhite: 1.0, alpha: 0.88)
        ball.strokeColor = .clear
        ball.position = CGPoint(x: sceneSize.width * 0.14, y: -sceneSize.height * 0.06)
        backdropLayer.addChild(ball)
    }

    private func renderOverlayTabs(_ tabs: [OverlayTabItem]) {
        let spacing: CGFloat = 10
        let tabHeight: CGFloat = 28
        let maxWidth = max(overlayPanel.frame.width - 40, 220)
        let baseWidths = tabs.map { max(70, CGFloat($0.title.count) * 12 + (($0.icon == nil) ? 0 : 20)) }
        let totalBaseWidth = baseWidths.reduce(0, +) + CGFloat(max(0, tabs.count - 1)) * spacing
        let scale = min(1, maxWidth / max(totalBaseWidth, 1))
        let widths = baseWidths.map { $0 * scale }
        let totalWidth = widths.reduce(0, +) + CGFloat(max(0, tabs.count - 1)) * spacing
        var cursorX = -totalWidth / 2

        for (index, tab) in tabs.enumerated() {
            let width = widths[index]
            let node = SKShapeNode(rectOf: CGSize(width: width, height: tabHeight), cornerRadius: 14)
            node.position = CGPoint(x: cursorX + width / 2, y: overlayTabsY)
            node.fillColor = tab.isSelected
                ? currentPalette.accent.withAlphaComponent(0.22)
                : SKColor(calibratedWhite: 1.0, alpha: 0.06)
            node.strokeColor = tab.isSelected
                ? currentPalette.accent.withAlphaComponent(0.92)
                : SKColor(calibratedWhite: 1.0, alpha: 0.12)
            node.lineWidth = tab.isSelected ? 1.8 : 1
            overlayTabLayer.addChild(node)

            let label = SKLabelNode(fontNamed: tab.isSelected ? "AvenirNext-Bold" : "AvenirNext-DemiBold")
            label.fontSize = 12
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            label.fontColor = tab.isSelected
                ? SKColor(calibratedWhite: 0.98, alpha: 0.98)
                : SKColor(calibratedWhite: 0.90, alpha: 0.82)
            let icon = tab.icon.map { "\($0) " } ?? ""
            label.text = "\(icon)\(tab.title)"
            label.position = CGPoint(x: 0, y: -1)
            node.addChild(label)
            overlayTabHitFrames.append(node.frame.insetBy(dx: -6, dy: -4))

            cursorX += width + spacing
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

    private func celebrateAchievement(_ achievement: AchievementDefinition) {
        pulseHighScore()

        let center = CGPoint(x: 0, y: boardFrame.maxY + 56)
        let burstColors = [
            currentPalette.accent,
            SKColor(calibratedRed: 1.0, green: 0.85, blue: 0.34, alpha: 1.0),
            SKColor(calibratedRed: 0.62, green: 0.92, blue: 1.0, alpha: 1.0)
        ]

        for index in 0 ..< 9 {
            let angle = CGFloat(index) / 9 * .pi * 2
            let sparkle = SKLabelNode(fontNamed: "AvenirNext-Bold")
            sparkle.fontSize = cellSize * 0.34
            sparkle.fontColor = burstColors[index % burstColors.count]
            sparkle.text = index.isMultiple(of: 2) ? "✦" : achievement.symbol
            sparkle.position = center
            hudLayer.addChild(sparkle)

            let dx = cos(angle) * cellSize * 1.8
            let dy = sin(angle) * cellSize * 1.3
            sparkle.run(.sequence([
                .group([
                    .moveBy(x: dx, y: dy, duration: 0.42),
                    .fadeOut(withDuration: 0.42),
                    .scale(to: 0.72, duration: 0.42)
                ]),
                .removeFromParent()
            ]))
        }

        let banner = SKLabelNode(fontNamed: "AvenirNext-Bold")
        banner.fontSize = cellSize * 0.38
        banner.fontColor = SKColor(calibratedRed: 1.0, green: 0.92, blue: 0.48, alpha: 1.0)
        banner.text = "★ \(achievement.title)"
        banner.position = CGPoint(x: 0, y: boardFrame.maxY + 108)
        banner.alpha = 0
        hudLayer.addChild(banner)
        banner.run(.sequence([
            .group([
                .fadeIn(withDuration: 0.12),
                .moveBy(x: 0, y: 6, duration: 0.12)
            ]),
            .wait(forDuration: 0.6),
            .group([
                .fadeOut(withDuration: 0.25),
                .moveBy(x: 0, y: 8, duration: 0.25)
            ]),
            .removeFromParent()
        ]))
    }

    private func celebrateTheme(_ theme: VisualTheme) {
        let center = CGPoint(x: 0, y: boardFrame.maxY + 94)
        let symbols = [theme.symbol, "✦", "✧", theme.symbol]

        for index in 0 ..< 8 {
            let angle = CGFloat(index) / 8 * .pi * 2
            let sparkle = SKLabelNode(fontNamed: "AvenirNext-Bold")
            sparkle.fontSize = cellSize * 0.34
            sparkle.fontColor = currentPalette.accent
            sparkle.text = symbols[index % symbols.count]
            sparkle.position = center
            hudLayer.addChild(sparkle)

            let dx = cos(angle) * cellSize * 1.4
            let dy = sin(angle) * cellSize * 1.0
            sparkle.run(.sequence([
                .group([
                    .moveBy(x: dx, y: dy, duration: 0.38),
                    .fadeOut(withDuration: 0.38),
                    .scale(to: 0.76, duration: 0.38)
                ]),
                .removeFromParent()
            ]))
        }
    }

    private func celebrateLeaderboardRank(_ rank: Int) {
        let center = CGPoint(x: 0, y: boardFrame.maxY + 96)
        let symbol: String
        let color: SKColor
        switch rank {
        case 1:
            symbol = "🥇"
            color = SKColor(calibratedRed: 1.0, green: 0.88, blue: 0.36, alpha: 1.0)
        case 2:
            symbol = "🥈"
            color = SKColor(calibratedRed: 0.84, green: 0.90, blue: 1.0, alpha: 1.0)
        default:
            symbol = "🥉"
            color = SKColor(calibratedRed: 0.98, green: 0.72, blue: 0.54, alpha: 1.0)
        }

        for index in 0 ..< 10 {
            let angle = CGFloat(index) / 10 * .pi * 2
            let sparkle = SKLabelNode(fontNamed: "AvenirNext-Bold")
            sparkle.fontSize = cellSize * 0.34
            sparkle.fontColor = color
            sparkle.text = index.isMultiple(of: 3) ? symbol : "✦"
            sparkle.position = center
            hudLayer.addChild(sparkle)

            let dx = cos(angle) * cellSize * 1.9
            let dy = sin(angle) * cellSize * 1.2
            sparkle.run(.sequence([
                .group([
                    .moveBy(x: dx, y: dy, duration: 0.45),
                    .fadeOut(withDuration: 0.45),
                    .scale(to: 0.7, duration: 0.45)
                ]),
                .removeFromParent()
            ]))
        }

        let banner = SKLabelNode(fontNamed: "AvenirNext-Bold")
        banner.fontSize = cellSize * 0.40
        banner.fontColor = color
        banner.text = "排行榜第 \(rank) 名"
        banner.position = CGPoint(x: 0, y: boardFrame.maxY + 116)
        banner.alpha = 0
        hudLayer.addChild(banner)
        banner.run(.sequence([
            .group([
                .fadeIn(withDuration: 0.12),
                .moveBy(x: 0, y: 6, duration: 0.12)
            ]),
            .wait(forDuration: 0.7),
            .group([
                .fadeOut(withDuration: 0.25),
                .moveBy(x: 0, y: 8, duration: 0.25)
            ]),
            .removeFromParent()
        ]))
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
        GameRendererBoardSupport.renderBackdrop(
            on: backdropLayer,
            sceneSize: sceneSize,
            accentColor: currentPalette.accent,
            snakeHeadColor: currentPalette.snakeHead
        )
    }

    private func applyOverlayPanelTheme() {
        switch renderedTheme ?? .orchard {
        case .orchard:
            overlayPanel.fillColor = SKColor(calibratedRed: 0.05, green: 0.08, blue: 0.05, alpha: 0.86)
            overlayPanel.strokeColor = currentPalette.accent.withAlphaComponent(0.26)
        case .sunset:
            overlayPanel.fillColor = SKColor(calibratedRed: 0.14, green: 0.09, blue: 0.06, alpha: 0.88)
            overlayPanel.strokeColor = SKColor(calibratedRed: 1.0, green: 0.78, blue: 0.40, alpha: 0.38)
        case .mint:
            overlayPanel.fillColor = SKColor(calibratedRed: 0.05, green: 0.10, blue: 0.09, alpha: 0.86)
            overlayPanel.strokeColor = SKColor(calibratedRed: 0.74, green: 0.98, blue: 0.90, alpha: 0.34)
        case .neon:
            overlayPanel.fillColor = SKColor(calibratedRed: 0.03, green: 0.03, blue: 0.08, alpha: 0.90)
            overlayPanel.strokeColor = SKColor(calibratedRed: 0.68, green: 0.92, blue: 1.0, alpha: 0.44)
            overlayPanel.glowWidth = 6
            return
        case .motorcade:
            overlayPanel.fillColor = SKColor(calibratedRed: 0.06, green: 0.08, blue: 0.10, alpha: 0.88)
            overlayPanel.strokeColor = SKColor(calibratedRed: 0.96, green: 0.84, blue: 0.28, alpha: 0.40)
        case .police:
            overlayPanel.fillColor = SKColor(calibratedRed: 0.05, green: 0.07, blue: 0.11, alpha: 0.90)
            overlayPanel.strokeColor = SKColor(calibratedRed: 0.76, green: 0.86, blue: 1.0, alpha: 0.42)
        case .construction:
            overlayPanel.fillColor = SKColor(calibratedRed: 0.10, green: 0.08, blue: 0.05, alpha: 0.90)
            overlayPanel.strokeColor = SKColor(calibratedRed: 0.98, green: 0.82, blue: 0.24, alpha: 0.40)
        case .racing:
            overlayPanel.fillColor = SKColor(calibratedRed: 0.10, green: 0.05, blue: 0.05, alpha: 0.90)
            overlayPanel.strokeColor = SKColor(calibratedRed: 1.0, green: 0.96, blue: 0.96, alpha: 0.42)
        }
        overlayPanel.glowWidth = 0
    }

    private func applyOverlayLayout(mode: SceneMode, overlayMenu: OverlayMenuState?) {
        let overlayWidth = min(boardFrame.width * 0.90, 520)
        let overlayHeight = overlayHeight(for: mode, overlayMenu: overlayMenu, width: overlayWidth)
        let overlayRect = CGRect(
            x: -overlayWidth / 2,
            y: -overlayHeight / 2,
            width: overlayWidth,
            height: overlayHeight
        )
        overlayPanel.path = CGPath(roundedRect: overlayRect, cornerWidth: 20, cornerHeight: 20, transform: nil)
        applyOverlayPanelTheme()

        overlayTitle.position = CGPoint(x: 0, y: overlayRect.maxY - 48)
        overlaySubtitle.position = CGPoint(x: 0, y: overlayRect.maxY - 84)
        overlayTabsY = overlayRect.maxY - 124
        overlayMetaY = overlayRect.maxY - (overlayMenu?.tabs.isEmpty == false ? 162 : 128)
        overlayFooterY = overlayRect.minY + 26
        overlayGridStartY = overlayMetaY - ((overlayMenu?.tabs.isEmpty == false) ? 70 : 54)
        overlayFooter.position = CGPoint(x: 0, y: overlayFooterY)

        overlayListSpacing = overlayLineSpacing(for: overlayMenu?.items.count ?? 0)
        overlayListStartY = overlayMetaY - 46
        let leadingX = overlayRect.minX + 30
        for node in overlayOptionNodes {
            node.position = CGPoint(x: leadingX, y: overlayListStartY)
        }
    }

    private func overlayHeight(for mode: SceneMode, overlayMenu: OverlayMenuState?, width: CGFloat) -> CGFloat {
        switch mode {
        case .ready:
            return 408
        case .paused:
            return 372
        case .playing:
            return 444
        case .gameSelection, .gameConstruction, .snakeModeSelection, .mainMenu, .battleSetup, .battleSummary, .familyOverview, .familyDetail, .achievements, .achievementDetail, .leaderboard, .codex, .codexDetail, .help, .settings, .gameOver:
            guard let overlayMenu else {
                return 444
            }

            switch overlayMenu.layout {
            case .list:
                let sectionHeaders = overlaySections(for: mode).count
                let lineSpacing = overlayLineSpacing(for: overlayMenu.items.count)
                let tabsHeight: CGFloat = overlayMenu.tabs.isEmpty ? 0 : 40
                let metaHeight: CGFloat = overlayMenu.detail == nil ? 30 : 42
                let denseLayout = overlayMenu.items.count >= 10
                let sectionHeaderHeight: CGFloat = denseLayout ? 18 : 22
                let sectionHeight: CGFloat = sectionHeaders == 0 ? 0 : CGFloat(sectionHeaders) * sectionHeaderHeight
                let contentHeight = 202
                    + tabsHeight
                    + metaHeight
                    + CGFloat(overlayMenu.items.count) * lineSpacing
                    + sectionHeight
                let desiredMax: CGFloat
                switch mode {
                case .settings:
                    desiredMax = 660
                case .gameSelection, .mainMenu, .battleSetup:
                    desiredMax = 620
                case .leaderboard, .familyDetail:
                    desiredMax = 600
                default:
                    desiredMax = 568
                }
                let sceneLimitedMax = max(420, min(renderedSceneSize.height - 48, desiredMax))
                return min(max(contentHeight, 392), sceneLimitedMax)
            case .achievementGrid:
                let panelWidth = max(width, 280)
                let columns: Int
                if overlayMenu.items.count > 8 {
                    columns = panelWidth >= 260 ? 3 : 2
                } else {
                    columns = panelWidth >= 430 ? 3 : 2
                }
                let rows = max(1, Int(ceil(Double(overlayMenu.items.count) / Double(columns))))
                let spacingY: CGFloat = columns == 3 ? 8 : (overlayMenu.items.count > 8 ? 10 : 12)
                let badgeHeight: CGFloat = columns == 3 ? 46 : (overlayMenu.items.count > 8 ? 56 : 66)
                let tabsHeight: CGFloat = overlayMenu.tabs.isEmpty ? 0 : 40
                let contentHeight = 258 + tabsHeight + CGFloat(rows) * badgeHeight + CGFloat(max(0, rows - 1)) * spacingY
                return min(max(contentHeight, 420), 580)
            case .gameSelectionCards:
                let tabsHeight: CGFloat = overlayMenu.tabs.isEmpty ? 0 : 40
                let contentHeight: CGFloat = 466 + tabsHeight
                let desiredMax = max(460, min(renderedSceneSize.height - 40, 580))
                return min(max(contentHeight, 488), desiredMax)
            }
        }
    }

    private func overlayLineSpacing(for itemCount: Int) -> CGFloat {
        GameRendererOverlaySupport.lineSpacing(for: itemCount)
    }

    private func overlaySections(for mode: SceneMode) -> [OverlaySection] {
        GameRendererOverlaySupport.sections(for: mode).map {
            OverlaySection(title: $0.title, icon: $0.icon, startIndex: $0.startIndex)
        }
    }

    private func renderListSectionHeader(title: String, icon: String, y: CGFloat, leadingX: CGFloat, emphasizeDivider: Bool) {
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.fontSize = 11
        label.horizontalAlignmentMode = .left
        label.verticalAlignmentMode = .center
        label.fontColor = currentPalette.accent.withAlphaComponent(0.80)
        label.text = "\(icon) \(title.uppercased())"
        label.position = CGPoint(x: leadingX, y: y)
        overlayDecorLayer.addChild(label)

        let lineStartX = leadingX + 76
        let lineEndX = overlayPanel.frame.maxX - 28
        if lineEndX > lineStartX {
            let path = CGMutablePath()
            path.move(to: CGPoint(x: lineStartX, y: y))
            path.addLine(to: CGPoint(x: lineEndX, y: y))
            let divider = SKShapeNode(path: path)
            divider.strokeColor = currentPalette.accent.withAlphaComponent(emphasizeDivider ? 0.28 : 0.18)
            divider.lineWidth = emphasizeDivider ? 1.2 : 0.9
            overlayDecorLayer.addChild(divider)
        }
    }

    private func renderGridSectionHeader(for mode: SceneMode) {
        let title: String
        let icon: String
        switch mode {
        case .achievements:
            title = "成就总览"
            icon = "★"
        case .codex:
            title = "图鉴条目"
            icon = "📘"
        default:
            return
        }

        let y = overlayGridStartY + 34
        let leadingX = overlayPanel.frame.minX + 26

        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.fontSize = 11
        label.horizontalAlignmentMode = .left
        label.verticalAlignmentMode = .center
        label.fontColor = currentPalette.accent.withAlphaComponent(0.82)
        label.text = "\(icon) \(title)"
        label.position = CGPoint(x: leadingX, y: y)
        overlayDecorLayer.addChild(label)

        let path = CGMutablePath()
        path.move(to: CGPoint(x: leadingX + 72, y: y))
        path.addLine(to: CGPoint(x: overlayPanel.frame.maxX - 28, y: y))
        let divider = SKShapeNode(path: path)
        divider.strokeColor = currentPalette.accent.withAlphaComponent(0.20)
        divider.lineWidth = 1.0
        overlayDecorLayer.addChild(divider)
    }

    private func renderLeaderboardRowDecoration(rank: Int, y: CGFloat, isSelected: Bool) {
        let rect = CGRect(
            x: overlayPanel.frame.minX + 18,
            y: y - 16,
            width: overlayPanel.frame.width - 36,
            height: 28
        )
        let node = SKShapeNode(rect: rect, cornerRadius: 12)
        switch rank {
        case 1:
            node.fillColor = SKColor(calibratedRed: 0.42, green: 0.32, blue: 0.10, alpha: isSelected ? 0.50 : 0.34)
            node.strokeColor = SKColor(calibratedRed: 1.0, green: 0.88, blue: 0.40, alpha: isSelected ? 0.92 : 0.56)
        case 2:
            node.fillColor = SKColor(calibratedRed: 0.24, green: 0.28, blue: 0.34, alpha: isSelected ? 0.48 : 0.32)
            node.strokeColor = SKColor(calibratedRed: 0.82, green: 0.88, blue: 0.98, alpha: isSelected ? 0.88 : 0.50)
        default:
            node.fillColor = SKColor(calibratedRed: 0.36, green: 0.23, blue: 0.16, alpha: isSelected ? 0.48 : 0.32)
            node.strokeColor = SKColor(calibratedRed: 0.98, green: 0.72, blue: 0.54, alpha: isSelected ? 0.88 : 0.50)
        }
        node.lineWidth = isSelected ? 2.2 : 1.4
        overlayDecorLayer.addChild(node)

        let sparkle = SKLabelNode(fontNamed: "AvenirNext-Bold")
        sparkle.fontSize = 12
        sparkle.text = rank == 1 ? "✦" : "✧"
        sparkle.fontColor = node.strokeColor
        sparkle.position = CGPoint(x: rect.maxX - 22, y: y - 1)
        overlayDecorLayer.addChild(sparkle)
    }

    private func renderAccentRowDecoration(color: SKColor, y: CGFloat, isSelected: Bool) {
        let rect = CGRect(
            x: overlayPanel.frame.minX + 18,
            y: y - 15,
            width: overlayPanel.frame.width - 36,
            height: 26
        )
        let node = SKShapeNode(rect: rect, cornerRadius: 12)
        node.fillColor = color.withAlphaComponent(isSelected ? 0.14 : 0.08)
        node.strokeColor = color.withAlphaComponent(isSelected ? 0.88 : 0.42)
        node.lineWidth = isSelected ? 1.8 : 1.2
        overlayDecorLayer.addChild(node)
    }

    private func renderOverlayDecorations(for mode: SceneMode) {
        let rect = overlayPanel.frame
        switch renderedTheme ?? .orchard {
        case .orchard:
            renderOrchardOverlayDecorations(in: rect)
        case .sunset:
            renderSunsetOverlayDecorations(in: rect)
        case .mint:
            renderMintOverlayDecorations(in: rect)
        case .neon:
            renderNeonOverlayDecorations(in: rect, mode: mode)
        case .motorcade:
            renderMotorcadeOverlayDecorations(in: rect)
        case .police:
            renderPoliceOverlayDecorations(in: rect)
        case .construction:
            renderConstructionOverlayDecorations(in: rect)
        case .racing:
            renderRacingOverlayDecorations(in: rect)
        }
    }

    private func renderOrchardOverlayDecorations(in rect: CGRect) {
        for (x, rotation) in [(-rect.width * 0.36, CGFloat.pi / 6), (rect.width * 0.36, -CGFloat.pi / 6)] {
            let leaf = SKShapeNode(
                rectOf: CGSize(width: cellSize * 0.54, height: cellSize * 0.22),
                cornerRadius: cellSize * 0.11
            )
            leaf.position = CGPoint(x: x, y: rect.maxY - 32)
            leaf.zRotation = rotation
            leaf.fillColor = SKColor(calibratedRed: 0.46, green: 0.76, blue: 0.32, alpha: 0.22)
            leaf.strokeColor = currentPalette.accent.withAlphaComponent(0.22)
            overlayDecorLayer.addChild(leaf)
        }
    }

    private func renderSunsetOverlayDecorations(in rect: CGRect) {
        let halo = SKShapeNode(circleOfRadius: cellSize * 0.74)
        halo.position = CGPoint(x: 0, y: rect.maxY - 40)
        halo.fillColor = SKColor(calibratedRed: 1.0, green: 0.72, blue: 0.34, alpha: 0.14)
        halo.strokeColor = SKColor(calibratedRed: 1.0, green: 0.84, blue: 0.52, alpha: 0.24)
        halo.lineWidth = 1.4
        overlayDecorLayer.addChild(halo)

        for offset in stride(from: -2, through: 2, by: 1) {
            let ray = SKShapeNode(
                rectOf: CGSize(width: cellSize * 0.10, height: cellSize * 0.42),
                cornerRadius: cellSize * 0.04
            )
            ray.position = CGPoint(x: CGFloat(offset) * cellSize * 0.26, y: rect.maxY - 12)
            ray.zRotation = CGFloat(offset) * .pi / 12
            ray.fillColor = SKColor(calibratedRed: 1.0, green: 0.84, blue: 0.50, alpha: 0.20)
            ray.strokeColor = .clear
            overlayDecorLayer.addChild(ray)
        }
    }

    private func renderMintOverlayDecorations(in rect: CGRect) {
        for offset in stride(from: -2, through: 2, by: 1) {
            let candy = SKShapeNode(
                rectOf: CGSize(width: cellSize * 0.24, height: cellSize * 0.24),
                cornerRadius: cellSize * 0.08
            )
            candy.position = CGPoint(x: CGFloat(offset) * cellSize * 0.34, y: rect.maxY - 24)
            candy.zRotation = CGFloat(offset) * .pi / 10
            candy.fillColor = (offset % 2 == 0)
                ? SKColor(calibratedRed: 0.92, green: 1.0, blue: 0.96, alpha: 0.20)
                : SKColor(calibratedRed: 0.54, green: 0.92, blue: 0.82, alpha: 0.18)
            candy.strokeColor = currentPalette.accent.withAlphaComponent(0.20)
            overlayDecorLayer.addChild(candy)
        }
    }

    private func renderNeonOverlayDecorations(in rect: CGRect, mode: SceneMode) {
        let corners = [
            CGPoint(x: rect.minX + 22, y: rect.maxY - 22),
            CGPoint(x: rect.maxX - 22, y: rect.maxY - 22),
            CGPoint(x: rect.minX + 22, y: rect.minY + 22),
            CGPoint(x: rect.maxX - 22, y: rect.minY + 22)
        ]

        for (index, corner) in corners.enumerated() {
            let star = SKLabelNode(fontNamed: "AvenirNext-Bold")
            star.fontSize = mode == .gameOver ? cellSize * 0.22 : cellSize * 0.18
            star.fontColor = index.isMultiple(of: 2)
                ? SKColor(calibratedRed: 0.34, green: 0.96, blue: 1.0, alpha: 0.54)
                : SKColor(calibratedRed: 1.0, green: 0.48, blue: 0.92, alpha: 0.48)
            star.text = "✦"
            star.position = CGPoint(x: corner.x, y: corner.y - cellSize * 0.04)
            overlayDecorLayer.addChild(star)
        }
    }

    private func renderMotorcadeOverlayDecorations(in rect: CGRect) {
        for (index, x) in [-rect.width * 0.28, 0, rect.width * 0.28].enumerated() {
            let lane = SKShapeNode(
                rectOf: CGSize(width: cellSize * 0.20, height: cellSize * 0.58),
                cornerRadius: cellSize * 0.06
            )
            lane.position = CGPoint(x: x, y: rect.maxY - 22)
            lane.fillColor = SKColor(calibratedRed: 0.18, green: 0.22, blue: 0.26, alpha: 0.30)
            lane.strokeColor = .clear
            overlayDecorLayer.addChild(lane)

            let dash = SKLabelNode(fontNamed: "AppleColorEmoji")
            dash.fontSize = cellSize * 0.20
            dash.text = index == 1 ? "🚗" : "🚕"
            dash.position = CGPoint(x: x, y: rect.maxY - 30 - CGFloat(index) * cellSize * 0.02)
            overlayDecorLayer.addChild(dash)
        }
    }

    private func renderPoliceOverlayDecorations(in rect: CGRect) {
        let lightBar = SKShapeNode(
            rectOf: CGSize(width: cellSize * 0.82, height: cellSize * 0.14),
            cornerRadius: cellSize * 0.05
        )
        lightBar.position = CGPoint(x: 0, y: rect.maxY - 28)
        lightBar.fillColor = SKColor(calibratedWhite: 0.92, alpha: 0.16)
        lightBar.strokeColor = .clear
        overlayDecorLayer.addChild(lightBar)

        let redHalf = SKShapeNode(
            rectOf: CGSize(width: cellSize * 0.38, height: cellSize * 0.14),
            cornerRadius: cellSize * 0.05
        )
        redHalf.position = CGPoint(x: -cellSize * 0.12, y: rect.maxY - 28)
        redHalf.fillColor = SKColor(calibratedRed: 0.84, green: 0.18, blue: 0.18, alpha: 0.36)
        redHalf.strokeColor = .clear
        overlayDecorLayer.addChild(redHalf)

        let blueHalf = SKShapeNode(
            rectOf: CGSize(width: cellSize * 0.38, height: cellSize * 0.14),
            cornerRadius: cellSize * 0.05
        )
        blueHalf.position = CGPoint(x: cellSize * 0.12, y: rect.maxY - 28)
        blueHalf.fillColor = SKColor(calibratedRed: 0.26, green: 0.54, blue: 1.0, alpha: 0.34)
        blueHalf.strokeColor = .clear
        overlayDecorLayer.addChild(blueHalf)

        redHalf.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.86, duration: 0.18),
            .fadeAlpha(to: 0.18, duration: 0.18)
        ])))
        blueHalf.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.18, duration: 0.18),
            .fadeAlpha(to: 0.84, duration: 0.18)
        ])))
    }

    private func renderConstructionOverlayDecorations(in rect: CGRect) {
        for offset in [-1, 0, 1] {
            let cone = SKLabelNode(fontNamed: "AppleColorEmoji")
            cone.fontSize = cellSize * 0.22
            cone.text = "🚧"
            cone.position = CGPoint(x: CGFloat(offset) * cellSize * 0.36, y: rect.maxY - 26)
            overlayDecorLayer.addChild(cone)
            cone.run(.repeatForever(.sequence([
                .moveBy(x: 0, y: 3, duration: 0.42),
                .moveBy(x: 0, y: -3, duration: 0.42)
            ])))
        }
    }

    private func renderRacingOverlayDecorations(in rect: CGRect) {
        let flags = ["🏁", "🏁", "🏁"]
        for (index, symbol) in flags.enumerated() {
            let flag = SKLabelNode(fontNamed: "AppleColorEmoji")
            flag.fontSize = cellSize * 0.20
            flag.text = symbol
            flag.position = CGPoint(x: CGFloat(index - 1) * cellSize * 0.32, y: rect.maxY - 24)
            overlayDecorLayer.addChild(flag)
            let lift = SKAction.group([
                .moveBy(x: 0, y: 2, duration: 0.20),
                .rotate(byAngle: .pi / 36, duration: 0.20)
            ])
            let settle = SKAction.group([
                .moveBy(x: 0, y: -2, duration: 0.20),
                .rotate(byAngle: -.pi / 36, duration: 0.20)
            ])
            flag.run(.repeatForever(.sequence([lift, settle])))
        }
    }

    private func decorateBadgeCard(_ card: SKShapeNode, width: CGFloat, height: CGFloat, isSelected: Bool, isDimmed: Bool) {
        switch renderedTheme ?? .orchard {
        case .orchard:
            for x in [-width * 0.40, width * 0.40] {
                let leaf = SKShapeNode(
                    rectOf: CGSize(width: cellSize * 0.18, height: cellSize * 0.08),
                    cornerRadius: cellSize * 0.04
                )
                leaf.position = CGPoint(x: x, y: height * 0.32)
                leaf.zRotation = x < 0 ? .pi / 5 : -.pi / 5
                leaf.fillColor = currentPalette.accent.withAlphaComponent(isDimmed ? 0.16 : (isSelected ? 0.42 : 0.28))
                leaf.strokeColor = .clear
                card.addChild(leaf)
            }
        case .sunset:
            let arc = SKShapeNode(circleOfRadius: cellSize * 0.12)
            arc.position = CGPoint(x: width * 0.34, y: height * 0.24)
            arc.fillColor = SKColor(calibratedRed: 1.0, green: 0.78, blue: 0.42, alpha: isDimmed ? 0.14 : 0.26)
            arc.strokeColor = .clear
            card.addChild(arc)
        case .mint:
            let mintDot = SKShapeNode(circleOfRadius: cellSize * 0.06)
            mintDot.position = CGPoint(x: width * 0.34, y: height * 0.24)
            mintDot.fillColor = SKColor(calibratedRed: 0.86, green: 1.0, blue: 0.94, alpha: isDimmed ? 0.18 : 0.32)
            mintDot.strokeColor = .clear
            card.addChild(mintDot)
        case .neon:
            let corner = SKShapeNode(path: neonCornerPath(size: cellSize * 0.18))
            corner.position = CGPoint(x: -width * 0.42, y: height * 0.28)
            corner.strokeColor = isDimmed
                ? SKColor(calibratedRed: 0.60, green: 0.70, blue: 0.84, alpha: 0.18)
                : SKColor(calibratedRed: 0.34, green: 0.96, blue: 1.0, alpha: isSelected ? 0.72 : 0.48)
            corner.lineWidth = 1.4
            corner.glowWidth = isSelected ? 3 : 0
            corner.fillColor = .clear
            card.addChild(corner)
        case .motorcade:
            let plate = SKShapeNode(
                rectOf: CGSize(width: cellSize * 0.24, height: cellSize * 0.12),
                cornerRadius: cellSize * 0.04
            )
            plate.position = CGPoint(x: width * 0.34, y: height * 0.24)
            plate.fillColor = isDimmed
                ? SKColor(calibratedRed: 0.64, green: 0.68, blue: 0.74, alpha: 0.18)
                : SKColor(calibratedRed: 0.96, green: 0.86, blue: 0.36, alpha: isSelected ? 0.42 : 0.28)
            plate.strokeColor = .clear
            card.addChild(plate)
        case .police:
            let light = SKShapeNode(
                rectOf: CGSize(width: cellSize * 0.22, height: cellSize * 0.08),
                cornerRadius: cellSize * 0.03
            )
            light.position = CGPoint(x: width * 0.34, y: height * 0.24)
            light.fillColor = isDimmed
                ? SKColor(calibratedRed: 0.52, green: 0.60, blue: 0.74, alpha: 0.18)
                : SKColor(calibratedRed: 0.30, green: 0.56, blue: 1.0, alpha: isSelected ? 0.40 : 0.28)
            light.strokeColor = .clear
            card.addChild(light)
        case .construction:
            let cone = SKLabelNode(fontNamed: "AppleColorEmoji")
            cone.fontSize = cellSize * 0.18
            cone.text = "🚧"
            cone.position = CGPoint(x: width * 0.34, y: height * 0.20)
            card.addChild(cone)
        case .racing:
            let flag = SKLabelNode(fontNamed: "AppleColorEmoji")
            flag.fontSize = cellSize * 0.18
            flag.text = "🏁"
            flag.position = CGPoint(x: width * 0.34, y: height * 0.20)
            card.addChild(flag)
        }
    }

    private func palette(for level: LevelDefinition, theme: VisualTheme) -> LevelPalette {
        applyTheme(palette(for: level), theme: theme)
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

    private func applyTheme(_ palette: LevelPalette, theme: VisualTheme) -> LevelPalette {
        switch theme {
        case .orchard:
            return palette
        case .sunset:
            return LevelPalette(
                background: mixColor(palette.background, SKColor(calibratedRed: 0.95, green: 0.47, blue: 0.24, alpha: 1.0), amount: 0.24),
                board: mixColor(palette.board, SKColor(calibratedRed: 1.0, green: 0.79, blue: 0.58, alpha: 1.0), amount: 0.18),
                obstacle: mixColor(palette.obstacle, SKColor(calibratedRed: 0.58, green: 0.26, blue: 0.22, alpha: 1.0), amount: 0.28),
                snakeHead: mixColor(palette.snakeHead, SKColor(calibratedRed: 1.0, green: 0.50, blue: 0.34, alpha: 1.0), amount: 0.32),
                snakeBody: mixColor(palette.snakeBody, SKColor(calibratedRed: 0.98, green: 0.68, blue: 0.34, alpha: 1.0), amount: 0.28),
                accent: mixColor(palette.accent, SKColor(calibratedRed: 1.0, green: 0.86, blue: 0.52, alpha: 1.0), amount: 0.34)
            )
        case .mint:
            return LevelPalette(
                background: mixColor(palette.background, SKColor(calibratedRed: 0.72, green: 0.95, blue: 0.88, alpha: 1.0), amount: 0.20),
                board: mixColor(palette.board, SKColor(calibratedRed: 0.87, green: 1.0, blue: 0.95, alpha: 1.0), amount: 0.24),
                obstacle: mixColor(palette.obstacle, SKColor(calibratedRed: 0.34, green: 0.64, blue: 0.58, alpha: 1.0), amount: 0.22),
                snakeHead: mixColor(palette.snakeHead, SKColor(calibratedRed: 0.26, green: 0.86, blue: 0.74, alpha: 1.0), amount: 0.30),
                snakeBody: mixColor(palette.snakeBody, SKColor(calibratedRed: 0.24, green: 0.72, blue: 0.62, alpha: 1.0), amount: 0.24),
                accent: mixColor(palette.accent, SKColor(calibratedRed: 0.78, green: 1.0, blue: 0.92, alpha: 1.0), amount: 0.36)
            )
        case .neon:
            return LevelPalette(
                background: mixColor(palette.background, SKColor(calibratedRed: 0.04, green: 0.03, blue: 0.11, alpha: 1.0), amount: 0.36),
                board: mixColor(palette.board, SKColor(calibratedRed: 0.08, green: 0.06, blue: 0.18, alpha: 1.0), amount: 0.30),
                obstacle: mixColor(palette.obstacle, SKColor(calibratedRed: 0.36, green: 0.18, blue: 0.58, alpha: 1.0), amount: 0.30),
                snakeHead: mixColor(palette.snakeHead, SKColor(calibratedRed: 0.98, green: 0.28, blue: 0.90, alpha: 1.0), amount: 0.34),
                snakeBody: mixColor(palette.snakeBody, SKColor(calibratedRed: 0.18, green: 0.88, blue: 0.98, alpha: 1.0), amount: 0.34),
                accent: mixColor(palette.accent, SKColor(calibratedRed: 0.96, green: 0.90, blue: 1.0, alpha: 1.0), amount: 0.32)
            )
        case .motorcade:
            return LevelPalette(
                background: mixColor(palette.background, SKColor(calibratedRed: 0.12, green: 0.14, blue: 0.18, alpha: 1.0), amount: 0.30),
                board: mixColor(palette.board, SKColor(calibratedRed: 0.18, green: 0.21, blue: 0.26, alpha: 1.0), amount: 0.28),
                obstacle: mixColor(palette.obstacle, SKColor(calibratedRed: 0.42, green: 0.46, blue: 0.54, alpha: 1.0), amount: 0.26),
                snakeHead: mixColor(palette.snakeHead, SKColor(calibratedRed: 0.96, green: 0.78, blue: 0.20, alpha: 1.0), amount: 0.34),
                snakeBody: mixColor(palette.snakeBody, SKColor(calibratedRed: 0.28, green: 0.62, blue: 0.96, alpha: 1.0), amount: 0.34),
                accent: mixColor(palette.accent, SKColor(calibratedRed: 0.94, green: 0.90, blue: 0.68, alpha: 1.0), amount: 0.30)
            )
        case .police:
            return LevelPalette(
                background: mixColor(palette.background, SKColor(calibratedRed: 0.05, green: 0.08, blue: 0.12, alpha: 1.0), amount: 0.34),
                board: mixColor(palette.board, SKColor(calibratedRed: 0.10, green: 0.14, blue: 0.22, alpha: 1.0), amount: 0.30),
                obstacle: mixColor(palette.obstacle, SKColor(calibratedRed: 0.22, green: 0.28, blue: 0.40, alpha: 1.0), amount: 0.28),
                snakeHead: mixColor(palette.snakeHead, SKColor(calibratedRed: 0.96, green: 0.96, blue: 0.98, alpha: 1.0), amount: 0.34),
                snakeBody: mixColor(palette.snakeBody, SKColor(calibratedRed: 0.26, green: 0.48, blue: 0.94, alpha: 1.0), amount: 0.34),
                accent: mixColor(palette.accent, SKColor(calibratedRed: 0.86, green: 0.16, blue: 0.16, alpha: 1.0), amount: 0.30)
            )
        case .construction:
            return LevelPalette(
                background: mixColor(palette.background, SKColor(calibratedRed: 0.16, green: 0.12, blue: 0.06, alpha: 1.0), amount: 0.34),
                board: mixColor(palette.board, SKColor(calibratedRed: 0.24, green: 0.20, blue: 0.10, alpha: 1.0), amount: 0.30),
                obstacle: mixColor(palette.obstacle, SKColor(calibratedRed: 0.48, green: 0.40, blue: 0.18, alpha: 1.0), amount: 0.30),
                snakeHead: mixColor(palette.snakeHead, SKColor(calibratedRed: 0.98, green: 0.82, blue: 0.22, alpha: 1.0), amount: 0.36),
                snakeBody: mixColor(palette.snakeBody, SKColor(calibratedRed: 0.76, green: 0.54, blue: 0.18, alpha: 1.0), amount: 0.34),
                accent: mixColor(palette.accent, SKColor(calibratedRed: 0.98, green: 0.90, blue: 0.56, alpha: 1.0), amount: 0.30)
            )
        case .racing:
            return LevelPalette(
                background: mixColor(palette.background, SKColor(calibratedRed: 0.10, green: 0.04, blue: 0.04, alpha: 1.0), amount: 0.34),
                board: mixColor(palette.board, SKColor(calibratedRed: 0.18, green: 0.08, blue: 0.08, alpha: 1.0), amount: 0.30),
                obstacle: mixColor(palette.obstacle, SKColor(calibratedRed: 0.28, green: 0.10, blue: 0.10, alpha: 1.0), amount: 0.30),
                snakeHead: mixColor(palette.snakeHead, SKColor(calibratedRed: 1.0, green: 0.18, blue: 0.18, alpha: 1.0), amount: 0.36),
                snakeBody: mixColor(palette.snakeBody, SKColor(calibratedRed: 0.96, green: 0.96, blue: 0.98, alpha: 1.0), amount: 0.28),
                accent: mixColor(palette.accent, SKColor(calibratedRed: 1.0, green: 0.98, blue: 0.98, alpha: 1.0), amount: 0.28)
            )
        }
    }

    private func mixColor(_ lhs: SKColor, _ rhs: SKColor, amount: CGFloat) -> SKColor {
        let amount = max(0, min(1, amount))
        guard
            let l = lhs.usingColorSpace(.deviceRGB),
            let r = rhs.usingColorSpace(.deviceRGB)
        else {
            return lhs
        }

        return SKColor(
            calibratedRed: l.redComponent + (r.redComponent - l.redComponent) * amount,
            green: l.greenComponent + (r.greenComponent - l.greenComponent) * amount,
            blue: l.blueComponent + (r.blueComponent - l.blueComponent) * amount,
            alpha: l.alphaComponent + (r.alphaComponent - l.alphaComponent) * amount
        )
    }

    private func neonCornerPath(size: CGFloat) -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: size))
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: size, y: 0))
        return path
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
