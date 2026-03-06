//
//  GameAudioController.swift
//  贪吃蛇
//
//  Created by zhangwang on 2026/3/6.
//

import AppKit

final class GameAudioController {
    private let eatSound = NSSound(named: NSSound.Name("Glass"))
    private let specialSound = NSSound(named: NSSound.Name("Hero"))
    private let pauseSound = NSSound(named: NSSound.Name("Submarine"))
    private let gameOverSound = NSSound(named: NSSound.Name("Basso"))

    func playFruit(effect: FruitEffect) {
        switch effect {
        case .normal:
            play(sound: eatSound)
        case .golden, .frost:
            play(sound: specialSound)
        }
    }

    func playPause() {
        play(sound: pauseSound)
    }

    func playGameOver() {
        play(sound: gameOverSound)
    }

    private func play(sound: NSSound?) {
        guard let sound else {
            NSSound.beep()
            return
        }

        sound.stop()
        sound.play()
    }
}
