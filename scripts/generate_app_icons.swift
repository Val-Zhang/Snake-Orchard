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

func drawFigure(
    center: CGPoint,
    scale: CGFloat,
    bodyColor: NSColor,
    hairColor: NSColor,
    outline: NSColor,
    accessory: String
) {
    let headRect = CGRect(
        x: center.x - scale * 0.12,
        y: center.y + scale * 0.10,
        width: scale * 0.24,
        height: scale * 0.24
    )
    color(249, 214, 187).setFill()
    NSBezierPath(ovalIn: headRect).fill()

    let hairRect = CGRect(
        x: headRect.minX - scale * 0.02,
        y: headRect.midY,
        width: headRect.width + scale * 0.04,
        height: headRect.height * 0.70
    )
    let hair = NSBezierPath(roundedRect: hairRect, xRadius: scale * 0.08, yRadius: scale * 0.08)
    hairColor.setFill()
    hair.fill()

    let bodyRect = CGRect(
        x: center.x - scale * 0.16,
        y: center.y - scale * 0.16,
        width: scale * 0.32,
        height: scale * 0.32
    )
    drawRoundedBody(bodyRect, fill: bodyColor, stroke: outline, radius: scale * 0.10)

    let armLeft = NSBezierPath()
    armLeft.move(to: CGPoint(x: bodyRect.minX + scale * 0.04, y: bodyRect.midY + scale * 0.04))
    armLeft.line(to: CGPoint(x: bodyRect.minX - scale * 0.10, y: bodyRect.midY - scale * 0.08))
    armLeft.lineWidth = scale * 0.07
    armLeft.lineCapStyle = .round
    outline.setStroke()
    armLeft.stroke()

    let armRight = NSBezierPath()
    armRight.move(to: CGPoint(x: bodyRect.maxX - scale * 0.04, y: bodyRect.midY + scale * 0.02))
    armRight.line(to: CGPoint(x: bodyRect.maxX + scale * 0.11, y: bodyRect.midY - scale * 0.12))
    armRight.lineWidth = scale * 0.07
    armRight.lineCapStyle = .round
    outline.setStroke()
    armRight.stroke()

    let leftEye = NSBezierPath(ovalIn: CGRect(
        x: headRect.minX + scale * 0.06,
        y: headRect.minY + scale * 0.12,
        width: scale * 0.025,
        height: scale * 0.025
    ))
    let rightEye = NSBezierPath(ovalIn: CGRect(
        x: headRect.maxX - scale * 0.085,
        y: headRect.minY + scale * 0.12,
        width: scale * 0.025,
        height: scale * 0.025
    ))
    NSColor.black.setFill()
    leftEye.fill()
    rightEye.fill()

    let smile = NSBezierPath()
    smile.move(to: CGPoint(x: headRect.midX - scale * 0.035, y: headRect.minY + scale * 0.07))
    smile.curve(
        to: CGPoint(x: headRect.midX + scale * 0.035, y: headRect.minY + scale * 0.07),
        controlPoint1: CGPoint(x: headRect.midX - scale * 0.018, y: headRect.minY + scale * 0.02),
        controlPoint2: CGPoint(x: headRect.midX + scale * 0.018, y: headRect.minY + scale * 0.02)
    )
    smile.lineWidth = scale * 0.018
    smile.lineCapStyle = .round
    color(132, 83, 67).setStroke()
    smile.stroke()

    switch accessory {
    case "swordLarge":
        drawSword(in: CGRect(x: center.x - scale * 0.44, y: center.y - scale * 0.06, width: scale * 0.28, height: scale * 0.52))
    case "swordSmall":
        drawSword(in: CGRect(x: center.x + scale * 0.08, y: center.y - scale * 0.02, width: scale * 0.18, height: scale * 0.34))
    case "staff":
        drawStaff(in: CGRect(x: center.x + scale * 0.12, y: center.y - scale * 0.10, width: scale * 0.18, height: scale * 0.42))
    default:
        break
    }
}

func drawFamily(in rect: CGRect) {
    let outline = color(128, 89, 63)
    drawFigure(
        center: CGPoint(x: rect.midX - rect.width * 0.16, y: rect.midY - rect.height * 0.02),
        scale: rect.width * 0.54,
        bodyColor: color(242, 235, 222),
        hairColor: color(119, 74, 51),
        outline: outline,
        accessory: "swordLarge"
    )
    drawFigure(
        center: CGPoint(x: rect.midX, y: rect.midY - rect.height * 0.06),
        scale: rect.width * 0.48,
        bodyColor: color(226, 201, 170),
        hairColor: color(111, 72, 43),
        outline: outline,
        accessory: "swordSmall"
    )
    drawFigure(
        center: CGPoint(x: rect.midX + rect.width * 0.18, y: rect.midY - rect.height * 0.01),
        scale: rect.width * 0.52,
        bodyColor: color(211, 225, 203),
        hairColor: color(150, 97, 62),
        outline: outline,
        accessory: "staff"
    )
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
