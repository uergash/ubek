import SwiftUI
import UIKit

@MainActor
struct AddStoryView: View {
    @State private var viewModel = AddStoryViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                Divider().background(Color.hairline)
                Group {
                    switch viewModel.mode {
                    case .compose: composeMode
                    case .recording:
                        VoiceCaptureView(speech: viewModel.speech) { viewModel.stopRecording() }
                    case .extracting: extractingMode
                    case .facts:
                        StoryFactsReviewView(viewModel: viewModel) {
                            hideKeyboard()
                            Task {
                                await viewModel.confirmFacts()
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
            Text("New story").font(.system(size: 15, weight: .semibold))
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

    // ─── Compose ───────────────────────────────────────────────────────────
    private var composeMode: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                if viewModel.text.isEmpty {
                    Text(placeholderText)
                        .font(.system(size: 16))
                        .foregroundStyle(Color.muted)
                        .padding(.horizontal, 22)
                        .padding(.top, 22)
                }
                TextEditor(text: Binding(get: { viewModel.text }, set: { viewModel.text = $0 }))
                    .font(.system(size: 16))
                    .scrollContentBackground(.hidden)
                    .background(Color.appBackground)
                    .padding(.horizontal, 17)
                    .padding(.top, 14)
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

    private var placeholderText: String {
        "What happened? An anecdote, a small win, a funny moment — anything you might want to share later."
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

// ─── Self-fact review (post-save) ──────────────────────────────────────────
@MainActor
private struct StoryFactsReviewView: View {
    @Bindable var viewModel: AddStoryViewModel
    var onDone: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            content
            footer
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.candidateFacts.isEmpty {
            VStack(spacing: 14) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.accent)
                Text("Story saved")
                    .font(.system(size: 17, weight: .semibold))
                Text("No new facts about you to add this time.")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .frame(maxHeight: .infinity)
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 5) {
                        Image(systemName: "sparkles").font(.system(size: 11, weight: .semibold))
                        Text("\(viewModel.candidateFacts.count) NEW \(viewModel.candidateFacts.count == 1 ? "FACT" : "FACTS") ABOUT YOU")
                            .font(.system(size: 11, weight: .semibold))
                            .tracking(0.88)
                    }
                    .foregroundStyle(Color.accent)
                    .padding(.bottom, 8)

                    Text("Tap to confirm. Kept facts show up at the top of your Stories tab.")
                        .font(.system(size: 14.5))
                        .foregroundStyle(Color.inkSoft)
                        .lineSpacing(2)
                        .padding(.bottom, 14)

                    VStack(spacing: 10) {
                        ForEach(viewModel.candidateFacts) { fact in
                            factRow(fact)
                        }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 24)
                .padding(.bottom, 16)
            }
        }
    }

    private func factRow(_ fact: AddStoryViewModel.CandidateFact) -> some View {
        Button {
            viewModel.toggleFact(fact.id)
        } label: {
            HStack(spacing: 10) {
                checkbox(isOn: fact.keep)
                Text(fact.text)
                    .font(.system(size: 14.5, weight: .medium))
                    .foregroundStyle(fact.keep ? Color.ink : Color.muted)
                    .strikethrough(!fact.keep, color: Color.muted)
                Spacer()
                Text(fact.keep ? "Keep" : "Skipped")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.muted)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.card))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.hairline, lineWidth: 1))
            .cardShadow()
        }
        .buttonStyle(.plain)
    }

    private func checkbox(isOn: Bool) -> some View {
        ZStack {
            Circle()
                .fill(isOn ? Color.accent : Color.hairline)
                .frame(width: 22, height: 22)
            if isOn {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
    }

    private var footer: some View {
        let anyKept = viewModel.candidateFacts.contains(where: \.keep)
        return Button(anyKept ? "Save facts" : "Done", action: onDone)
            .buttonStyle(AccentPrimaryLargeButton())
            .padding(.horizontal, 22)
            .padding(.vertical, 14)
    }
}
