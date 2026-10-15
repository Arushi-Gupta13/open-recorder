import AVFoundation
import Foundation
import OSLog
import Observation

struct VoiceGenerationConfig: Codable, Equatable, Hashable, Sendable {
    var speed: Double = 1.0
    var pitch: Double = 1.0
    var model: String = "qwen2.5-tts"

    static let `default` = VoiceGenerationConfig()

    var clamped: VoiceGenerationConfig {
        VoiceGenerationConfig(
            speed: max(0.5, min(2.0, speed)),
            pitch: max(0.5, min(2.0, pitch)),
            model: model
        )
    }
}

@MainActor
@Observable
final class VoiceGeneratorController {
    enum Phase: String {
        case idle
        case checking = "Checking server"
        case generating = "Generating voice"
    }

    private(set) var phase: Phase = .idle
    private(set) var progress: Double?
    private(set) var serverReady = false
    private(set) var error: String?
    private(set) var generatedAudioPath: String?
    var config = VoiceGenerationConfig.default

    private static let logger = Logger(subsystem: "dev.openrecorder.app", category: "VoiceGenerator")
    private static let ttsServerURL = URL(string: "http://localhost:8880")!

    var isBusy: Bool { phase != .idle }
    var canGenerate: Bool { !isBusy && serverReady }

    func checkServer() {
        guard phase == .idle else { return }
        phase = .checking
        error = nil
        Task {
            do {
                let url = Self.ttsServerURL.appendingPathComponent("v1/models")
                var request = URLRequest(url: url)
                request.timeoutInterval = 5
                let (_, response) = try await URLSession.shared.data(for: request)
                if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                    serverReady = true
                } else {
                    serverReady = false
                    error = "TTS server not responding correctly."
                }
            } catch {
                serverReady = false
                self.error = "TTS server not found at localhost:8880. Start the Qwen TTS server first."
            }
            phase = .idle
        }
    }

    func generate(text: String, outputDir: URL) {
        guard canGenerate, !text.isEmpty else { return }
        phase = .generating
        progress = 0
        error = nil
        let cfg = config.clamped

        Task {
            do {
                let url = Self.ttsServerURL.appendingPathComponent("v1/audio/speech")
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.timeoutInterval = 120

                let body: [String: Any] = [
                    "model": cfg.model,
                    "input": text,
                    "voice": "alloy",
                    "speed": cfg.speed,
                    "response_format": "wav"
                ]
                request.httpBody = try JSONSerialization.data(withJSONObject: body)

                let (data, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                    throw VoiceGenError.serverError
                }

                try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
                let outputPath = outputDir.appendingPathComponent("generated-voice-\(UUID().uuidString.prefix(8)).wav")
                try data.write(to: outputPath)

                generatedAudioPath = outputPath.path
                Self.logger.info("Voice generated: \(outputPath.lastPathComponent)")
                progress = 1
                phase = .idle
            } catch {
                self.error = error.localizedDescription
                phase = .idle
                progress = nil
            }
        }
    }

    func generateFromSegments(_ segments: [CaptionSegment], outputDir: URL) {
        let fullText = segments.sorted(by: { $0.start < $1.start }).map(\.text).joined(separator: " ")
        generate(text: fullText, outputDir: outputDir)
    }

    enum VoiceGenError: LocalizedError {
        case serverError
        case noText
        var errorDescription: String? {
            switch self {
            case .serverError: "TTS server returned an error."
            case .noText: "No text to generate voice from."
            }
        }
    }
}
