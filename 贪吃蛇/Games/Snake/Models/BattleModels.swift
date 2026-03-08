//
//  BattleModels.swift
//  贪吃蛇
//
//  Created by Codex on 2026/3/8.
//

import Foundation

struct BattleConfig: Equatable {
    var participants: [FamilyMember]
    var roundCount: Int

    static let defaultConfig = BattleConfig(
        participants: [.memberOne, .memberTwo],
        roundCount: 3
    )

    var isValid: Bool {
        participants.count >= 2
    }

    var totalMatches: Int {
        participants.count * roundCount
    }

    func contains(_ member: FamilyMember) -> Bool {
        participants.contains(member)
    }

    func toggled(member: FamilyMember) -> BattleConfig {
        var next = self
        if let index = next.participants.firstIndex(of: member) {
            next.participants.remove(at: index)
        } else {
            next.participants.append(member)
            next.participants.sort { lhs, rhs in
                (FamilyMember.allCases.firstIndex(of: lhs) ?? 0) < (FamilyMember.allCases.firstIndex(of: rhs) ?? 0)
            }
        }
        if next.participants.isEmpty {
            next.participants = [member]
        }
        return next
    }
}

struct BattleRoundTemplate: Equatable {
    let level: LevelDefinition
    let modifier: RunModifier
    let mission: MissionDefinition
}

struct BattleRoundResult: Equatable {
    let member: FamilyMember
    let round: Int
    let score: Int
    let length: Int
    let levelName: String
    let missionTitle: String
    let missionCompleted: Bool
}

struct BattleStanding: Equatable {
    let member: FamilyMember
    let totalScore: Int
    let bestScore: Int
    let totalLength: Int
    let bestLength: Int
    let roundWins: Int
    let roundsPlayed: Int

    var averageScore: Int {
        guard roundsPlayed > 0 else {
            return 0
        }
        return Int((Double(totalScore) / Double(roundsPlayed)).rounded())
    }
}

struct BattleSummary: Equatable {
    let standings: [BattleStanding]
    let totalRounds: Int
    let totalMatches: Int

    var champion: BattleStanding? {
        standings.first
    }

    init(config: BattleConfig, results: [BattleRoundResult]) {
        let roundWinners = Dictionary(grouping: results, by: \.round).reduce(into: [FamilyMember: Int]()) { partialResult, entry in
            guard let best = entry.value.max(by: {
                if $0.score != $1.score {
                    return $0.score < $1.score
                }
                return $0.length < $1.length
            }) else {
                return
            }
            let winners = entry.value.filter { $0.score == best.score && $0.length == best.length }
            for winner in winners {
                partialResult[winner.member, default: 0] += 1
            }
        }

        standings = config.participants.map { member in
            let memberResults = results.filter { $0.member == member }
            return BattleStanding(
                member: member,
                totalScore: memberResults.reduce(0) { $0 + $1.score },
                bestScore: memberResults.map(\.score).max() ?? 0,
                totalLength: memberResults.reduce(0) { $0 + $1.length },
                bestLength: memberResults.map(\.length).max() ?? 0,
                roundWins: roundWinners[member, default: 0],
                roundsPlayed: memberResults.count
            )
        }
        .sorted { lhs, rhs in
            if lhs.roundWins != rhs.roundWins {
                return lhs.roundWins > rhs.roundWins
            }
            if lhs.totalScore != rhs.totalScore {
                return lhs.totalScore > rhs.totalScore
            }
            if lhs.bestScore != rhs.bestScore {
                return lhs.bestScore > rhs.bestScore
            }
            return lhs.totalLength > rhs.totalLength
        }

        totalRounds = config.roundCount
        totalMatches = config.totalMatches
    }
}

struct BattleSession: Equatable {
    let originalMember: FamilyMember
    var config: BattleConfig
    var currentRound: Int
    var currentParticipantIndex: Int
    var currentTemplate: BattleRoundTemplate
    var results: [BattleRoundResult]

    var currentMember: FamilyMember {
        config.participants[currentParticipantIndex]
    }

    var completedMatches: Int {
        results.count
    }

    var totalMatches: Int {
        config.totalMatches
    }

    var progressTitle: String {
        "家庭对战 · 第 \(currentRound)/\(config.roundCount) 轮"
    }

    var progressDetail: String {
        "第 \(completedMatches + 1)/\(totalMatches) 场 · \(currentMember.title) 出战"
    }

    mutating func advance(nextTemplate: @autoclosure () -> BattleRoundTemplate) -> Bool {
        if currentParticipantIndex + 1 < config.participants.count {
            currentParticipantIndex += 1
            return true
        }
        if currentRound < config.roundCount {
            currentRound += 1
            currentParticipantIndex = 0
            currentTemplate = nextTemplate()
            return true
        }
        return false
    }
}
