import AppKit
import Foundation

struct IconSpec {
    let filename: String
    let pixels: Int
}

let specs: [IconSpec] = [
    .init(filename: "appicon_16x16.png", pixels: 16),
    .init(filename: "appicon_16x16@2x.png", pixels: 32),
    .init(filename: "appicon_32x32.png", pixels: 32),
    .init(filename: "appicon_32x32@2x.png", pixels: 64),
    .init(filename: "appicon_128x128.png", pixels: 128),
    .init(filename: "appicon_128x128@2x.png", pixels: 256),
    .init(filename: "appicon_256x256.png", pixels: 256),
    .init(filename: "appicon_256x256@2x.png", pixels: 512),
    .init(filename: "appicon_512x512.png", pixels: 512),
    .init(filename: "appicon_512x512@2x.png", pixels: 1024),
]

let fileManager = FileManager.default
let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
let outputDirectory = currentDirectory
    .appendingPathComponent("贪吃蛇")
    .appendingPathComponent("Resources")
    .appendingPathComponent("Common")
    .appendingPathComponent("Assets.xcassets")
    .appendingPathComponent("AppIcon.appiconset")

func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1.0) -> NSColor {
    NSColor(calibratedRed: red / 255.0, green: green / 255.0, blue: blue / 255.0, alpha: alpha)
}

func roundedRect(_ rect: CGRect, radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}

func badgePath(in rect: CGRect, lobes: Int) -> NSBezierPath {
    let path = NSBezierPath()
    let center = CGPoint(x: rect.midX, y: rect.midY)
    let baseRadius = rect.width * 0.42
    let amplitude = rect.width * 0.022
    let steps = lobes * 10

    for step in 0 ... steps {
        let t = CGFloat(step) / CGFloat(steps)
        let angle = -.pi / 2 + t * .pi * 2
        let radius = baseRadius + sin(t * .pi * 2 * CGFloat(lobes)) * amplitude
        let point = CGPoint(
            x: center.x + cos(angle) * radius,
            y: center.y + sin(angle) * radius
        )
        if step == 0 {
            path.move(to: point)
        } else {
            path.line(to: point)
        }
    }

    path.close()
    return path
}

func drawBackground(in rect: CGRect) {
    let base = roundedRect(rect, radius: rect.width * 0.22)
    base.addClip()

    let gradient = NSGradient(colors: [
        color(248, 239, 225),
        color(242, 230, 212),
        color(232, 213, 190)
    ])!
    gradient.draw(in: base, angle: -90)

    let glow = NSBezierPath(ovalIn: CGRect(
        x: rect.minX + rect.width * 0.08,
        y: rect.minY + rect.height * 0.26,
        width: rect.width * 0.84,
        height: rect.height * 0.56
    ))
    color(255, 255, 255, 0.34).setFill()
    glow.fill()

    let vignette = NSGradient(colors: [
        color(255, 255, 255, 0.0),
        color(179, 138, 99, 0.18)
    ])!
    vignette.draw(in: base, relativeCenterPosition: NSPoint(x: 0.0, y: -0.2))
}

func drawSeal(in rect: CGRect) {
    let seal = badgePath(in: rect, lobes: 18)
    color(250, 244, 235).setFill()
    seal.fill()

    color(179, 136, 101).setStroke()
    seal.lineWidth = rect.width * 0.018
    seal.stroke()

    let innerRect = rect.insetBy(dx: rect.width * 0.06, dy: rect.height * 0.06)
    let inner = badgePath(in: innerRect, lobes: 18)
    color(255, 251, 246).setFill()
    inner.fill()

    color(196, 158, 125, 0.88).setStroke()
    inner.lineWidth = rect.width * 0.010
    inner.stroke()

    let dotRadius = rect.width * 0.008
    let dotRingRadius = rect.width * 0.38
    for index in 0 ..< 26 {
        let angle = -.pi / 2 + CGFloat(index) / 26.0 * .pi * 2
        let dotCenter = CGPoint(
            x: rect.midX + cos(angle) * dotRingRadius,
            y: rect.midY + sin(angle) * dotRingRadius
        )
        let dotRect = CGRect(
            x: dotCenter.x - dotRadius,
            y: dotCenter.y - dotRadius,
            width: dotRadius * 2,
            height: dotRadius * 2
        )
        color(186, 145, 110, 0.9).setFill()
        NSBezierPath(ovalIn: dotRect).fill()
    }
}

