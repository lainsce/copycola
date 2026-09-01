import AVFoundation
import Combine
import os
import Speech
import WhisperKit

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

private final class SpeechRequestBox: @unchecked Sendable {
    nonisolated(unsafe) let request: SFSpeechAudioBufferRecognitionRequest

    init(_ request: SFSpeechAudioBufferRecognitionRequest) {
        self.request = request
    }
}

private final class SpeechSamples: @unchecked Sendable {
    private let state = OSAllocatedUnfairLock(initialState: [Float]())
    private let rate = OSAllocatedUnfairLock(initialState: Double(WhisperKit.sampleRate))

    func reset() {
        state.withLock { $0.removeAll(keepingCapacity: true) }
    }

    nonisolated func append(_ buffer: AVReadOnlyAudioPCMBuffer) {
        guard case .float(let values) = buffer.channelData(0) else { return }
        rate.withLock { current in if current == Double(WhisperKit.sampleRate) { current = buffer.format.sampleRate } }
        let copy = values.withUnsafeBufferPointer { Array($0) }
        state.withLock { $0.append(contentsOf: copy) }
    }

    func snapshot() -> [Float] {
        let input = state.withLock { $0 }
        let sourceRate = rate.withLock { $0 }
        guard sourceRate > 0, sourceRate != Double(WhisperKit.sampleRate), input.count > 1 else { return input }
        let outputCount = max(1, Int(Double(input.count) * Double(WhisperKit.sampleRate) / sourceRate))
        return (0..<outputCount).map { index in
            let position = Double(index) * sourceRate / Double(WhisperKit.sampleRate)
            let lower = min(input.count - 1, Int(position))
            let upper = min(input.count - 1, lower + 1)
            let fraction = Float(position - Double(lower))
            return input[lower] + (input[upper] - input[lower]) * fraction
        }
    }
}

@MainActor
final class CanvasVoiceRecorder: ObservableObject {
    @Published private(set) var bass: CGFloat = 0.18
    @Published private(set) var mid: CGFloat = 0.28
    @Published private(set) var treble: CGFloat = 0.20
    @Published private(set) var transcript = ""
    @Published private(set) var finalTranscript = ""

    private var engine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    // Use the user's current language model so recognition stays open-ended and
    // follows the language they use for arbitrary names and concepts.
    private let speechRecognizer = SFSpeechRecognizer(locale: .current)
    private var acceptsTranscription = false
    private let samples = SpeechSamples()

    func start() {
        guard !engine.isRunning else { return }
        resetRecordingState()
        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
            requestSpeechAuthorization()
            return
        }

        startAuthorizedCapture()
    }

    private func resetRecordingState() {
        acceptsTranscription = true
        samples.reset()
        transcript = ""
        finalTranscript = ""
    }

    private func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            guard status == .authorized else { return }
            Task { @MainActor [weak self] in
                self?.start()
            }
        }
    }

    private func startAuthorizedCapture() {
        guard let speechRecognizer, speechRecognizer.isAvailable else { return }

        let input = engine.inputNode
        let analysisState = VoiceAnalysisState()
        input.removeTap(onBus: 0)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.taskHint = .dictation
        request.contextualStrings = [
            "canvas", "card", "note", "image", "link", "map", "location"
        ]
        let requestBox = SpeechRequestBox(request)
        recognitionRequest = request
        recognitionTask?.cancel()
        installRecognitionTask(using: speechRecognizer, request: request)

        do {
            try installAudioTap(on: input, requestBox: requestBox, analysisState: analysisState)
            try engine.start()
        } catch {
            stop()
        }
    }

    private func installRecognitionTask(
        using speechRecognizer: SFSpeechRecognizer,
        request: SFSpeechAudioBufferRecognitionRequest
    ) {
        recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, _ in
            guard let result else { return }
            let transcript = result.bestTranscription.formattedString
            let isFinal = result.isFinal
            Task { @MainActor [weak self] in
                guard let self, self.acceptsTranscription, !transcript.isEmpty else { return }
                self.transcript = transcript
                if isFinal {
                    self.finalTranscript = transcript
                    self.recognitionTask = nil
                    self.recognitionRequest = nil
                }
            }
        }
    }

    private func installAudioTap(
        on input: AVAudioInputNode,
        requestBox: SpeechRequestBox,
        analysisState: VoiceAnalysisState
    ) throws {
        // Let AVAudioEngine negotiate the hardware format. Supplying outputFormat here
        // can trigger an AVFAudio assertion when the input route changes at launch.
        try input.installAudioTap(onBus: 0, bufferSize: 512, format: nil) { [weak self] buffer, _ in
            self?.samples.append(buffer)
            if let speechBuffer = Self.mutableBuffer(copying: buffer) {
                requestBox.request.append(speechBuffer)
            }
            guard let values = analysisState.analyze(buffer) else { return }
            Task { @MainActor [weak self] in
                self?.bass = max(0.12, values.0)
                self?.mid = max(0.12, values.1)
                self?.treble = max(0.12, values.2)
            }
        }
    }

    func stop() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        engine = AVAudioEngine()
        let recordedSamples = samples.snapshot()
        Task { @MainActor [weak self] in
            guard let self, self.acceptsTranscription else { return }
            if let transcription = await CanvasAIRecon.shared.transcribe(samples: recordedSamples),
               !transcription.isEmpty {
                self.transcript = transcription
                self.finalTranscript = transcription
            }
        }
        bass = 0.18
        mid = 0.28
        treble = 0.20
    }

    func clearTranscript() {
        acceptsTranscription = false
        transcript = ""
        finalTranscript = ""
    }

    private nonisolated static func mutableBuffer(copying buffer: AVReadOnlyAudioPCMBuffer) -> AVAudioPCMBuffer? {
        guard let copy = AVAudioPCMBuffer(
            pcmFormat: buffer.format,
            frameCapacity: AVAudioFrameCount(buffer.frameLength)
        ) else { return nil }

        copy.frameLength = AVAudioFrameCount(buffer.frameLength)
        guard let destination = copy.floatChannelData else { return nil }
        let channelCount = Int(buffer.format.channelCount)
        for index in 0..<channelCount {
            guard case .float(let samples) = buffer.channelData(index) else { continue }
            samples.withUnsafeBufferPointer { source in
                guard let sourceData = source.baseAddress else { return }
                memcpy(
                    destination[index],
                    sourceData,
                    Int(buffer.frameLength) * MemoryLayout<Float>.size
                )
            }
        }
        return copy
    }
}
