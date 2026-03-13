//
//  LevelFactory.swift
//  贪吃蛇
//
//  Created by zhangwang on 2026/3/6.
//

import Foundation

struct LevelFactory {
    func randomLevel(isSimpleModeEnabled: Bool = false) -> LevelDefinition {
        let availableLevels = allLevels(isSimpleModeEnabled: isSimpleModeEnabled)
        return availableLevels.randomElement() ?? allLevels(isSimpleModeEnabled: true).first!
    }

    func allLevels(isSimpleModeEnabled: Bool = false) -> [LevelDefinition] {
        let columns = 20
        let rows = 14

        let empty = LevelDefinition(
            name: "草地",
            columns: columns,
            rows: rows,
            tickDuration: 0.18,
            obstacles: [],
            dynamicMechanic: nil,
            hasCollapsingTiles: false
        )

        let gateway = LevelDefinition(
            name: "门廊",
            columns: columns,
            rows: rows,
            tickDuration: 0.17,
            obstacles: Set([
                line(fromX: 6, toX: 13, y: 4),
                line(fromX: 6, toX: 13, y: 9)
            ].flatMap { $0 }.filter { $0.x != 9 && $0.x != 10 }),
            dynamicMechanic: nil,
            hasCollapsingTiles: false
        )

        let towers = LevelDefinition(
            name: "双塔",
            columns: columns,
            rows: rows,
            tickDuration: 0.16,
            obstacles: Set([
                line(fromY: 2, toY: 11, x: 5),
                line(fromY: 2, toY: 11, x: 14)
            ].flatMap { $0 }.filter { $0.y != 6 && $0.y != 7 }),
            dynamicMechanic: nil,
            hasCollapsingTiles: false
        )

        let arena = LevelDefinition(
            name: "斗兽场",
            columns: columns,
            rows: rows,
            tickDuration: 0.15,
            obstacles: Set(
                rectangleBorder(x: 6, y: 3, width: 8, height: 8)
                    .filter { !($0.x == 9 || $0.x == 10) || !($0.y == 3 || $0.y == 10) }
            ),
            dynamicMechanic: nil,
            hasCollapsingTiles: false
        )

        let zigzag = LevelDefinition(
            name: "折返跑",
            columns: columns,
            rows: rows,
            tickDuration: 0.14,
            obstacles: Set(
                line(fromX: 2, toX: 9, y: 3) +
                line(fromX: 10, toX: 17, y: 6) +
                line(fromX: 2, toX: 9, y: 9)
            ),
            dynamicMechanic: nil,
            hasCollapsingTiles: false
        )

        let sweeper = LevelDefinition(
            name: "回旋走廊",
            columns: columns,
            rows: rows,
            tickDuration: 0.16,
            obstacles: Set(
                line(fromY: 1, toY: 12, x: 2) +
                line(fromY: 1, toY: 12, x: 17) +
                line(fromX: 3, toX: 7, y: 3) +
                line(fromX: 12, toX: 16, y: 10)
            ),
            dynamicMechanic: .sweeper(
                SweeperDefinition(row: 6, minX: 4, maxX: 15, length: 4)
            ),
            hasCollapsingTiles: false
        )

        let pulseGate = LevelDefinition(
            name: "水闸",
            columns: columns,
            rows: rows,
            tickDuration: 0.16,
            obstacles: Set(
                line(fromY: 1, toY: 12, x: 6) +
                line(fromY: 1, toY: 12, x: 13)
            ).subtracting([
                GridPoint(x: 6, y: 6),
                GridPoint(x: 6, y: 7),
                GridPoint(x: 13, y: 6),
                GridPoint(x: 13, y: 7)
            ]),
            dynamicMechanic: .pulseGate(
                PulseGateDefinition(
                    closedPoints: [
                        GridPoint(x: 9, y: 6),
                        GridPoint(x: 10, y: 6),
                        GridPoint(x: 9, y: 7),
                        GridPoint(x: 10, y: 7)
                    ],
                    closedDuration: 4,
                    openDuration: 3
                )
            ),
            hasCollapsingTiles: false
        )

        let rotor = LevelDefinition(
            name: "风车庭院",
            columns: columns,
            rows: rows,
            tickDuration: 0.15,
            obstacles: Set(
                rectangleBorder(x: 2, y: 2, width: 16, height: 10)
                    .filter { !($0.x == 9 || $0.x == 10) || !($0.y == 2 || $0.y == 11) }
            ),
            dynamicMechanic: .rotor(
                RotorDefinition(center: GridPoint(x: 10, y: 6), armLength: 3, holdTicks: 2)
            ),
            hasCollapsingTiles: false
        )

        let crusher = LevelDefinition(
            name: "石壁夹道",
            columns: columns,
            rows: rows,
            tickDuration: 0.15,
            obstacles: Set(
                line(fromY: 1, toY: 12, x: 3) +
                line(fromY: 1, toY: 12, x: 16) +
                line(fromX: 4, toX: 15, y: 1).filter { $0.x != 9 && $0.x != 10 } +
                line(fromX: 4, toX: 15, y: 12).filter { $0.x != 9 && $0.x != 10 }
            ),
            dynamicMechanic: .crusher(
                CrusherDefinition(minY: 3, maxY: 10, fromX: 6, toX: 13)
            ),
            hasCollapsingTiles: false
        )

        let footbridge = LevelDefinition(
            name: "浮桥",
            columns: columns,
            rows: rows,
            tickDuration: 0.16,
            obstacles: Set(
                line(fromX: 1, toX: 18, y: 2) +
                line(fromX: 1, toX: 18, y: 11) +
                line(fromY: 3, toY: 10, x: 1) +
                line(fromY: 3, toY: 10, x: 18) +
                line(fromX: 4, toX: 15, y: 6)
            ).subtracting([
                GridPoint(x: 9, y: 6),
                GridPoint(x: 10, y: 6)
            ]),
            dynamicMechanic: nil,
            hasCollapsingTiles: true
        )

        let standardPool = [empty, gateway, towers, arena, zigzag, sweeper, pulseGate, rotor, crusher, footbridge]
        let simplePool = [empty, gateway, towers, arena]
        return isSimpleModeEnabled ? simplePool : standardPool
    }

    private func line(fromX start: Int, toX end: Int, y: Int) -> [GridPoint] {
        (min(start, end) ... max(start, end)).map { GridPoint(x: $0, y: y) }
    }

    private func line(fromY start: Int, toY end: Int, x: Int) -> [GridPoint] {
        (min(start, end) ... max(start, end)).map { GridPoint(x: x, y: $0) }
    }

    private func rectangleBorder(x: Int, y: Int, width: Int, height: Int) -> [GridPoint] {
        let top = line(fromX: x, toX: x + width - 1, y: y + height - 1)
        let bottom = line(fromX: x, toX: x + width - 1, y: y)
        let left = line(fromY: y + 1, toY: y + height - 2, x: x)
        let right = line(fromY: y + 1, toY: y + height - 2, x: x + width - 1)
        return top + bottom + left + right
    }
}