func drawSpark(at center: CGPoint, size: CGFloat, fill: NSColor) {
    let path = NSBezierPath()
    path.move(to: CGPoint(x: center.x, y: center.y + size))
    path.line(to: CGPoint(x: center.x + size * 0.34, y: center.y + size * 0.34))
    path.line(to: CGPoint(x: center.x + size, y: center.y))
    path.line(to: CGPoint(x: center.x + size * 0.34, y: center.y - size * 0.34))
    path.line(to: CGPoint(x: center.x, y: center.y - size))
    path.line(to: CGPoint(x: center.x - size * 0.34, y: center.y - size * 0.34))
    path.line(to: CGPoint(x: center.x - size, y: center.y))
    path.line(to: CGPoint(x: center.x - size * 0.34, y: center.y + size * 0.34))
    path.close()
    fill.setFill()
    path.fill()
}

func drawHeart(at center: CGPoint, size: CGFloat, fill: NSColor) {
    let path = NSBezierPath()
    path.move(to: CGPoint(x: center.x, y: center.y - size * 0.58))
    path.curve(
        to: CGPoint(x: center.x - size * 0.92, y: center.y + size * 0.18),
        controlPoint1: CGPoint(x: center.x - size * 0.56, y: center.y - size * 0.24),
        controlPoint2: CGPoint(x: center.x - size * 0.92, y: center.y - size * 0.22)
    )
    path.curve(
        to: CGPoint(x: center.x, y: center.y + size * 0.92),
        controlPoint1: CGPoint(x: center.x - size * 0.92, y: center.y + size * 0.76),
        controlPoint2: CGPoint(x: center.x - size * 0.36, y: center.y + size * 0.92)
    )
    path.curve(
        to: CGPoint(x: center.x + size * 0.92, y: center.y + size * 0.18),
        controlPoint1: CGPoint(x: center.x + size * 0.36, y: center.y + size * 0.92),
        controlPoint2: CGPoint(x: center.x + size * 0.92, y: center.y + size * 0.76)
    )
    path.curve(
        to: CGPoint(x: center.x, y: center.y - size * 0.58),
        controlPoint1: CGPoint(x: center.x + size * 0.92, y: center.y - size * 0.22),
        controlPoint2: CGPoint(x: center.x + size * 0.56, y: center.y - size * 0.24)
    )
    fill.setFill()
    path.fill()
}

func drawRoundedBody(_ rect: CGRect, fill: NSColor, stroke: NSColor, radius: CGFloat) {
    let body = roundedRect(rect, radius: radius)
    fill.setFill()
    body.fill()
    stroke.setStroke()
    body.lineWidth = rect.width * 0.06
    body.stroke()
}

func drawSword(in rect: CGRect) {
    let blade = NSBezierPath()
    blade.move(to: CGPoint(x: rect.minX, y: rect.minY))
    blade.line(to: CGPoint(x: rect.maxX, y: rect.maxY - rect.height * 0.06))
    blade.line(to: CGPoint(x: rect.maxX - rect.width * 0.14, y: rect.maxY))
    blade.line(to: CGPoint(x: rect.minX - rect.width * 0.08, y: rect.minY + rect.height * 0.08))
    blade.close()
    color(210, 225, 232).setFill()
    blade.fill()
    color(140, 111, 91, 0.65).setStroke()
    blade.lineWidth = rect.width * 0.05
    blade.stroke()

    let hilt = NSBezierPath(roundedRect: CGRect(
        x: rect.minX - rect.width * 0.08,
        y: rect.minY - rect.height * 0.08,
        width: rect.width * 0.34,
        height: rect.height * 0.14
    ), xRadius: rect.height * 0.06, yRadius: rect.height * 0.06)
    color(185, 129, 84).setFill()
    hilt.fill()
}

