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
        Button {
            if reduceMotion {
                configuration.isOn.toggle()
            } else {
                withAnimation(CopycoaColors.controlMotion) {
                    configuration.isOn.toggle()
                }
            }
        } label: {
            HStack(spacing: 8) {
                configuration.label

                ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                        .fill(
                            configuration.isOn
                                ? Color("AccentColor")
                                : Color.primary.opacity(0.05)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 999, style: .continuous)
                                .strokeBorder(CopycoaColors.controlRule(for: colorScheme), lineWidth: 1)
                        }

                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                        .fill(.white)
                        .overlay {
                            RoundedRectangle(cornerRadius: 999, style: .continuous)
                                .strokeBorder(CopycoaColors.controlRule(for: colorScheme), lineWidth: 1)
                        }
                        .frame(width: 24, height: 24)
                        .padding(4)
                }
                .frame(width: 48, height: 32)
                .animation(
                    reduceMotion ? nil : CopycoaColors.controlMotion,
                    value: configuration.isOn
                )
            }
        }
        .buttonStyle(.plain)
        .accessibilityValue(configuration.isOn ? "On" : "Off")
        .accessibilityRemoveTraits(.isButton)
        .accessibilityAddTraits(.isToggle)
    }
}
