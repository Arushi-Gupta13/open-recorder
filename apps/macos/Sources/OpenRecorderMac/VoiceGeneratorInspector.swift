import AppKit
import SwiftUI

struct VoiceGeneratorInspector: View {
    @State private var controller = VoiceGeneratorController()
    var edits: TimelineEditDriver

    private var track: CaptionTrack? { edits.snapshot.captions }

    var body: some View {
        InspectorGroup(title: "Voice Generation", symbolName: "waveform.and.mic", showsTopDivider: false) {
            HStack {
                Circle()
                    .fill(controller.serverReady ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                Text(controller.serverReady ? "TTS server connected" : "TTS server offline")
                    .font(.caption)
                Spacer()
                Button("Check") { controller.checkServer() }
                    .disabled(controller.isBusy)
                    .controlSize(.small)
            }

            if !controller.serverReady {
                Text("Start a local TTS server (Qwen2.5-TTS) on port 8880. The model runs locally and is not bundled with the app.")
                    .font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if controller.isBusy {
                HStack {
                    ProgressView().controlSize(.small)
                    Text(controller.phase.rawValue).font(.caption)
                }
            }

            if let error = controller.error {
                Text(error).font(.caption).foregroundStyle(.red)
            }

            InspectorSlider(title: "Speed", valueText: String(format: "%.1f×", controller.config.speed),
                value: $controller.config.speed, range: 0.5...2.0, step: 0.1, onEditingChanged: { _ in })
            InspectorSlider(title: "Pitch", valueText: String(format: "%.1f×", controller.config.pitch),
                value: $controller.config.pitch, range: 0.5...2.0, step: 0.1, onEditingChanged: { _ in })

            if let track, !track.segments.isEmpty {
                Button("Generate from transcript") {
                    let supportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                        .appendingPathComponent("OpenRecorder/generated-audio", isDirectory: true)
                    controller.generateFromSegments(track.segments, outputDir: supportDir)
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .disabled(!controller.canGenerate)
            } else {
                Text("Generate captions first to use voice generation.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            if let path = controller.generatedAudioPath {
                HStack {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    Text("Audio generated").font(.caption)
                    Spacer()
                    Button("Show in Finder") {
                        NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
                    }.controlSize(.small)
                }
            }
        }
        .onAppear { controller.checkServer() }
    }
}
