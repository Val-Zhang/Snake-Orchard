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
    .appendingPathComponent("Assets.xcassets")
    .appendingPathComponent("AppIcon.appiconset")

func makeColor(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat = 1.0) -> NSColor {
    NSColor(calibratedRed: red / 255.0, green: green / 255.0, blue: blue / 255.0, alpha: alpha)
}

func roundedRect(_ rect: CGRect, radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}

func drawBackground(in rect: CGRect) {
    let path = roundedRect(rect, radius: rect.width * 0.23)
    path.addClip()

    let gradient = NSGradient(colors: [
        makeColor(red: 255, green: 244, blue: 203),
        makeColor(red: 255, green: 214, blue: 160),
        makeColor(red: 255, green: 173, blue: 129)
    ])!
    gradient.draw(in: path, angle: -35)

    let glowRect = rect.insetBy(dx: rect.width * 0.04, dy: rect.height * 0.04)
    let glowPath = roundedRect(glowRect, radius: rect.width * 0.20)
    makeColor(red: 255, green: 255, blue: 255, alpha: 0.16).setFill()
    glowPath.fill()

    let vignette = NSGradient(colors: [
        makeColor(red: 0, green: 0, blue: 0, alpha: 0.00),
        makeColor(red: 165, green: 92, blue: 47, alpha: 0.18)
    ])!
    vignette.draw(in: path, relativeCenterPosition: NSPoint(x: 0.1, y: 0.35))

    makeColor(red: 255, green: 255, blue: 255, alpha: 0.30).setStroke()
    path.lineWidth = rect.width * 0.018
    path.stroke()
}

func drawShadowOval(in rect: CGRect) {
    let shadowRect = CGRect(
        x: rect.minX + rect.width * 0.22,
        y: rect.minY + rect.height * 0.20,
        width: rect.width * 0.56,
        height: rect.height * 0.11
    )
    let shadow = NSBezierPath(ovalIn: shadowRect)
    let shadowGradient = NSGradient(colors: [
        makeColor(red: 117, green: 72, blue: 37, alpha: 0.28),
        makeColor(red: 117, green: 72, blue: 37, alpha: 0.02)
    ])!
    shadowGradient.draw(in: shadow, angle: 90)
}