func drawStaff(in rect: CGRect) {
    let stick = NSBezierPath()
    stick.move(to: CGPoint(x: rect.minX, y: rect.minY))
    stick.line(to: CGPoint(x: rect.maxX, y: rect.maxY))
    stick.lineWidth = rect.width * 0.14
    stick.lineCapStyle = .round
    color(154, 117, 90).setStroke()
    stick.stroke()

    let orbRect = CGRect(
        x: rect.maxX - rect.width * 0.18,
        y: rect.maxY - rect.width * 0.18,
        width: rect.width * 0.34,
        height: rect.width * 0.34
    )
    color(180, 233, 240).setFill()
    NSBezierPath(ovalIn: orbRect).fill()
    color(156, 114, 87).setStroke()
    let ring = NSBezierPath(ovalIn: orbRect.insetBy(dx: -rect.width * 0.04, dy: -rect.width * 0.04))
    ring.lineWidth = rect.width * 0.07
    ring.stroke()
}

func fillCircle(center: CGPoint, radius: CGFloat, fill: NSColor) {
    fill.setFill()
    NSBezierPath(ovalIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)).fill()
}

func strokePath(_ path: NSBezierPath, color: NSColor, width: CGFloat) {
    color.setStroke()
    path.lineWidth = width
    path.lineCapStyle = .round
    path.lineJoinStyle = .round
    path.stroke()
}

func drawEye(at center: CGPoint, size: CGFloat) {
    fillCircle(center: center, radius: size, fill: color(71, 47, 34))
}

func drawSmile(center: CGPoint, width: CGFloat) {
    let smile = NSBezierPath()
    smile.move(to: CGPoint(x: center.x - width * 0.5, y: center.y))
    smile.curve(
        to: CGPoint(x: center.x + width * 0.5, y: center.y),
        controlPoint1: CGPoint(x: center.x - width * 0.2, y: center.y - width * 0.35),
        controlPoint2: CGPoint(x: center.x + width * 0.2, y: center.y - width * 0.35)
    )
    strokePath(smile, color: color(139, 89, 70), width: width * 0.12)
}

func drawCape(in rect: CGRect, fill: NSColor) {
    let cape = NSBezierPath()
    cape.move(to: CGPoint(x: rect.midX, y: rect.maxY))
    cape.line(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.18))
    cape.curve(
        to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.18),
        controlPoint1: CGPoint(x: rect.minX + rect.width * 0.24, y: rect.minY - rect.height * 0.08),
        controlPoint2: CGPoint(x: rect.maxX - rect.width * 0.24, y: rect.minY - rect.height * 0.08)
    )
    cape.close()
    fill.setFill()
    cape.fill()
}

func drawCastle(in rect: CGRect) {
    let base = roundedRect(rect, radius: rect.width * 0.08)
    color(124, 105, 103, 0.22).setFill()
    base.fill()

    let towerWidth = rect.width * 0.22
    let towerRects = [
        CGRect(x: rect.minX + rect.width * 0.06, y: rect.minY + rect.height * 0.12, width: towerWidth, height: rect.height * 0.58),
        CGRect(x: rect.midX - towerWidth * 0.5, y: rect.minY + rect.height * 0.18, width: towerWidth, height: rect.height * 0.52),
        CGRect(x: rect.maxX - rect.width * 0.06 - towerWidth, y: rect.minY + rect.height * 0.12, width: towerWidth, height: rect.height * 0.58)
    ]
    for tower in towerRects {
        drawRoundedBody(tower, fill: color(125, 108, 120, 0.84), stroke: color(102, 82, 90, 0.8), radius: rect.width * 0.03)
        for notch in 0 ..< 3 {
            let notchRect = CGRect(
                x: tower.minX + CGFloat(notch) * tower.width / 3.0,
                y: tower.maxY - rect.height * 0.10,
                width: tower.width * 0.22,
                height: rect.height * 0.08
            )
            color(250, 244, 235).setFill()
            notchRect.fill()
        }
    }

    let gate = NSBezierPath(roundedRect: CGRect(
        x: rect.midX - rect.width * 0.12,
        y: rect.minY + rect.height * 0.12,
        width: rect.width * 0.24,
        height: rect.height * 0.34
    ), xRadius: rect.width * 0.08, yRadius: rect.width * 0.08)
    color(88, 72, 76).setFill()
    gate.fill()
}

