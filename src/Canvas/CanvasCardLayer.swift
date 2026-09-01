import SwiftUI

/// The interaction surface for cards placed on a CanvasView.
///
/// CanvasView owns board geometry and presentation state; this view owns the repeated card
/// design/gesture/accessibility wiring so the canvas itself can stay focused on orchestration.
struct CanvasCardLayer: View {
    let cards: [Card]
    let selectedCardID: UUID?
    let editingCardID: UUID?
    let draggingCardID: UUID?
    let dragTranslation: CGSize
    let actions: CanvasCardActions

    var body: some View {
        ForEach(cards) { card in
            cardLayer(for: card)
        }
    }

    private func cardLayer(for card: Card) -> some View {
        let dragging = draggingCardID == card.id
        let selected = selectedCardID == card.id
        let extra = dragging ? dragTranslation : .zero
        let renderedSize = CGSize(
            width: max(card.width, card.cardSize.pointSize.width),
            height: max(card.height, card.cardSize.pointSize.height)
        )

        return CardView(
            card: card,
            isSelected: selected,
            isEditing: editingCardID == card.id,
            isDragging: dragging,
            dragTranslation: extra,
            onDelete: { actions.delete(card) },
            onSetSize: { size in actions.setSize(card, size) },
            onBeginEdit: { actions.beginEditing(card) },
            onChooseImage: { actions.chooseImage(card) },
            onCropImageToSubject: { actions.cropImageToSubject(card) },
            onEditLink: { actions.editLink(card) },
            onEditLocation: { actions.editLocation(card) }
        )
        .frame(width: renderedSize.width, height: renderedSize.height)
        .position(
            x: card.x + renderedSize.width / 2 + extra.width,
            y: card.y + renderedSize.height / 2 + extra.height
        )
        .zIndex(cardZIndex(for: card, dragging: dragging, selected: selected))
        .onTapGesture(count: 2) { actions.beginEditing(card) }
        .onTapGesture { actions.select(card) }
        .highPriorityGesture(
            cardDrag(for: card),
            including: editingCardID == card.id ? .subviews : .all
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(card.kind.displayName))
        .accessibilityValue(Text(verbatim: actions.accessibilitySummary(card)))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { actions.select(card) }
        .accessibilityAction(named: Text(card.kind.editActionName)) {
            actions.edit(card)
        }
        .accessibilityAction(named: Text("Move Left")) {
            actions.nudge(card, -Double(CanvasMetrics.module), 0)
        }
        .accessibilityAction(named: Text("Move Right")) {
            actions.nudge(card, Double(CanvasMetrics.module), 0)
        }
        .accessibilityAction(named: Text("Move Up")) {
            actions.nudge(card, 0, -Double(CanvasMetrics.module))
        }
        .accessibilityAction(named: Text("Move Down")) {
            actions.nudge(card, 0, Double(CanvasMetrics.module))
        }
    }

    private func cardZIndex(for card: Card, dragging: Bool, selected: Bool) -> Double {
        Double(card.zIndex) + (dragging ? 100_000 : (selected ? 50_000 : 0))
    }

    private func cardDrag(for card: Card) -> some Gesture {
        DragGesture()
            .onChanged { value in
                actions.dragChanged(card, value.translation)
            }
            .onEnded { value in
                actions.dragEnded(card, value.translation)
            }
    }
}

/// Commands supplied by CanvasView to keep board mutation and card presentation separate.
struct CanvasCardActions {
    let select: (Card) -> Void
    let edit: (Card) -> Void
    let beginEditing: (Card) -> Void
    let delete: (Card) -> Void
    let setSize: (Card, CardSize) -> Void
    let chooseImage: (Card) -> Void
    let cropImageToSubject: (Card) -> Void
    let editLink: (Card) -> Void
    let editLocation: (Card) -> Void
    let accessibilitySummary: (Card) -> String
    let nudge: (Card, Double, Double) -> Void
    let dragChanged: (Card, CGSize) -> Void
    let dragEnded: (Card, CGSize) -> Void
}
