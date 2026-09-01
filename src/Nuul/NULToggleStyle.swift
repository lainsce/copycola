import SwiftUI

/// Compact Metro switch used by visible settings controls.
///
/// This mirrors Habito's toggle treatment: a clearly outlined track, a circular
/// thumb, and a short spring when the value changes. The style keeps its
/// intrinsic width so the containing form can decide the control's alignment.
/// Menu toggles intentionally keep their platform-provided menu presentation.
struct NULToggleStyle: ToggleStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        Button(action: { toggle(configuration) }) {
            toggleLabel(configuration)
        }
        .buttonStyle(.plain)
        .accessibilityValue(toggleValue(isOn: configuration.isOn))
        .accessibilityRemoveTraits(.isButton)
        .accessibilityAddTraits(.isToggle)
    }

    private func toggle(_ configuration: Configuration) {
        if reduceMotion {
            configuration.isOn.toggle()
        } else {
            withAnimation(CopycolaColors.controlMotion) {
                configuration.isOn.toggle()
            }
        }
    }

    @ViewBuilder
    private func toggleLabel(_ configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            configuration.label
            toggleTrack(isOn: configuration.isOn)
        }
    }

    private func toggleTrack(isOn: Bool) -> some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            RoundedRectangle(cornerRadius: 999, style: .continuous)
                .fill(isOn ? Color("AccentColor") : Color.primary.opacity(0.05))
                .overlay {
                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                        .strokeBorder(CopycolaColors.controlRule(for: colorScheme), lineWidth: 1)
                }

            RoundedRectangle(cornerRadius: 999, style: .continuous)
                .fill(.white)
                .overlay {
                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                        .strokeBorder(CopycolaColors.controlRule(for: colorScheme), lineWidth: 1)
                }
                .frame(width: 24, height: 24)
                .padding(4)
        }
        .frame(width: 48, height: 32)
        .animation(controlMotion, value: isOn)
    }

    private var controlMotion: Animation? {
        reduceMotion ? nil : CopycolaColors.controlMotion
    }

    private func toggleValue(isOn: Bool) -> String {
        isOn ? "On" : "Off"
    }
}
