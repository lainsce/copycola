import SwiftUI

/// A compact, bottom-centered command surface for turning a thought into a card.
struct CanvasPromptComposer: View {
    @Binding var text: String
    let submit: () -> Void
    @ObservedObject var recorder: CanvasVoiceRecorder

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var isFocused: Bool
    @State private var isListening = false
    @State private var recordingStartedAt = Date()

    var body: some View {
        VStack(spacing: 8) {
            if !recorder.transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                transcriptionComposer
            }

            Group {
                if isListening { listeningComposer } else { idleComposer }
            }
            .frame(width: 300, height: 40)
            .clipShape(Capsule())
        }
        .animation(reduceMotion ? nil : .snappy, value: isListening)
        .onAppear { isFocused = false }
        .onChange(of: recorder.transcript) { _, transcript in
            guard isListening else { return }
            text = transcript
        }
        .onChange(of: recorder.finalTranscript) { _, transcript in
            guard !transcript.isEmpty else { return }
            text = transcript
        }
    }

    private var transcriptionComposer: some View {
        HStack(spacing: 8) {
            Text(verbatim: recorder.transcript)
                .font(CopycolaTypography.text(12))
                .foregroundStyle(colorScheme == .dark ? .white : .black)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: submitIfNeeded) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 12, weight: .bold))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .foregroundStyle(colorScheme == .dark ? Color.black : Color.white)
            .background(
                colorScheme == .dark ? Color(hex: "D39224") : Color(hex: "D9921E"),
                in: Circle()
            )
            .accessibilityLabel(Text("Send transcription"))
            .help(Text("Send transcription"))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .frame(width: 300, alignment: .leading)
        .background(colorScheme == .dark ? Color(hex: "171717") : Color.white, in: RoundedRectangle(cornerRadius: 12))
    }

    private var idleComposer: some View {
        HStack(spacing: 0) {
            Button {
                beginListening()
            } label: {
                Image(systemName: "mic.fill")
                    .font(.system(size: 13, weight: .bold))
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)
            .foregroundStyle(colorScheme == .dark ? .white : .black)
            .accessibilityLabel(Text("Voice input"))
            .help(Text("Voice input"))

            ZStack {
                TextField("", text: $text)
                .textFieldStyle(.plain)
                .font(CopycolaTypography.text(12))
                .multilineTextAlignment(.leading)
                .tint(Color.accent)
                .focused($isFocused)
                    .onSubmit(submitIfNeeded)
                    .accessibilityLabel(Text("Describe the card to add"))

                if text.isEmpty {
                    Text("Add a thought…")
                        .font(CopycolaTypography.text(12))
                        .foregroundStyle(.secondary)
                        .allowsHitTesting(false)
                }
            }

            Button(action: submitIfNeeded) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 12, weight: .bold))
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)
            .foregroundStyle(colorScheme == .dark ? Color.black : Color.white)
            .background(colorScheme == .dark ? Color(hex: "D39224") : Color(hex: "D9921E"), in: Circle())
            .padding(.trailing, 4)
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .accessibilityLabel(Text("Create card"))
            .help(Text("Create card"))
        }
        .background(colorScheme == .dark ? Color(hex: "171717") : Color.white)
    }

    private var listeningComposer: some View {
        Button(action: stopListening) {
            HStack(spacing: 0) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 13, weight: .bold))
                    .frame(width: 40, height: 40)
                Spacer(minLength: 0)
                HStack(spacing: 3) {
                    waveformBar(recorder.bass)
                    waveformBar(recorder.mid)
                    waveformBar(recorder.treble)
                }
                .frame(width: 24, height: 40)
                Spacer(minLength: 0)
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    Text(elapsedTime(from: context.date))
                        .font(CopycolaTypography.text(12, weight: .bold))
                        .monospacedDigit()
                        .frame(width: 38, alignment: .leading)
                }
                .padding(.trailing, 14)
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(.black)
        .background(colorScheme == .dark ? Color(hex: "D39224") : Color(hex: "D9921E"))
        .accessibilityLabel(Text("Stop voice input"))
        .help(Text("Stop voice input"))
    }

    private func beginListening() {
        recordingStartedAt = .now
        isListening = true
        recorder.start()
    }

    private func stopListening() {
        isListening = false
        recorder.stop()
    }

    private func elapsedTime(from date: Date) -> String {
        let elapsed = max(0, Int(date.timeIntervalSince(recordingStartedAt)))
        return String(format: "0:%02d", elapsed)
    }

    private func waveformBar(_ level: CGFloat) -> some View {
        Capsule()
            .fill(.black)
            .frame(width: 2, height: max(5, min(18, level * 22)))
    }

    private func submitIfNeeded() {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isListening = false
        recorder.stop()
        submit()
        text = ""
        recorder.clearTranscript()
        isFocused = true
    }
}
