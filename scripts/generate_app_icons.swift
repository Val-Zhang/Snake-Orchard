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
        makeColor(red: 9, green: 21, blue: 34),
        makeColor(red: 12, green: 62, blue: 58),
        makeColor(red: 35, green: 120, blue: 80)
    ])!
    gradient.draw(in: path, angle: -45)

    let glowRect = rect.insetBy(dx: rect.width * 0.04, dy: rect.height * 0.04)
    let glowPath = roundedRect(glowRect, radius: rect.width * 0.20)
    makeColor(red: 255, green: 255, blue: 255, alpha: 0.05).setFill()
    glowPath.fill()

    let vignette = NSGradient(colors: [
        makeColor(red: 0, green: 0, blue: 0, alpha: 0.00),
        makeColor(red: 0, green: 0, blue: 0, alpha: 0.26)
    ])!
    vignette.draw(in: path, relativeCenterPosition: NSPoint(x: 0.0, y: 0.4))

    makeColor(red: 255, green: 255, blue: 255, alpha: 0.12).setStroke()
    path.lineWidth = rect.width * 0.018
    path.stroke()
}

func drawGrid(in rect: CGRect) {
    let gridPath = NSBezierPath()
    gridPath.lineWidth = max(1, rect.width * 0.006)

    let columns = 5
    let rows = 5
    for index in 1..<columns {
        let x = rect.minX + CGFloat(index) * rect.width / CGFloat(columns)
        gridPath.move(to: CGPoint(x: x, y: rect.minY))
        gridPath.line(to: CGPoint(x: x, y: rect.maxY))
    }
    for index in 1..<rows {
        let y = rect.minY + CGFloat(index) * rect.height / CGFloat(rows)
        gridPath.move(to: CGPoint(x: rect.minX, y: y))
        gridPath.line(to: CGPoint(x: rect.maxX, y: y))
    }

    makeColor(red: 255, green: 255, blue: 255, alpha: 0.07).setStroke()
    gridPath.stroke()
}

func drawSnake(in rect: CGRect) {
    let body = NSBezierPath()
    body.move(to: CGPoint(x: rect.minX + rect.width * 0.24, y: rect.minY + rect.height * 0.22))
    body.curve(
        to: CGPoint(x: rect.minX + rect.width * 0.70, y: rect.minY + rect.height * 0.74),
        controlPoint1: CGPoint(x: rect.minX + rect.width * 0.16, y: rect.minY + rect.height * 0.54),
        controlPoint2: CGPoint(x: rect.minX + rect.width * 0.46, y: rect.minY + rect.height * 0.95)
    )
    body.curve(
        to: CGPoint(x: rect.minX + rect.width * 0.52, y: rect.minY + rect.height * 0.56),
        controlPoint1: CGPoint(x: rect.minX + rect.width * 0.82, y: rect.minY + rect.height * 0.70),
        controlPoint2: CGPoint(x: rect.minX + rect.width * 0.70, y: rect.minY + rect.height * 0.56)
    )

    body.lineCapStyle = .round
    body.lineJoinStyle = .round
    body.lineWidth = rect.width * 0.14
    makeColor(red: 58, green: 193, blue: 97).setStroke()
    body.stroke()

    body.lineWidth = rect.width * 0.08
    makeColor(red: 137, green: 245, blue: 159, alpha: 0.95).setStroke()
    body.stroke()

    let headRect = CGRect(
        x: rect.minX + rect.width * 0.58,
        y: rect.minY + rect.height * 0.64,
        width: rect.width * 0.23,
        height: rect.height * 0.18
    )
    let headPath = roundedRect(headRect, radius: rect.width * 0.09)
    makeColor(red: 97, green: 235, blue: 118).setFill()
    headPath.fill()

    makeColor(red: 22, green: 58, blue: 33, alpha: 0.35).setStroke()
    headPath.lineWidth = rect.width * 0.012
    headPath.stroke()

    let leftEye = NSBezierPath(ovalIn: CGRect(
        x: headRect.minX + headRect.width * 0.24,
        y: headRect.minY + headRect.height * 0.54,
        width: headRect.width * 0.12,
        height: headRect.width * 0.12
    ))
    let rightEye = NSBezierPath(ovalIn: CGRect(
        x: headRect.minX + headRect.width * 0.60,
        y: headRect.minY + headRect.height * 0.54,
        width: headRect.width * 0.12,
        height: headRect.width * 0.12
    ))
    NSColor.black.setFill()
    leftEye.fill()
    rightEye.fill()

    let tongue = NSBezierPath()
    tongue.move(to: CGPoint(x: headRect.maxX - rect.width * 0.006, y: headRect.midY - rect.height * 0.01))
    tongue.line(to: CGPoint(x: headRect.maxX + rect.width * 0.07, y: headRect.midY + rect.height * 0.01))
    tongue.lineCapStyle = .round
    tongue.lineWidth = rect.width * 0.016
    makeColor(red: 255, green: 91, blue: 112).setStroke()
    tongue.stroke()
}

