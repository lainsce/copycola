import AVFoundation
import Combine
import os

private final class VoiceAnalysisState: @unchecked Sendable {
    private struct FilterState {
        var lowPass: Float = 0
        var previousSample: Float = 0
    }

    private let state = OSAllocatedUnfairLock(initialState: FilterState())

    nonisolated func analyze(_ buffer: AVReadOnlyAudioPCMBuffer) -> (CGFloat, CGFloat, CGFloat)? {
        guard case .float(let samples) = buffer.channelData(0), buffer.frameLength > 0 else { return nil }
        let count = Int(buffer.frameLength)

        return state.withLock { state in
            var lowEnergy: Float = 0
            var midEnergy: Float = 0
            var highEnergy: Float = 0

            for index in 0..<count {
                let sample = samples[index]
                state.lowPass += 0.018 * (sample - state.lowPass)
                lowEnergy += abs(state.lowPass)
                midEnergy += abs(sample - state.lowPass)
                highEnergy += abs(sample - state.previousSample)
                state.previousSample = sample
            }

            let divisor = max(Float(count), 1)
            return (
                min(1, CGFloat(lowEnergy / divisor) * 10),
                min(1, CGFloat(midEnergy / divisor) * 7),
                min(1, CGFloat(highEnergy / divisor) * 4)
            )
        }
    }
}

@MainActor
final class CanvasVoiceRecorder: ObservableObject {
    @Published private(set) var bass: CGFloat = 0.18
    @Published private(set) var mid: CGFloat = 0.28
    @Published private(set) var treble: CGFloat = 0.20

    private var engine = AVAudioEngine()

    func start() {
        guard !engine.isRunning else { return }
        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        let analysisState = VoiceAnalysisState()
        input.removeTap(onBus: 0)
        do {
            try input.installAudioTap(onBus: 0, bufferSize: 512, format: format) { [weak self] buffer, _ in
                guard let values = analysisState.analyze(buffer) else { return }
                Task { @MainActor [weak self] in
                    self?.bass = max(0.12, values.0)
                    self?.mid = max(0.12, values.1)
                    self?.treble = max(0.12, values.2)
                }
            }
            try engine.start()
        } catch {
            stop()
        }
    }

    func stop() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        engine = AVAudioEngine()
        bass = 0.18
        mid = 0.28
        treble = 0.20
    }
}
