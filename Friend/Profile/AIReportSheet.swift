import SwiftUI

/// Sheet shown when the user reports a piece of AI-generated output.
/// Required for App Store compliance with generative-AI guidelines.
struct AIReportSheet: View {
    let kind: SupabaseService.AIReportKind
    let content: String
    let personId: UUID?

    @Environment(\.dismiss) private var dismiss
    @State private var reason: String = ""
    @State private var isSubmitting = false
    @State private var didSubmit = false

    var body: some View {
        NavigationStack {
            Form {
                Section("What's wrong with this output?") {
                    TextField(
                        "It's inaccurate, off-tone, or inappropriate…",
                        text: $reason,
                        axis: .vertical
                    )
                    .lineLimit(3...6)
                }
                Section {
                    Text(content)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.muted)
                } header: {
                    Text("Reported content")
                }
                if didSubmit {
                    Section {
                        Label("Thanks — we'll review.", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
            }
            .navigationTitle("Report AI output")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSubmitting ? "Sending…" : "Submit") {
                        Task { await submit() }
                    }
                    .disabled(isSubmitting || didSubmit)
                }
            }
        }
    }

    private func submit() async {
        isSubmitting = true
        defer { isSubmitting = false }
        try? await SupabaseService.shared.reportAIContent(
            kind: kind,
            content: content,
            reason: reason.isEmpty ? nil : reason,
            personId: personId
        )
        didSubmit = true
        try? await Task.sleep(nanoseconds: 700_000_000)
        dismiss()
    }
}