func drawBook(in rect: CGRect) {
    let cover = NSBezierPath(roundedRect: rect, xRadius: rect.width * 0.18, yRadius: rect.width * 0.18)
    color(153, 107, 79).setFill()
    cover.fill()
    strokePath(cover, color: color(120, 82, 59), width: rect.width * 0.08)

    let page = CGRect(x: rect.minX + rect.width * 0.16, y: rect.minY + rect.height * 0.14, width: rect.width * 0.68, height: rect.height * 0.70)
    color(246, 238, 220).setFill()
    NSBezierPath(roundedRect: page, xRadius: rect.width * 0.08, yRadius: rect.width * 0.08).fill()
    fillCircle(center: CGPoint(x: rect.midX, y: rect.midY), radius: rect.width * 0.12, fill: color(236, 184, 101))
}

func drawPotion(in rect: CGRect) {
    let neck = CGRect(x: rect.midX - rect.width * 0.10, y: rect.maxY - rect.height * 0.28, width: rect.width * 0.20, height: rect.height * 0.18)
    drawRoundedBody(neck, fill: color(226, 215, 205), stroke: color(154, 117, 90), radius: rect.width * 0.06)
    let flask = NSBezierPath()
    flask.move(to: CGPoint(x: rect.midX - rect.width * 0.18, y: rect.maxY - rect.height * 0.30))
    flask.line(to: CGPoint(x: rect.midX - rect.width * 0.26, y: rect.minY + rect.height * 0.24))
    flask.curve(
        to: CGPoint(x: rect.midX + rect.width * 0.26, y: rect.minY + rect.height * 0.24),
        controlPoint1: CGPoint(x: rect.midX - rect.width * 0.18, y: rect.minY + rect.height * 0.02),
        controlPoint2: CGPoint(x: rect.midX + rect.width * 0.18, y: rect.minY + rect.height * 0.02)
    )
    flask.line(to: CGPoint(x: rect.midX + rect.width * 0.18, y: rect.maxY - rect.height * 0.30))
    flask.close()
    color(244, 246, 250, 0.92).setFill()
    flask.fill()
    strokePath(flask, color: color(154, 117, 90), width: rect.width * 0.06)

    let liquid = NSBezierPath()
    liquid.move(to: CGPoint(x: rect.midX - rect.width * 0.20, y: rect.minY + rect.height * 0.30))
    liquid.curve(
        to: CGPoint(x: rect.midX + rect.width * 0.20, y: rect.minY + rect.height * 0.30),
        controlPoint1: CGPoint(x: rect.midX - rect.width * 0.12, y: rect.minY + rect.height * 0.36),
        controlPoint2: CGPoint(x: rect.midX + rect.width * 0.12, y: rect.minY + rect.height * 0.24)
    )
    liquid.line(to: CGPoint(x: rect.midX + rect.width * 0.22, y: rect.minY + rect.height * 0.18))
    liquid.curve(
        to: CGPoint(x: rect.midX - rect.width * 0.22, y: rect.minY + rect.height * 0.18),
        controlPoint1: CGPoint(x: rect.midX + rect.width * 0.12, y: rect.minY + rect.height * 0.05),
        controlPoint2: CGPoint(x: rect.midX - rect.width * 0.12, y: rect.minY + rect.height * 0.05)
    )
    liquid.close()
    color(153, 87, 182, 0.92).setFill()
    liquid.fill()
}

