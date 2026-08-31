import Foundation
import WhisperKit

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
            if whisper == nil {
                whisper = try await WhisperKit(
                    WhisperKitConfig(model: "base")
                )
            }
            guard let whisper else { return nil }
            // The default WhisperKit configuration pre-fills English and disables
            // language detection. Let the model detect Portuguese (including pt-BR)
            // or another language from the actual audio instead.
            let options = DecodingOptions(usePrefillPrompt: false, detectLanguage: true)
            let batches = await whisper.transcribe(audioArrays: [samples], decodeOptions: options)
            return batches.first??.map(\.text).joined(separator: " ")
        } catch {
            return nil
        }
    }
}
