import Foundation

enum Waveform {
    case sine
    case triangle
    case pulse
}

struct NoteEvent {
    let frequency: Double
    let start: Double
    let duration: Double
    let amplitude: Double
    let waveform: Waveform
}

enum AudioAsset: String, CaseIterable {
    case eat
    case special
    case pause
    case gameOver = "game_over"
    case navigate
    case confirm
    case menuLoop = "menu_loop"
    case gameplayLoop = "gameplay_loop"
}

let sampleRate = 22_050.0
let masterGain = 0.82

func envelope(position: Double, duration: Double) -> Double {
    let attack = min(0.02, duration * 0.2)
    let release = min(0.09, duration * 0.28)
    if position < attack {
        return attack == 0 ? 1 : position / attack
    }
    if position > duration - release {
        return max(0, (duration - position) / max(release, 0.0001))
    }
    return 1.0
}

func oscillate(_ phase: Double, waveform: Waveform) -> Double {
    switch waveform {
    case .sine:
        return sin(phase)
    case .triangle:
        return (2 / Double.pi) * asin(sin(phase))
    case .pulse:
        return sin(phase) >= 0 ? 0.9 : -0.9
    }
}

func render(duration: Double, events: [NoteEvent]) -> [Int16] {
    let sampleCount = Int(duration * sampleRate)
    return (0 ..< sampleCount).map { index in
        let time = Double(index) / sampleRate
        let value = events.reduce(0.0) { partial, event in
            guard time >= event.start, time <= event.start + event.duration else {
                return partial
            }
            let localTime = time - event.start
            let env = envelope(position: localTime, duration: event.duration)
            let phase = 2 * Double.pi * event.frequency * localTime
            return partial + oscillate(phase, waveform: event.waveform) * event.amplitude * env
        }
        let clamped = max(-1.0, min(1.0, value * masterGain))
        return Int16(clamped * Double(Int16.max))
    }
}

func wavData(from samples: [Int16]) -> Data {
    let channels: UInt16 = 1
    let bitsPerSample: UInt16 = 16
    let byteRate: UInt32 = UInt32(sampleRate) * UInt32(channels) * UInt32(bitsPerSample / 8)
    let blockAlign: UInt16 = channels * bitsPerSample / 8
    let dataSize = UInt32(samples.count * MemoryLayout<Int16>.size)
    let chunkSize = 36 + dataSize

    var data = Data()
    data.append("RIFF".data(using: .ascii)!)
    data.append(contentsOf: withUnsafeBytes(of: chunkSize.littleEndian, Array.init))
    data.append("WAVE".data(using: .ascii)!)
    data.append("fmt ".data(using: .ascii)!)
    data.append(contentsOf: withUnsafeBytes(of: UInt32(16).littleEndian, Array.init))
    data.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian, Array.init))
    data.append(contentsOf: withUnsafeBytes(of: channels.littleEndian, Array.init))
    data.append(contentsOf: withUnsafeBytes(of: UInt32(sampleRate).littleEndian, Array.init))
    data.append(contentsOf: withUnsafeBytes(of: byteRate.littleEndian, Array.init))
    data.append(contentsOf: withUnsafeBytes(of: blockAlign.littleEndian, Array.init))
    data.append(contentsOf: withUnsafeBytes(of: bitsPerSample.littleEndian, Array.init))
    data.append("data".data(using: .ascii)!)
    data.append(contentsOf: withUnsafeBytes(of: dataSize.littleEndian, Array.init))
    samples.forEach { sample in
        data.append(contentsOf: withUnsafeBytes(of: sample.littleEndian, Array.init))
    }
    return data
}

func melodyEvents(notes: [(Double, Double, Double, Waveform)], beat: Double, amplitude: Double) -> [NoteEvent] {
    notes.map { note in
        NoteEvent(
            frequency: note.0,
            start: note.1 * beat,
            duration: note.2 * beat,
            amplitude: amplitude,
            waveform: note.3
        )
    }
}

let menuBeat = 0.34
let menuEvents = melodyEvents(notes: [
    (392, 0, 1.4, .triangle), (523.25, 1.5, 1.2, .sine), (659.25, 3.0, 1.5, .triangle),
    (587.33, 4.8, 1.2, .sine), (523.25, 6.2, 1.2, .triangle), (440, 7.5, 2.0, .sine),
    (392, 9.8, 1.4, .triangle), (523.25, 11.2, 1.2, .sine), (659.25, 12.8, 1.4, .triangle),
    (783.99, 14.4, 1.0, .sine), (659.25, 15.6, 1.6, .triangle)
], beat: menuBeat, amplitude: 0.32) + melodyEvents(notes: [
    (196, 0, 2.4, .pulse), (220, 2.4, 2.4, .pulse), (174.61, 4.8, 2.4, .pulse),
    (146.83, 7.2, 2.4, .pulse), (196, 9.6, 2.4, .pulse), (220, 12.0, 2.4, .pulse), (174.61, 14.4, 2.8, .pulse)
], beat: menuBeat, amplitude: 0.14)

