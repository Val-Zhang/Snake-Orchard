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
    private struct AudioStyle {
        let effectRate: Float
        let specialRate: Float
        let confirmRate: Float
        let navigateRate: Float
        let pauseRate: Float
        let gameOverRate: Float
        let menuLoopRate: Float
        let gameplayLoopRate: Float
        let effectVolumeScale: Float
        let musicVolumeScale: Float
    }

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
    private var menuMusicPlayer: AVAudioPlayer?
    private var gameplayMusicPlayer: AVAudioPlayer?

    func apply(settings: GameSettings) {
        self.settings = settings
        rebuildMusicPlayers()
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
        let style = audioStyle(for: settings.visualTheme)
        switch effect {
        case .normal:
            playEffect(asset: .eat, volume: 0.86 * style.effectVolumeScale, rate: style.effectRate)
        case .golden, .frost, .ghost, .warp, .bomb:
            playEffect(asset: .special, volume: 0.92 * style.effectVolumeScale, rate: style.specialRate)
        }
    }

    func playPause() {
        let style = audioStyle(for: settings.visualTheme)
        playEffect(asset: .pause, volume: 0.90 * style.effectVolumeScale, rate: style.pauseRate)
    }

    func playGameOver() {
        let style = audioStyle(for: settings.visualTheme)
        playEffect(asset: .gameOver, volume: 0.96 * style.effectVolumeScale, rate: style.gameOverRate)
    }

    func playNavigate() {
        let style = audioStyle(for: settings.visualTheme)
        playEffect(asset: .navigate, volume: 0.70 * style.effectVolumeScale, rate: style.navigateRate)
    }

    func playConfirm() {
        let style = audioStyle(for: settings.visualTheme)
        playEffect(asset: .confirm, volume: 0.82 * style.effectVolumeScale, rate: style.confirmRate)
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

    private func playEffect(asset: AudioAsset, volume: Float, rate: Float) {
        guard settings.soundEnabled else {
            return
        }

        pruneEffectPlayers()
        guard let player = makePlayer(asset: asset, loops: 0, volume: volume, rate: rate) else {
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

    private func makePlayer(asset: AudioAsset, loops: Int, volume: Float, rate: Float) -> AVAudioPlayer? {
        guard let url = resourceURL(for: asset) else {
            return nil
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = loops
            player.volume = volume
            player.enableRate = true
            player.rate = rate
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

    private func rebuildMusicPlayers() {
        let style = audioStyle(for: settings.visualTheme)
        menuMusicPlayer = makePlayer(
            asset: .menuLoop,
            loops: -1,
            volume: 0.42 * style.musicVolumeScale,
            rate: style.menuLoopRate
        )
        gameplayMusicPlayer = makePlayer(
            asset: .gameplayLoop,
            loops: -1,
            volume: 0.34 * style.musicVolumeScale,
            rate: style.gameplayLoopRate
        )
    }

    private func audioStyle(for theme: VisualTheme) -> AudioStyle {
        switch theme {
        case .orchard:
            return AudioStyle(
                effectRate: 1.0,
                specialRate: 1.02,
                confirmRate: 1.0,
                navigateRate: 1.0,
                pauseRate: 0.98,
                gameOverRate: 0.96,
                menuLoopRate: 1.0,
                gameplayLoopRate: 1.0,
                effectVolumeScale: 1.0,
                musicVolumeScale: 1.0
            )
        case .sunset:
            return AudioStyle(
                effectRate: 0.94,
                specialRate: 0.98,
                confirmRate: 0.92,
                navigateRate: 0.94,
                pauseRate: 0.90,
                gameOverRate: 0.88,
                menuLoopRate: 0.96,
                gameplayLoopRate: 0.94,
                effectVolumeScale: 0.96,
                musicVolumeScale: 1.06
            )
        case .mint:
            return AudioStyle(
                effectRate: 1.08,
                specialRate: 1.16,
                confirmRate: 1.12,
                navigateRate: 1.10,
                pauseRate: 1.04,
                gameOverRate: 0.98,
                menuLoopRate: 1.04,
                gameplayLoopRate: 1.06,
                effectVolumeScale: 0.94,
                musicVolumeScale: 0.98
            )
        case .neon:
            return AudioStyle(
                effectRate: 1.12,
                specialRate: 1.22,
                confirmRate: 1.18,
                navigateRate: 1.14,
                pauseRate: 1.06,
                gameOverRate: 0.92,
                menuLoopRate: 1.08,
                gameplayLoopRate: 1.10,
                effectVolumeScale: 1.02,
                musicVolumeScale: 1.04
            )
        }
    }
}
