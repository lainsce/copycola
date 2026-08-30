import SwiftUI

/// Edits the event data shown by a Calendar card. Draft state keeps Cancel genuinely reversible.
struct CalendarEditorSheet: View {
    @Bindable var card: Card
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var dateKind: CalendarDateKind
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var eventTitle: String
    @State private var recurrenceLabel: String

    init(card: Card, onSave: @escaping () -> Void = {}) {
        self.card = card
        self.onSave = onSave
        _dateKind = State(initialValue: card.calendarDateKind)
        _startDate = State(initialValue: card.calendarStartDateValue)
        _endDate = State(initialValue: card.calendarEndDateValue)
        _eventTitle = State(initialValue: card.calendarEventTitleValue)
        _recurrenceLabel = State(initialValue: card.calendarRecurrenceLabelValue)
    }

    var body: some View {
        Form {
            Section {
                NULFormRow("Date type") {
                    NULSegmentedPicker(
                        selection: $dateKind,
                        options: CalendarDateKind.allCases
                    ) { kind in
                        Label(kind.displayName, systemImage: kind.systemImage)
                    }
                }
            } header: {
                Text("Calendar")
            }

            Section("When") {
                NULFormRow(dateKind == .dateRange ? "Starts" : "Date and time") {
                    DatePicker(
                        "",
                        selection: $startDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .labelsHidden()
                    .padding(.horizontal, 8)
                    .frame(minWidth: 210, minHeight: 36, alignment: .leading)
                    .modifier(NULFieldModifier())
                    .accessibilityLabel(dateKind == .dateRange ? "Starts" : "Date and time")
                }

                if dateKind == .dateRange {
                    NULFormRow("Ends") {
                        DatePicker(
                            "",
                            selection: $endDate,
                            in: startDate...,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .labelsHidden()
                        .padding(.horizontal, 8)
                        .frame(minWidth: 210, minHeight: 36, alignment: .leading)
                        .modifier(NULFieldModifier())
                        .accessibilityLabel("Ends")
                    }
                }
            }

            Section("Details") {
                NULFormRow("Event title") {
                    TextField("", text: $eventTitle, prompt: Text("Event"))
                        .textFieldStyle(.plain)
                        .textFieldStyle(NULTextFieldStyle())
                        .accessibilityLabel("Event title")
                }

                if dateKind == .recurring {
                    NULFormRow("Repeat label") {
                        TextField("", text: $recurrenceLabel, prompt: Text("Weekly"))
                            .textFieldStyle(.plain)
                            .textFieldStyle(NULTextFieldStyle())
                            .accessibilityLabel("Repeat label")
                    }
                }
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(CopycoaColors.itemSurface, in: RoundedRectangle(cornerRadius: CopycoaColors.largeSurfaceRadius, style: .continuous))
        .frame(width: 540, height: dateKind == .dateRange ? 430 : 390)
        .padding(.top, 8)
        .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: dismiss.callAsFunction)
                        .buttonStyle(NULButtonStyle(kind: .neutral))
                }
                .sharedBackgroundVisibility(.hidden)
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .buttonStyle(NULButtonStyle(kind: .primary))
                    .keyboardShortcut(.defaultAction)
            }
            .sharedBackgroundVisibility(.hidden)
        }
        .onChange(of: startDate) { _, newValue in
            if endDate < newValue {
                endDate = newValue.addingTimeInterval(24 * 60 * 60)
            }
        }
    }

    private func save() {
        card.calendarDateKind = dateKind
        card.calendarStartDateValue = startDate
        card.calendarEndDateValue = max(endDate, startDate)
        card.calendarEventTitleValue = eventTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Event"
            : eventTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        card.calendarRecurrenceLabelValue = recurrenceLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Weekly"
            : recurrenceLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        onSave()
        dismiss()
    }
}
