import SwiftUI

/// Compact Metro switch used by visible settings controls.
///
/// This mirrors Habito's toggle treatment: a layered track, a rounded-square
/// thumb with a two-bar handle, and a short spring when the value changes.
/// The style keeps its intrinsic width so the containing form can decide the
/// control's alignment.
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
        HStack(spacing: CopycolaColors.switchLabelSpacing) {
            toggleTrack(isOn: configuration.isOn)
            configuration.label
        }
        // The switch action owns the whole laid-out control, not just the
        // track or its label glyph.
        .contentShape(.rect(cornerRadius: CopycolaColors.switchCornerRadius))
    }

    private func toggleTrack(isOn: Bool) -> some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            RoundedRectangle(cornerRadius: CopycolaColors.switchCornerRadius, style: .continuous)
                .fill(isOn ? CopycolaColors.accent : CopycolaColors.controlRule(for: colorScheme))

            RoundedRectangle(cornerRadius: CopycolaColors.switchCornerRadius, style: .continuous)
                .fill(.white)
                .overlay {
                    HStack(spacing: 4) {
                        Rectangle().frame(width: 2, height: 12)
                        Rectangle().frame(width: 2, height: 12)
                    }
                    .foregroundStyle(Color.black.opacity(0.2))
                    .frame(width: 8, height: 12)
                }
                .frame(width: CopycolaColors.switchKnobSize, height: CopycolaColors.switchKnobSize)
                .padding(CopycolaColors.switchInset)
        }
        .frame(width: CopycolaColors.switchWidth, height: CopycolaColors.switchHeight)
        .animation(controlMotion, value: isOn)
    }

    private var controlMotion: Animation? {
        reduceMotion ? nil : CopycolaColors.controlMotion
    }

    private func toggleValue(isOn: Bool) -> String {
        isOn ? "On" : "Off"
    }
}
