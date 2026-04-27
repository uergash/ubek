import SwiftUI

/// Editor for the user's quiet-hours window. Notifications scheduled to fire
/// inside this window get pushed out by NotificationService.
@MainActor
struct QuietHoursPickerSheet: View {
    let currentStart: Int
    let currentEnd: Int
    var onSave: (_ start: Int, _ end: Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var start: Int
    @State private var end: Int

    init(currentStart: Int, currentEnd: Int, onSave: @escaping (Int, Int) -> Void) {
        self.currentStart = currentStart
        self.currentEnd = currentEnd
        self.onSave = onSave
        _start = State(initialValue: currentStart)
        _end = State(initialValue: currentEnd)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Starts at", selection: $start) {
                        ForEach(0..<24, id: \.self) { h in
                            Text(format(hour: h)).tag(h)
                        }
                    }
                    Picker("Ends at", selection: $end) {
                        ForEach(0..<24, id: \.self) { h in
                            Text(format(hour: h)).tag(h)
                        }
                    }
                } header: {
                    Text("Quiet hours window")
                } footer: {
                    Text("Notifications scheduled to fire during this window get pushed to the end of the window.")
                }
            }
            .navigationTitle("Quiet hours")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(start, end)
                        dismiss()
                    }
                    .disabled(start == end)
                }
            }
        }
    }

    private func format(hour: Int) -> String {
        if hour == 0 { return "12am" }
        if hour == 12 { return "12pm" }
        if hour < 12 { return "\(hour)am" }
        return "\(hour - 12)pm"
    }
}
