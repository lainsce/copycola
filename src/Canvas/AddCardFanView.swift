import SwiftUI

struct AddCardFanView: View {
    @Binding var isExpanded: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let addCard: (CardKind) -> Void

    var body: some View {
        addButton
            .popover(isPresented: $isExpanded, arrowEdge: .bottom) {
                AddCardPickerView(addCard: selectCard, animation: fanAnimation)
                    .padding(8)
                    .presentationBackground(CopycolaColors.itemSurface)
            }
    }

    private var addButton: some View {
        Button {
            withAnimation(fanAnimation) {
                isExpanded.toggle()
            }
        } label: {
            NULIcon(systemImage: "plus")
                .rotationEffect(.degrees(isExpanded ? 45 : 0))
        }
        .accessibilityLabel(Text(anchorTitle))
        .accessibilityHint(Text("Shows card types"))
        .help(Text(anchorTitle))
        .buttonStyle(NULToolbarButtonStyle(diameter: 38, accented: true))
    }

    private func selectCard(_ kind: CardKind) {
        withAnimation(fanAnimation) {
            isExpanded = false
        }
        addCard(kind)
    }

    private var anchorTitle: LocalizedStringResource {
        isExpanded ? "Close" : "Add Card"
    }

    private var fanAnimation: Animation? {
        reduceMotion ? nil : CopycolaColors.controlMotion
    }
}