func drawTrainSnake(in rect: CGRect) {
    let outline = makeColor(red: 56, green: 123, blue: 72, alpha: 0.22)
    let bodyColor = makeColor(red: 102, green: 215, blue: 116)
    let bodyHighlight = makeColor(red: 171, green: 244, blue: 173)
    let stripeColor = makeColor(red: 219, green: 255, blue: 198, alpha: 0.95)
    let darkGreen = makeColor(red: 48, green: 135, blue: 79)
    let wheelGreen = makeColor(red: 55, green: 120, blue: 74)
    let cream = makeColor(red: 255, green: 247, blue: 227)
    let blush = makeColor(red: 255, green: 145, blue: 144, alpha: 0.65)

    let tail = NSBezierPath()
    tail.move(to: CGPoint(x: rect.minX + rect.width * 0.32, y: rect.minY + rect.height * 0.48))
    tail.curve(
        to: CGPoint(x: rect.minX + rect.width * 0.17, y: rect.minY + rect.height * 0.73),
        controlPoint1: CGPoint(x: rect.minX + rect.width * 0.22, y: rect.minY + rect.height * 0.48),
        controlPoint2: CGPoint(x: rect.minX + rect.width * 0.12, y: rect.minY + rect.height * 0.58)
    )
    tail.curve(
        to: CGPoint(x: rect.minX + rect.width * 0.30, y: rect.minY + rect.height * 0.77),
        controlPoint1: CGPoint(x: rect.minX + rect.width * 0.21, y: rect.minY + rect.height * 0.82),
        controlPoint2: CGPoint(x: rect.minX + rect.width * 0.30, y: rect.minY + rect.height * 0.83)
    )
    tail.lineCapStyle = .round
    tail.lineJoinStyle = .round
    tail.lineWidth = rect.width * 0.12
    outline.setStroke()
    tail.stroke()
    tail.lineWidth = rect.width * 0.10
    bodyColor.setStroke()
    tail.stroke()
    tail.lineWidth = rect.width * 0.05
    bodyHighlight.setStroke()
    tail.stroke()

    let bodyRect = CGRect(
        x: rect.minX + rect.width * 0.24,
        y: rect.minY + rect.height * 0.31,
        width: rect.width * 0.44,
        height: rect.height * 0.23
    )
    let bodyPath = roundedRect(bodyRect, radius: rect.width * 0.10)
    outline.setFill()
    roundedRect(bodyRect.offsetBy(dx: 0, dy: -rect.height * 0.012), radius: rect.width * 0.10).fill()
    bodyColor.setFill()
    bodyPath.fill()

    let stripeRect = CGRect(
        x: bodyRect.minX + bodyRect.width * 0.10,
        y: bodyRect.minY + bodyRect.height * 0.18,
        width: bodyRect.width * 0.72,
        height: bodyRect.height * 0.32
    )
    stripeColor.setFill()
    roundedRect(stripeRect, radius: stripeRect.height * 0.48).fill()

    let cabRect = CGRect(
        x: rect.minX + rect.width * 0.18,
        y: rect.minY + rect.height * 0.42,
        width: rect.width * 0.19,
        height: rect.height * 0.18
    )
    let cabPath = roundedRect(cabRect, radius: rect.width * 0.07)
    outline.setFill()
    roundedRect(cabRect.offsetBy(dx: 0, dy: -rect.height * 0.010), radius: rect.width * 0.07).fill()
    darkGreen.setFill()
    cabPath.fill()

    let windowRect = CGRect(
        x: cabRect.minX + cabRect.width * 0.18,
        y: cabRect.minY + cabRect.height * 0.28,
        width: cabRect.width * 0.46,
        height: cabRect.height * 0.38
    )
    makeColor(red: 220, green: 247, blue: 255, alpha: 0.95).setFill()
    roundedRect(windowRect, radius: windowRect.width * 0.24).fill()

    let chimneyRect = CGRect(
        x: bodyRect.minX + bodyRect.width * 0.22,
        y: bodyRect.maxY - rect.height * 0.01,
        width: rect.width * 0.08,
        height: rect.height * 0.14
    )
    darkGreen.setFill()
    roundedRect(chimneyRect, radius: rect.width * 0.03).fill()
    let chimneyTop = CGRect(
        x: chimneyRect.minX - rect.width * 0.015,
        y: chimneyRect.maxY - rect.height * 0.02,
        width: chimneyRect.width + rect.width * 0.03,
        height: rect.height * 0.04
    )
    roundedRect(chimneyTop, radius: chimneyTop.height * 0.5).fill()

    let puffCenter = CGPoint(x: chimneyRect.midX - rect.width * 0.02, y: chimneyTop.maxY + rect.height * 0.05)
    let puff = NSBezierPath(ovalIn: CGRect(
        x: puffCenter.x - rect.width * 0.045,
        y: puffCenter.y - rect.width * 0.045,
        width: rect.width * 0.09,
        height: rect.width * 0.09
    ))
    makeColor(red: 255, green: 255, blue: 255, alpha: 0.65).setFill()
    puff.fill()

    let headRect = CGRect(
        x: rect.minX + rect.width * 0.58,
        y: rect.minY + rect.height * 0.34,
        width: rect.width * 0.22,
        height: rect.height * 0.19
    )
    let headPath = roundedRect(headRect, radius: rect.width * 0.09)
    outline.setFill()
    roundedRect(headRect.offsetBy(dx: 0, dy: -rect.height * 0.010), radius: rect.width * 0.09).fill()
    bodyColor.setFill()
    headPath.fill()

    let snoutRect = CGRect(
        x: headRect.maxX - rect.width * 0.06,
        y: headRect.minY + headRect.height * 0.12,
        width: rect.width * 0.08,
        height: headRect.height * 0.48
    )
    bodyColor.setFill()
    roundedRect(snoutRect, radius: snoutRect.width * 0.45).fill()

    let leftEye = NSBezierPath(ovalIn: CGRect(
        x: headRect.minX + headRect.width * 0.24,
        y: headRect.minY + headRect.height * 0.56,
        width: headRect.width * 0.11,
        height: headRect.width * 0.11
    ))
    let rightEye = NSBezierPath(ovalIn: CGRect(
        x: headRect.minX + headRect.width * 0.56,
        y: headRect.minY + headRect.height * 0.56,
        width: headRect.width * 0.11,
        height: headRect.width * 0.11
    ))
    NSColor.black.setFill()
    leftEye.fill()
    rightEye.fill()

    let leftCheek = NSBezierPath(ovalIn: CGRect(
        x: headRect.minX + headRect.width * 0.16,
        y: headRect.minY + headRect.height * 0.28,
        width: headRect.width * 0.14,
        height: headRect.width * 0.10
    ))
    let rightCheek = NSBezierPath(ovalIn: CGRect(
        x: headRect.minX + headRect.width * 0.66,
        y: headRect.minY + headRect.height * 0.28,
        width: headRect.width * 0.14,
        height: headRect.width * 0.10
    ))
    blush.setFill()
    leftCheek.fill()
    rightCheek.fill()

    let smile = NSBezierPath()
    smile.move(to: CGPoint(x: headRect.minX + headRect.width * 0.38, y: headRect.minY + headRect.height * 0.30))
    smile.curve(
        to: CGPoint(x: headRect.minX + headRect.width * 0.62, y: headRect.minY + headRect.height * 0.30),
        controlPoint1: CGPoint(x: headRect.minX + headRect.width * 0.44, y: headRect.minY + headRect.height * 0.20),
        controlPoint2: CGPoint(x: headRect.minX + headRect.width * 0.56, y: headRect.minY + headRect.height * 0.20)
    )
    smile.lineCapStyle = .round
    smile.lineWidth = rect.width * 0.012
    makeColor(red: 54, green: 112, blue: 68, alpha: 0.8).setStroke()
    smile.stroke()

    let connector = NSBezierPath()
    connector.move(to: CGPoint(x: bodyRect.maxX - rect.width * 0.01, y: bodyRect.midY + rect.height * 0.02))
    connector.line(to: CGPoint(x: headRect.minX + rect.width * 0.01, y: headRect.midY + rect.height * 0.01))
    connector.lineCapStyle = .round
    connector.lineWidth = rect.width * 0.08
    bodyColor.setStroke()
    connector.stroke()
    connector.lineWidth = rect.width * 0.038
    bodyHighlight.setStroke()
    connector.stroke()

    let bumper = NSBezierPath()
    bumper.move(to: CGPoint(x: headRect.maxX + rect.width * 0.005, y: headRect.minY + headRect.height * 0.16))
    bumper.line(to: CGPoint(x: headRect.maxX + rect.width * 0.045, y: headRect.minY + headRect.height * 0.16))
    bumper.lineCapStyle = .round
    bumper.lineWidth = rect.width * 0.022
    darkGreen.setStroke()
    bumper.stroke()

    for center in [
        CGPoint(x: rect.minX + rect.width * 0.34, y: rect.minY + rect.height * 0.28),
        CGPoint(x: rect.minX + rect.width * 0.54, y: rect.minY + rect.height * 0.28)
    ] {
        let outerRect = CGRect(
            x: center.x - rect.width * 0.07,
            y: center.y - rect.width * 0.07,
            width: rect.width * 0.14,
            height: rect.width * 0.14
        )
        wheelGreen.setFill()
        NSBezierPath(ovalIn: outerRect).fill()

        let innerRect = outerRect.insetBy(dx: rect.width * 0.032, dy: rect.width * 0.032)
        cream.setFill()
        NSBezierPath(ovalIn: innerRect).fill()
    }
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

    let insetRect = rect.insetBy(dx: CGFloat(size) * 0.04, dy: CGFloat(size) * 0.04)
    drawBackground(in: insetRect)
    drawShadowOval(in: insetRect)
    drawTrainSnake(in: insetRect)

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
