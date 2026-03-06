//
//  ViewController.swift
//  贪吃蛇
//
//  Created by zhangwang on 2026/3/6.
//

import Cocoa
import SpriteKit

class ViewController: NSViewController {
    @IBOutlet var skView: SKView!

    override func viewDidLoad() {
        super.viewDidLoad()

        let scene = GameScene(size: skView.bounds.size)
        scene.scaleMode = .resizeFill

        skView.presentScene(scene)
        skView.ignoresSiblingOrder = true
        skView.showsFPS = true
        skView.showsNodeCount = true
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.makeFirstResponder(skView)
    }
}
