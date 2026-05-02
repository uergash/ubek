import SwiftUI
import UIKit

@MainActor
struct AddNoteView: View {
    @State private var viewModel: AddNoteViewModel
    @Environment(\.dismiss) private var dismiss
    /// Called when the user successfully completes the save+facts flow,
    /// passing the primary (first-selected) person the note was saved against.
    var onSaved: (Person) -> Void

    init(person: Person, onSaved: @escaping (Person) -> Void) {
        _viewModel = State(initialValue: AddNoteViewModel(person: person))
        self.onSaved = onSaved
    }

    init(people: [Person], onSaved: @escaping (Person) -> Void) {
        _viewModel = State(initialValue: AddNoteViewModel(people: people))
        self.onSaved = onSaved
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                personHeader
                Divider().background(Color.hairline)
                Group {
                    switch viewModel.mode {
                    case .compose: composeMode
                    case .recording: VoiceCaptureView(speech: viewModel.speech) { viewModel.stopRecording() }
                    case .extracting: extractingMode
                    case .facts: FactExtractionView(viewModel: viewModel) {
                        hideKeyboard()
                        Task {
                            await viewModel.confirmFacts()
                            onSaved(viewModel.person)
                            dismiss()
                        }
                    }
                    }
                }
                .frame(maxHeight: .infinity)
            }
        }
        .task { await viewModel.prepare() }
    }

    private var topBar: some View {
        HStack {
            Button("Cancel") { dismiss() }
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.muted)
            Spacer()
            Text("New note").font(.system(size: 15, weight: .semibold))
            Spacer()
            Button {
                hideKeyboard()
                Task { await viewModel.saveAndExtract() }
            } label: {
                Text("Save")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(canSave ? Color.appBackground : Color.muted)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(canSave ? Color.accent : Color.hairline))
            }
            .buttonStyle(.plain)
            .disabled(!canSave)
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 14)
    }

    private var canSave: Bool {
        !viewModel.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (viewModel.mode == .compose)
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil
        )
    }

    private var personHeader: some View {
        HStack(spacing: 12) {
            stackedAvatars
            VStack(alignment: .leading, spacing: 1) {
                Text(headerTitle)
                    .font(.system(size: 16, weight: .semibold))
                if viewModel.isMultiPerson {
                    Text(headerSubtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.muted)
                        .lineLimit(1)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 14)
    }

    private var stackedAvatars: some View {
        let visible = Array(viewModel.people.prefix(3))
        return ZStack(alignment: .leading) {
            ForEach(Array(visible.enumerated()), id: \.element.id) { i, person in
                AvatarView(person: person, size: 40)
                    .overlay(Circle().stroke(Color.appBackground, lineWidth: 2))
                    .offset(x: CGFloat(i) * 26)
                    .zIndex(Double(visible.count - i))
            }
        }
        .frame(width: 40 + CGFloat(max(visible.count - 1, 0)) * 26, height: 40)
    }

    private var headerTitle: String {
        if viewModel.isMultiPerson {
            return "For \(viewModel.people.count) people"
        }
        return "For \(viewModel.person.name)"
    }

    private var headerSubtitle: String {
        viewModel.people.map(\.firstName).joined(separator: ", ")
    }

    private var placeholderText: String {
        if viewModel.isMultiPerson {
            return "What happened with everyone?"
        }
        return "What did you and \(viewModel.person.firstName) talk about?"
    }

    // ─── Compose mode ──────────────────────────────────────────────────────
    private var composeMode: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(InteractionType.allCases, id: \.self) { t in
                        Button { viewModel.interactionType = t } label: {
                            HStack(spacing: 6) {
                                Image(systemName: t.iconName).font(.system(size: 12, weight: .semibold))
                                Text(t.rawValue).font(.system(size: 13.5, weight: .medium))
                            }
                            .foregroundStyle(viewModel.interactionType == t ? Color.appBackground : Color.ink)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(viewModel.interactionType == t ? Color.accent : Color.chipBg))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 22)
            }
            .padding(.vertical, 14)

            ZStack(alignment: .topLeading) {
                if viewModel.text.isEmpty {
                    Text(placeholderText)
                        .font(.system(size: 16))
                        .foregroundStyle(Color.muted)
                        .padding(.horizontal, 22)
                        .padding(.top, 8)
                }
                TextEditor(text: Binding(get: { viewModel.text }, set: { viewModel.text = $0 }))
                    .font(.system(size: 16))
                    .scrollContentBackground(.hidden)
                    .background(Color.appBackground)
                    .padding(.horizontal, 17)
                    .lineSpacing(3)
            }

            if UserSettings.shared.voiceEnabled {
                VStack(spacing: 8) {
                    Button {
                        Task { await viewModel.startRecording() }
                    } label: {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(.white)
                            .frame(width: 64, height: 64)
                            .background(Circle().fill(Color.accent))
                            .shadow(color: Color.accent.opacity(0.4), radius: 20, x: 0, y: 6)
                    }
                    .buttonStyle(.plain)
                    Text("Hold to talk · or tap")
                        .font(.system(size: 12.5))
                        .foregroundStyle(Color.muted)
                }
                .padding(.bottom, 30)
            }
        }
    }

    private var extractingMode: some View {
        VStack(spacing: 16) {
            ProgressView().tint(Color.muted)
            Text("Pulling out the key facts…")
                .font(.system(size: 14))
                .foregroundStyle(Color.muted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