let gameplayBeat = 0.24
let gameplayEvents = melodyEvents(notes: [
    (220, 0, 1, .pulse), (246.94, 1, 1, .pulse), (261.63, 2, 1, .pulse), (293.66, 3, 1, .pulse),
    (329.63, 4, 1, .pulse), (293.66, 5, 1, .pulse), (261.63, 6, 1, .pulse), (246.94, 7, 1, .pulse),
    (220, 8, 1, .pulse), (246.94, 9, 1, .pulse), (293.66, 10, 1, .pulse), (329.63, 11, 1, .pulse),
    (349.23, 12, 1, .pulse), (329.63, 13, 1, .pulse), (293.66, 14, 1, .pulse), (261.63, 15, 1, .pulse),
    (220, 16, 1, .pulse), (246.94, 17, 1, .pulse), (261.63, 18, 1, .pulse), (293.66, 19, 1, .pulse),
    (329.63, 20, 1, .pulse), (392, 21, 1, .pulse), (349.23, 22, 1, .pulse), (293.66, 23, 1, .pulse)
], beat: gameplayBeat, amplitude: 0.22) + melodyEvents(notes: [
    (110, 0, 2, .triangle), (123.47, 2, 2, .triangle), (130.81, 4, 2, .triangle), (146.83, 6, 2, .triangle),
    (110, 8, 2, .triangle), (123.47, 10, 2, .triangle), (146.83, 12, 2, .triangle), (164.81, 14, 2, .triangle),
    (110, 16, 2, .triangle), (123.47, 18, 2, .triangle), (130.81, 20, 2, .triangle), (146.83, 22, 2, .triangle)
], beat: gameplayBeat, amplitude: 0.18)

let assets: [(AudioAsset, Double, [NoteEvent])] = [
    (.eat, 0.18, [
        NoteEvent(frequency: 740, start: 0.00, duration: 0.08, amplitude: 0.50, waveform: .triangle),
        NoteEvent(frequency: 980, start: 0.06, duration: 0.08, amplitude: 0.38, waveform: .sine)
    ]),
    (.special, 0.34, [
        NoteEvent(frequency: 523.25, start: 0.00, duration: 0.12, amplitude: 0.36, waveform: .sine),
        NoteEvent(frequency: 659.25, start: 0.08, duration: 0.12, amplitude: 0.34, waveform: .triangle),
        NoteEvent(frequency: 880.00, start: 0.16, duration: 0.16, amplitude: 0.28, waveform: .sine)
    ]),
    (.pause, 0.22, [
        NoteEvent(frequency: 360, start: 0.00, duration: 0.10, amplitude: 0.34, waveform: .pulse),
        NoteEvent(frequency: 240, start: 0.10, duration: 0.10, amplitude: 0.30, waveform: .triangle)
    ]),
    (.gameOver, 0.55, [
        NoteEvent(frequency: 329.63, start: 0.00, duration: 0.14, amplitude: 0.28, waveform: .triangle),
        NoteEvent(frequency: 261.63, start: 0.12, duration: 0.16, amplitude: 0.28, waveform: .triangle),
        NoteEvent(frequency: 196.00, start: 0.28, duration: 0.22, amplitude: 0.26, waveform: .pulse)
    ]),
    (.navigate, 0.12, [
        NoteEvent(frequency: 640, start: 0.00, duration: 0.06, amplitude: 0.22, waveform: .pulse)
    ]),
    (.confirm, 0.20, [
        NoteEvent(frequency: 440, start: 0.00, duration: 0.08, amplitude: 0.24, waveform: .triangle),
        NoteEvent(frequency: 659.25, start: 0.07, duration: 0.10, amplitude: 0.28, waveform: .sine)
    ]),
    (.menuLoop, 6.0, menuEvents),
    (.gameplayLoop, 6.0, gameplayEvents)
]

let fileManager = FileManager.default
let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
let outputDirectory = currentDirectory.appendingPathComponent("贪吃蛇/Resources/Audio", isDirectory: true)
try fileManager.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

for asset in assets {
    let samples = render(duration: asset.1, events: asset.2)
    let data = wavData(from: samples)
    let url = outputDirectory.appendingPathComponent(asset.0.rawValue).appendingPathExtension("wav")
    try data.write(to: url)
    print("Generated \(url.path)")
}
