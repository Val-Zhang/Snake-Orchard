//
//  GameAudioController.swift
//  贪吃蛇
//
//  Created by zhangwang on 2026/3/6.
//

import AVFoundation

enum SceneAudioMode {
    case menu
    case gameplay
    case silent
}

final class GameAudioController {
    private enum AudioAsset: String {
        case eat = "eat"
        case special = "special"
        case pause = "pause"
        case gameOver = "game_over"
        case navigate = "navigate"
        case confirm = "confirm"
        case menuLoop = "menu_loop"
        case gameplayLoop = "gameplay_loop"
    }

    private let resourceSubdirectory = "Audio"
    private var settings = GameSettings.default
    private var currentMode: SceneAudioMode = .silent
    private var effectPlayers: [AVAudioPlayer] = []
    private lazy var menuMusicPlayer = makePlayer(asset: .menuLoop, loops: -1, volume: 0.42)
    private lazy var gameplayMusicPlayer = makePlayer(asset: .gameplayLoop, loops: -1, volume: 0.34)

    func apply(settings: GameSettings) {
        self.settings = settings
        if !settings.musicEnabled {
            stopMusic()
        } else {
            syncMusic(mode: currentMode)
        }
    }

    func updateMusic(for mode: SceneAudioMode) {
        currentMode = mode
        syncMusic(mode: mode)
    }

    func playFruit(effect: FruitEffect) {
        switch effect {
        case .normal:
            playEffect(asset: .eat, volume: 0.86)
        case .golden, .frost, .ghost, .warp, .bomb:
            playEffect(asset: .special, volume: 0.92)
        }
    }

    func playPause() {
        playEffect(asset: .pause, volume: 0.90)
    }

    func playGameOver() {
        playEffect(asset: .gameOver, volume: 0.96)
    }

    func playNavigate() {
        playEffect(asset: .navigate, volume: 0.70)
    }

    func playConfirm() {
        playEffect(asset: .confirm, volume: 0.82)
    }

    func stopAll() {
        stopMusic()
        effectPlayers.forEach { player in
            player.stop()
            player.currentTime = 0
        }
        effectPlayers.removeAll()
        currentMode = .silent
    }

    private func playEffect(asset: AudioAsset, volume: Float) {
        guard settings.soundEnabled else {
            return
        }

        pruneEffectPlayers()
        guard let player = makePlayer(asset: asset, loops: 0, volume: volume) else {
            return
        }

        effectPlayers.append(player)
        player.play()
    }

    private func syncMusic(mode: SceneAudioMode) {
        stopMusic()
        guard settings.musicEnabled else {
            return
        }

        switch mode {
        case .menu:
            menuMusicPlayer?.currentTime = 0
            menuMusicPlayer?.play()
        case .gameplay:
            gameplayMusicPlayer?.currentTime = 0
            gameplayMusicPlayer?.play()
        case .silent:
            break
        }
    }

    private func stopMusic() {
        menuMusicPlayer?.stop()
        gameplayMusicPlayer?.stop()
    }

    private func makePlayer(asset: AudioAsset, loops: Int, volume: Float) -> AVAudioPlayer? {
        guard let url = resourceURL(for: asset) else {
            return nil
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = loops
            player.volume = volume
            player.prepareToPlay()
            return player
        } catch {
            return nil
        }
    }

    private func pruneEffectPlayers() {
        effectPlayers.removeAll { !$0.isPlaying }
    }

    private func resourceURL(for asset: AudioAsset) -> URL? {
        Bundle.main.url(forResource: asset.rawValue, withExtension: "wav", subdirectory: resourceSubdirectory)
            ?? Bundle.main.url(forResource: asset.rawValue, withExtension: "wav")
    }
}
