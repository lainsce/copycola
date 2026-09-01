import Foundation
@preconcurrency import WhisperKit

/// Shared on-device speech model used by every prompt entry path.
final class CanvasAIRecon {
    static let shared = CanvasAIRecon()

    private nonisolated(unsafe) var whisper: WhisperKit?

    @MainActor func interpret(_ prompt: String) -> CanvasPromptInterpretation {
        CanvasPromptInterpreter.interpret(prompt)
    }

    func transcribe(samples: [Float]) async -> String? {
        guard samples.count >= 1_600 else { return nil }

        do {
            let whisper = try await configuredWhisper()
            // The default WhisperKit configuration pre-fills English and disables
            // language detection. Let the model detect Portuguese (including pt-BR)
            // or another language from the actual audio instead.
            let options = DecodingOptions(usePrefillPrompt: false, detectLanguage: true)
            let batches = await whisper.transcribe(audioArrays: [samples], decodeOptions: options)
            return transcriptionText(from: batches)
        } catch {
            return nil
        }
    }

    private func configuredWhisper() async throws -> WhisperKit {
        if let whisper { return whisper }
        let configured = try await WhisperKit(WhisperKitConfig(model: "base"))
        whisper = configured
        return configured
    }

    private func transcriptionText(from batches: [[TranscriptionResult]?]) -> String {
        batches
            .compactMap { $0 }
            .flatMap { $0 }
            .map(\.text)
            .joined(separator: " ")
    }
}