func drawFather(in rect: CGRect) {
    let outline = color(135, 90, 67)
    drawCape(
        in: CGRect(x: rect.minX + rect.width * 0.04, y: rect.minY + rect.height * 0.12, width: rect.width * 0.54, height: rect.height * 0.46),
        fill: color(225, 214, 201)
    )
    let torso = CGRect(x: rect.minX + rect.width * 0.16, y: rect.minY + rect.height * 0.16, width: rect.width * 0.38, height: rect.height * 0.42)
    drawRoundedBody(torso, fill: color(239, 231, 220), stroke: outline, radius: rect.width * 0.08)

    let armor = NSBezierPath(roundedRect: CGRect(
        x: torso.minX + rect.width * 0.05,
        y: torso.minY + rect.height * 0.16,
        width: torso.width - rect.width * 0.10,
        height: torso.height * 0.42
    ), xRadius: rect.width * 0.05, yRadius: rect.width * 0.05)
    color(217, 222, 228).setFill()
    armor.fill()
    strokePath(armor, color: color(141, 120, 108), width: rect.width * 0.015)

    let belt = CGRect(x: torso.minX + rect.width * 0.04, y: torso.minY + rect.height * 0.11, width: torso.width - rect.width * 0.08, height: rect.height * 0.05)
    drawRoundedBody(belt, fill: color(148, 106, 74), stroke: outline, radius: rect.width * 0.02)
    fillCircle(center: CGPoint(x: belt.midX, y: belt.midY), radius: rect.width * 0.028, fill: color(227, 184, 117))

    let headCenter = CGPoint(x: torso.midX, y: torso.maxY + rect.height * 0.10)
    fillCircle(center: headCenter, radius: rect.width * 0.12, fill: color(248, 214, 190))

    let hair = NSBezierPath()
    hair.move(to: CGPoint(x: headCenter.x - rect.width * 0.12, y: headCenter.y + rect.width * 0.00))
    hair.curve(
        to: CGPoint(x: headCenter.x + rect.width * 0.12, y: headCenter.y + rect.width * 0.01),
        controlPoint1: CGPoint(x: headCenter.x - rect.width * 0.10, y: headCenter.y + rect.width * 0.16),
        controlPoint2: CGPoint(x: headCenter.x + rect.width * 0.09, y: headCenter.y + rect.width * 0.17)
    )
    hair.line(to: CGPoint(x: headCenter.x + rect.width * 0.10, y: headCenter.y + rect.width * 0.10))
    hair.line(to: CGPoint(x: headCenter.x - rect.width * 0.10, y: headCenter.y + rect.width * 0.10))
    hair.close()
    color(120, 72, 47).setFill()
    hair.fill()

    let beard = NSBezierPath()
    beard.move(to: CGPoint(x: headCenter.x - rect.width * 0.08, y: headCenter.y - rect.width * 0.01))
    beard.curve(
        to: CGPoint(x: headCenter.x + rect.width * 0.08, y: headCenter.y - rect.width * 0.01),
        controlPoint1: CGPoint(x: headCenter.x - rect.width * 0.06, y: headCenter.y - rect.width * 0.13),
        controlPoint2: CGPoint(x: headCenter.x + rect.width * 0.06, y: headCenter.y - rect.width * 0.13)
    )
    beard.line(to: CGPoint(x: headCenter.x + rect.width * 0.06, y: headCenter.y + rect.width * 0.02))
    beard.line(to: CGPoint(x: headCenter.x - rect.width * 0.06, y: headCenter.y + rect.width * 0.02))
    beard.close()
    color(98, 59, 39).setFill()
    beard.fill()

    drawEye(at: CGPoint(x: headCenter.x - rect.width * 0.035, y: headCenter.y + rect.width * 0.02), size: rect.width * 0.010)
    drawEye(at: CGPoint(x: headCenter.x + rect.width * 0.035, y: headCenter.y + rect.width * 0.02), size: rect.width * 0.010)
    drawSmile(center: CGPoint(x: headCenter.x, y: headCenter.y - rect.width * 0.03), width: rect.width * 0.05)

    let arm = NSBezierPath()
    arm.move(to: CGPoint(x: torso.minX + rect.width * 0.05, y: torso.midY + rect.height * 0.05))
    arm.line(to: CGPoint(x: torso.minX - rect.width * 0.08, y: torso.midY - rect.height * 0.10))
    strokePath(arm, color: outline, width: rect.width * 0.06)

    drawSword(in: CGRect(
        x: rect.minX - rect.width * 0.08,
        y: rect.minY + rect.height * 0.14,
        width: rect.width * 0.26,
        height: rect.height * 0.56
    ))
}

