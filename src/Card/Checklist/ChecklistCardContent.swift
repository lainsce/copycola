import SwiftUI

struct ChecklistCardContent: View {
    @Bindable var card: Card

    var body: some View {
        GeometryReader { proxy in
            let metrics = ChecklistCardMetrics(size: proxy.size)

            VStack(alignment: .leading, spacing: metrics.sectionSpacing) {
                ChecklistCardHeader(title: card.checklistTitleValue, metrics: metrics)

                if card.checklistSlots.isEmpty {
                    Spacer(minLength: metrics.sectionSpacing)
                    Text("Add up to 3 checks")
                        .font(CopycolaTypography.body)
                        .foregroundStyle(.secondary)
                } else {
                    Spacer(minLength: metrics.sectionSpacing)
                    VStack(alignment: .leading, spacing: metrics.rowSpacing) {
                        ForEach(card.checklistSlots) { slot in
                            ChecklistRow(
                                text: slot.text,
                                isCompleted: slot.isCompleted,
                                metrics: metrics
                            ) {
                                card.setChecklistCompleted(!slot.isCompleted, at: slot.id)
                            }
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(metrics.inset)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .background {
            RoundedRectangle(cornerRadius: card.cardSize.cornerRadius, style: .continuous)
                .fill(CardSurfaceStyle.item)
        }
        .clipShape(.rect(cornerRadius: card.cardSize.cornerRadius))
        .accessibilityElement(children: .contain)
    }
}

private struct ChecklistCardMetrics {
    let size: CGSize

    var scale: CGFloat {
        max(0.75, min(size.width / CanvasMetrics.cell, size.height / CanvasMetrics.cell))
    }

    var inset: CGFloat { CanvasMetrics.cardContentInset }
    var sectionSpacing: CGFloat { max(8, 10 * scale) }
    var rowSpacing: CGFloat { max(8, 12 * scale) }
    var titleFont: CGFloat { CopycolaTypography.Role.contentBlockTitle.size }
    var bodyFont: CGFloat { CopycolaTypography.Role.body.size }
    var checkSize: CGFloat { max(16, 22 * scale) }
    var checkStroke: CGFloat { max(1.5, 2 * scale) }
}

private struct ChecklistCardHeader: View {
    let title: String
    let metrics: ChecklistCardMetrics

    var body: some View {
        HStack(spacing: metrics.sectionSpacing) {
            Image(systemName: "checklist")
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(Color.accent)
                .accessibilityHidden(true)

            Text(verbatim: title)
                .font(CopycolaTypography.contentBlockTitle)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Spacer(minLength: 0)
        }
    }
}

private struct ChecklistRow: View {
    let text: String
    let isCompleted: Bool
    let metrics: ChecklistCardMetrics
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .firstTextBaseline, spacing: metrics.sectionSpacing) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: metrics.checkSize, weight: .semibold))
                    .foregroundStyle(isCompleted ? Color.accent : .secondary.opacity(0.46))
                    .frame(width: metrics.checkSize, height: metrics.checkSize)

                Text(verbatim: text)
                    .font(CopycolaTypography.body)
                    .foregroundStyle(isCompleted ? .secondary : .primary)
                    .strikethrough(isCompleted, color: .secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 0)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: text))
        .accessibilityValue(Text(isCompleted ? "Completed" : "Not completed"))
        .accessibilityAddTraits(isCompleted ? .isSelected : [])
    }
}
