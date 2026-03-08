//
//  HistoryModels.swift
//  贪吃蛇
//
//  Created by Codex on 2026/3/8.
//

import Foundation

struct RunHistorySummary {
    let totalRuns: Int
    let bestLength: Int
    let lastScore: Int
    let lastLength: Int
    let lastLevelName: String
    let lastMissionTitle: String
    let lastMissionCompleted: Bool

    static let empty = RunHistorySummary(
        totalRuns: 0,
        bestLength: 0,
        lastScore: 0,
        lastLength: 0,
        lastLevelName: "尚无记录",
        lastMissionTitle: "尚无记录",
        lastMissionCompleted: false
    )
}

struct RunLeaderboardEntry: Codable, Equatable {
    let score: Int
    let length: Int
    let levelName: String
    let missionTitle: String
    let missionCompleted: Bool
    let isDailyChallenge: Bool
    let isSimpleModeEnabled: Bool
    let familyMember: FamilyMember
    let timestamp: TimeInterval

    private enum CodingKeys: String, CodingKey {
        case score
        case length
        case levelName
        case missionTitle
        case missionCompleted
        case isDailyChallenge
        case isSimpleModeEnabled
        case familyMember
        case timestamp
    }

    init(
        score: Int,
        length: Int,
        levelName: String,
        missionTitle: String,
        missionCompleted: Bool,
        isDailyChallenge: Bool,
        isSimpleModeEnabled: Bool,
        familyMember: FamilyMember,
        timestamp: TimeInterval
    ) {
        self.score = score
        self.length = length
        self.levelName = levelName
        self.missionTitle = missionTitle
        self.missionCompleted = missionCompleted
        self.isDailyChallenge = isDailyChallenge
        self.isSimpleModeEnabled = isSimpleModeEnabled
        self.familyMember = familyMember
        self.timestamp = timestamp
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        score = try container.decode(Int.self, forKey: .score)
        length = try container.decode(Int.self, forKey: .length)
        levelName = try container.decode(String.self, forKey: .levelName)
        missionTitle = try container.decode(String.self, forKey: .missionTitle)
        missionCompleted = try container.decode(Bool.self, forKey: .missionCompleted)
        isDailyChallenge = try container.decode(Bool.self, forKey: .isDailyChallenge)
        isSimpleModeEnabled = try container.decode(Bool.self, forKey: .isSimpleModeEnabled)
        familyMember = try container.decodeIfPresent(FamilyMember.self, forKey: .familyMember) ?? .memberOne
        timestamp = try container.decode(TimeInterval.self, forKey: .timestamp)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(score, forKey: .score)
        try container.encode(length, forKey: .length)
        try container.encode(levelName, forKey: .levelName)
        try container.encode(missionTitle, forKey: .missionTitle)
        try container.encode(missionCompleted, forKey: .missionCompleted)
        try container.encode(isDailyChallenge, forKey: .isDailyChallenge)
        try container.encode(isSimpleModeEnabled, forKey: .isSimpleModeEnabled)
        try container.encode(familyMember, forKey: .familyMember)
        try container.encode(timestamp, forKey: .timestamp)
    }
}

struct FamilyLeaderboardEntry {
    let member: FamilyMember
    let bestScore: Int
    let bestLength: Int
    let runCount: Int
    let latestTimestamp: TimeInterval
    let dailyChallengeCount: Int
}

struct RunLeaderboardPlacement {
    let totalRank: Int?
    let dailyRank: Int?
    let personalBestImproved: Bool
    let previousBestScore: Int?
    let previousBestLength: Int?
}