func drawChild(in rect: CGRect) {
    let outline = color(138, 96, 70)
    let torso = CGRect(x: rect.midX - rect.width * 0.18, y: rect.minY + rect.height * 0.12, width: rect.width * 0.36, height: rect.height * 0.32)
    drawRoundedBody(torso, fill: color(231, 217, 191), stroke: outline, radius: rect.width * 0.08)

    let vest = NSBezierPath(roundedRect: CGRect(
        x: torso.minX + rect.width * 0.03,
        y: torso.minY + rect.height * 0.06,
        width: torso.width - rect.width * 0.06,
        height: torso.height * 0.78
    ), xRadius: rect.width * 0.05, yRadius: rect.width * 0.05)
    color(162, 115, 86).setFill()
    vest.fill()

    let shirt = NSBezierPath(roundedRect: CGRect(
        x: torso.midX - rect.width * 0.07,
        y: torso.minY + rect.height * 0.06,
        width: rect.width * 0.14,
        height: torso.height * 0.72
    ), xRadius: rect.width * 0.04, yRadius: rect.width * 0.04)
    color(244, 235, 220).setFill()
    shirt.fill()

    let headCenter = CGPoint(x: rect.midX, y: torso.maxY + rect.height * 0.09)
    fillCircle(center: headCenter, radius: rect.width * 0.11, fill: color(250, 216, 188))

    let hair = NSBezierPath()
    hair.move(to: CGPoint(x: headCenter.x - rect.width * 0.11, y: headCenter.y + rect.width * 0.00))
    hair.curve(
        to: CGPoint(x: headCenter.x + rect.width * 0.11, y: headCenter.y + rect.width * 0.02),
        controlPoint1: CGPoint(x: headCenter.x - rect.width * 0.09, y: headCenter.y + rect.width * 0.12),
        controlPoint2: CGPoint(x: headCenter.x + rect.width * 0.08, y: headCenter.y + rect.width * 0.14)
    )
    hair.line(to: CGPoint(x: headCenter.x + rect.width * 0.05, y: headCenter.y + rect.width * 0.12))
    hair.line(to: CGPoint(x: headCenter.x - rect.width * 0.07, y: headCenter.y + rect.width * 0.10))
    hair.close()
    color(121, 77, 46).setFill()
    hair.fill()

    drawEye(at: CGPoint(x: headCenter.x - rect.width * 0.032, y: headCenter.y + rect.width * 0.02), size: rect.width * 0.010)
    drawEye(at: CGPoint(x: headCenter.x + rect.width * 0.032, y: headCenter.y + rect.width * 0.02), size: rect.width * 0.010)
    drawSmile(center: CGPoint(x: headCenter.x, y: headCenter.y - rect.width * 0.03), width: rect.width * 0.05)
    fillCircle(center: CGPoint(x: headCenter.x - rect.width * 0.058, y: headCenter.y - rect.width * 0.005), radius: rect.width * 0.012, fill: color(239, 168, 152))
    fillCircle(center: CGPoint(x: headCenter.x + rect.width * 0.058, y: headCenter.y - rect.width * 0.005), radius: rect.width * 0.012, fill: color(239, 168, 152))

    let armLeft = NSBezierPath()
    armLeft.move(to: CGPoint(x: torso.minX + rect.width * 0.04, y: torso.midY + rect.height * 0.03))
    armLeft.line(to: CGPoint(x: torso.minX - rect.width * 0.09, y: torso.midY - rect.height * 0.06))
    strokePath(armLeft, color: outline, width: rect.width * 0.05)

    let armRight = NSBezierPath()
    armRight.move(to: CGPoint(x: torso.maxX - rect.width * 0.04, y: torso.midY + rect.height * 0.02))
    armRight.line(to: CGPoint(x: torso.maxX + rect.width * 0.09, y: torso.midY - rect.height * 0.10))
    strokePath(armRight, color: outline, width: rect.width * 0.05)

    drawSword(in: CGRect(
        x: rect.midX + rect.width * 0.06,
        y: rect.minY + rect.height * 0.17,
        width: rect.width * 0.18,
        height: rect.height * 0.34
    ))
}