func drawApple(in rect: CGRect) {
    let appleCenter = CGPoint(x: rect.minX + rect.width * 0.76, y: rect.minY + rect.height * 0.28)
    let appleRadius = rect.width * 0.12

    let leftLobe = NSBezierPath(ovalIn: CGRect(
        x: appleCenter.x - appleRadius * 1.15,
        y: appleCenter.y - appleRadius * 0.55,
        width: appleRadius * 1.3,
        height: appleRadius * 1.45
    ))
    let rightLobe = NSBezierPath(ovalIn: CGRect(
        x: appleCenter.x - appleRadius * 0.15,
        y: appleCenter.y - appleRadius * 0.55,
        width: appleRadius * 1.3,
        height: appleRadius * 1.45
    ))
    let bottom = NSBezierPath(ovalIn: CGRect(
        x: appleCenter.x - appleRadius,
        y: appleCenter.y - appleRadius * 0.90,
        width: appleRadius * 2.0,
        height: appleRadius * 1.7
    ))

    makeColor(red: 238, green: 69, blue: 72).setFill()
    leftLobe.fill()
    rightLobe.fill()
    bottom.fill()

    let highlight = NSBezierPath(ovalIn: CGRect(
        x: appleCenter.x - appleRadius * 0.72,
        y: appleCenter.y + appleRadius * 0.12,
        width: appleRadius * 0.46,
        height: appleRadius * 0.72
    ))
    makeColor(red: 255, green: 255, blue: 255, alpha: 0.28).setFill()
    highlight.fill()

    let stem = NSBezierPath()
    stem.move(to: CGPoint(x: appleCenter.x + appleRadius * 0.02, y: appleCenter.y + appleRadius * 1.02))
    stem.curve(
        to: CGPoint(x: appleCenter.x + appleRadius * 0.18, y: appleCenter.y + appleRadius * 1.44),
        controlPoint1: CGPoint(x: appleCenter.x + appleRadius * 0.02, y: appleCenter.y + appleRadius * 1.16),
        controlPoint2: CGPoint(x: appleCenter.x + appleRadius * 0.12, y: appleCenter.y + appleRadius * 1.34)
    )
    stem.lineCapStyle = .round
    stem.lineWidth = rect.width * 0.022
    makeColor(red: 114, green: 70, blue: 35).setStroke()
    stem.stroke()

    let leaf = NSBezierPath()
    leaf.move(to: CGPoint(x: appleCenter.x + appleRadius * 0.12, y: appleCenter.y + appleRadius * 1.22))
    leaf.curve(
        to: CGPoint(x: appleCenter.x + appleRadius * 0.78, y: appleCenter.y + appleRadius * 1.02),
        controlPoint1: CGPoint(x: appleCenter.x + appleRadius * 0.48, y: appleCenter.y + appleRadius * 1.52),
        controlPoint2: CGPoint(x: appleCenter.x + appleRadius * 0.86, y: appleCenter.y + appleRadius * 1.22)
    )
    leaf.curve(
        to: CGPoint(x: appleCenter.x + appleRadius * 0.12, y: appleCenter.y + appleRadius * 1.22),
        controlPoint1: CGPoint(x: appleCenter.x + appleRadius * 0.54, y: appleCenter.y + appleRadius * 0.82),
        controlPoint2: CGPoint(x: appleCenter.x + appleRadius * 0.24, y: appleCenter.y + appleRadius * 0.96)
    )
    makeColor(red: 59, green: 177, blue: 95).setFill()
    leaf.fill()
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
    drawGrid(in: insetRect.insetBy(dx: insetRect.width * 0.08, dy: insetRect.height * 0.08))
    drawSnake(in: insetRect)
    drawApple(in: insetRect)

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