func drawMother(in rect: CGRect) {
    let outline = color(142, 101, 74)
    let dress = NSBezierPath()
    dress.move(to: CGPoint(x: rect.midX, y: rect.maxY - rect.height * 0.08))
    dress.line(to: CGPoint(x: rect.minX + rect.width * 0.12, y: rect.minY + rect.height * 0.10))
    dress.curve(
        to: CGPoint(x: rect.maxX - rect.width * 0.12, y: rect.minY + rect.height * 0.10),
        controlPoint1: CGPoint(x: rect.midX - rect.width * 0.10, y: rect.minY),
        controlPoint2: CGPoint(x: rect.midX + rect.width * 0.10, y: rect.minY)
    )
    dress.close()
    color(211, 228, 208).setFill()
    dress.fill()
    strokePath(dress, color: outline, width: rect.width * 0.02)

    let shoulder = NSBezierPath(roundedRect: CGRect(
        x: rect.midX - rect.width * 0.14,
        y: rect.minY + rect.height * 0.26,
        width: rect.width * 0.28,
        height: rect.height * 0.16
    ), xRadius: rect.width * 0.06, yRadius: rect.width * 0.06)
    color(224, 237, 223).setFill()
    shoulder.fill()

    let headCenter = CGPoint(x: rect.midX, y: rect.maxY - rect.height * 0.02)
    fillCircle(center: headCenter, radius: rect.width * 0.11, fill: color(250, 216, 190))

    let hair = NSBezierPath()
    hair.move(to: CGPoint(x: headCenter.x - rect.width * 0.11, y: headCenter.y + rect.width * 0.00))
    hair.curve(
        to: CGPoint(x: headCenter.x + rect.width * 0.11, y: headCenter.y + rect.width * 0.00),
        controlPoint1: CGPoint(x: headCenter.x - rect.width * 0.09, y: headCenter.y + rect.width * 0.12),
        controlPoint2: CGPoint(x: headCenter.x + rect.width * 0.09, y: headCenter.y + rect.width * 0.12)
    )
    hair.line(to: CGPoint(x: headCenter.x + rect.width * 0.08, y: headCenter.y + rect.width * 0.10))
    hair.line(to: CGPoint(x: headCenter.x - rect.width * 0.08, y: headCenter.y + rect.width * 0.10))
    hair.close()
    color(171, 111, 77).setFill()
    hair.fill()

    let braid = NSBezierPath()
    braid.move(to: CGPoint(x: headCenter.x + rect.width * 0.05, y: headCenter.y - rect.width * 0.02))
    braid.curve(
        to: CGPoint(x: headCenter.x + rect.width * 0.11, y: headCenter.y - rect.height * 0.28),
        controlPoint1: CGPoint(x: headCenter.x + rect.width * 0.13, y: headCenter.y - rect.height * 0.08),
        controlPoint2: CGPoint(x: headCenter.x + rect.width * 0.10, y: headCenter.y - rect.height * 0.22)
    )
    strokePath(braid, color: color(168, 108, 76), width: rect.width * 0.045)

    for bead in 0 ..< 3 {
        fillCircle(
            center: CGPoint(x: headCenter.x + rect.width * (0.075 + CGFloat(bead) * 0.012), y: headCenter.y - rect.height * (0.10 + CGFloat(bead) * 0.07)),
            radius: rect.width * 0.020,
            fill: color(185, 122, 84)
        )
    }

    drawEye(at: CGPoint(x: headCenter.x - rect.width * 0.032, y: headCenter.y + rect.width * 0.02), size: rect.width * 0.010)
    drawEye(at: CGPoint(x: headCenter.x + rect.width * 0.032, y: headCenter.y + rect.width * 0.02), size: rect.width * 0.010)
    drawSmile(center: CGPoint(x: headCenter.x, y: headCenter.y - rect.width * 0.03), width: rect.width * 0.05)

    drawStaff(in: CGRect(
        x: rect.maxX - rect.width * 0.16,
        y: rect.minY + rect.height * 0.02,
        width: rect.width * 0.18,
        height: rect.height * 0.54
    ))
}

func drawFamilyProps(in rect: CGRect) {
    drawCastle(in: CGRect(
        x: rect.minX + rect.width * 0.05,
        y: rect.midY + rect.height * 0.04,
        width: rect.width * 0.20,
        height: rect.height * 0.24
    ))
    drawBook(in: CGRect(
        x: rect.minX + rect.width * 0.12,
        y: rect.minY + rect.height * 0.12,
        width: rect.width * 0.08,
        height: rect.height * 0.10
    ))
    drawPotion(in: CGRect(
        x: rect.maxX - rect.width * 0.20,
        y: rect.minY + rect.height * 0.10,
        width: rect.width * 0.10,
        height: rect.height * 0.13
    ))
}

func drawFamily(in rect: CGRect) {
    drawFamilyProps(in: rect)
    drawFather(in: CGRect(
        x: rect.minX + rect.width * 0.12,
        y: rect.minY + rect.height * 0.22,
        width: rect.width * 0.32,
        height: rect.height * 0.42
    ))
    drawChild(in: CGRect(
        x: rect.midX - rect.width * 0.14,
        y: rect.minY + rect.height * 0.12,
        width: rect.width * 0.28,
        height: rect.height * 0.36
    ))
    drawMother(in: CGRect(
        x: rect.maxX - rect.width * 0.40,
        y: rect.minY + rect.height * 0.20,
        width: rect.width * 0.30,
        height: rect.height * 0.40
    ))
}

func drawLabel(_ text: String, in rect: CGRect, fontSize: CGFloat, color fill: NSColor) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont(name: "PingFangSC-Semibold", size: fontSize) ?? NSFont.boldSystemFont(ofSize: fontSize),
        .foregroundColor: fill,
        .paragraphStyle: paragraph
    ]
    let attributed = NSAttributedString(string: text, attributes: attributes)
    attributed.draw(in: rect)
}

func renderIcon(size: Int) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!

    let rect = CGRect(x: 0, y: 0, width: size, height: size)
    NSGraphicsContext.saveGraphicsState()
    let context = NSGraphicsContext(bitmapImageRep: rep)!
    context.imageInterpolation = .high
    NSGraphicsContext.current = context

    NSColor.clear.setFill()
    rect.fill()

    let cardRect = rect.insetBy(dx: rect.width * 0.04, dy: rect.height * 0.04)
    drawBackground(in: cardRect)

    let sealRect = cardRect.insetBy(dx: cardRect.width * 0.08, dy: cardRect.height * 0.06)
    drawSeal(in: sealRect)

    drawSpark(
        at: CGPoint(x: sealRect.minX + sealRect.width * 0.20, y: sealRect.midY + sealRect.height * 0.16),
        size: sealRect.width * 0.025,
        fill: color(242, 203, 116, 0.95)
    )
    drawSpark(
        at: CGPoint(x: sealRect.maxX - sealRect.width * 0.18, y: sealRect.midY + sealRect.height * 0.10),
        size: sealRect.width * 0.022,
        fill: color(153, 199, 213, 0.95)
    )
    drawHeart(
        at: CGPoint(x: sealRect.midX, y: sealRect.midY + sealRect.height * 0.19),
        size: sealRect.width * 0.030,
        fill: color(206, 100, 86, 0.95)
    )

    drawFamily(in: sealRect)

    if size >= 128 {
        drawLabel(
            "勇者一家",
            in: CGRect(
                x: sealRect.minX,
                y: sealRect.maxY - sealRect.height * 0.22,
                width: sealRect.width,
                height: sealRect.height * 0.12
            ),
            fontSize: sealRect.width * 0.11,
            color: color(178, 101, 69)
        )

        drawLabel(
            "一起闯关",
            in: CGRect(
                x: sealRect.minX,
                y: sealRect.minY + sealRect.height * 0.06,
                width: sealRect.width,
                height: sealRect.height * 0.12
            ),
            fontSize: sealRect.width * 0.11,
            color: color(77, 131, 176)
        )
    }

    context.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()
    return rep
}

try fileManager.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

for spec in specs {
    let destination = outputDirectory.appendingPathComponent(spec.filename)
    let bitmap = renderIcon(size: spec.pixels)
    let data = bitmap.representation(using: .png, properties: [:])!
    try data.write(to: destination)
    print("wrote \(destination.path)")
}
