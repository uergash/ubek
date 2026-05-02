import Foundation
import Observation

@MainActor
@Observable
final class AddStoryViewModel {
    enum Mode {
        case compose       // text or pre-recording
        case recording     // live mic
        case extracting    // hitting Claude
        case facts         // showing extracted self-facts for confirmation
    }

    var mode: Mode = .compose
    var text: String = ""

    struct CandidateFact: Identifiable {
        let id = UUID()
        var text: String
        var keep: Bool = true
    }
    var candidateFacts: [CandidateFact] = []

    var savedStoryId: UUID?
    var errorMessage: String?
    var isWorking = false

    let speech = SpeechRecognizer()
    private var existingFacts: [String] = []

    nonisolated init() {}

    /// Pre-loads existing self-facts so Claude can dedupe on save.
    func prepare() async {
        existingFacts = ((try? await SupabaseService.shared.fetchSelfFacts()) ?? []).map(\.text)
    }

    // ─── Voice ────────────────────────────────────────────────────────────
    func startRecording() async {
        text = ""
        speech.transcript = ""
        mode = .recording
        await speech.start()
    }

    func stopRecording() {
        speech.stop()
        if !speech.transcript.isEmpty {
            text = speech.transcript
        }
        mode = .compose
    }

    // ─── Save + extract ───────────────────────────────────────────────────
    /// Persists the story and asks Claude for new "about me" facts. Moves to
    /// `.facts` on success.
    func saveAndExtract() async {
        let body = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else { return }

        // Defensive teardown of the speech engine before any async work.
        speech.stop()

        isWorking = true
        mode = .extracting
        defer { isWorking = false }

        guard let userId = await SupabaseService.shared.resolveCurrentUserId() else {
            errorMessage = "Not signed in."
            mode = .compose
            return
        }

        do {
            let story = Story(
                id: UUID(),
                userId: userId,
                body: body,
                archivedAt: nil,
                createdAt: Date()
            )
            let saved = try await SupabaseService.shared.createStory(story)
            savedStoryId = saved.id
            AppEvents.storyChanged()

            if UserSettings.shared.aiFeaturesEnabled {
                let facts = (try? await ClaudeService.shared.extractSelfFacts(
                    storyBody: body,
                    existingFacts: existingFacts
                )) ?? []
                candidateFacts = facts.map { CandidateFact(text: $0) }
            } else {
                candidateFacts = []
            }
            mode = .facts
        } catch {
            errorMessage = error.localizedDescription
            mode = .compose
        }
    }

    /// Persists the kept self-facts.
    func confirmFacts() async {
        speech.stop()

        guard let storyId = savedStoryId,
              let userId = SupabaseService.shared.currentUserId else { return }
        let kept = candidateFacts.filter(\.keep)
        for cf in kept {
            let fact = SelfFact(
                id: UUID(),
                userId: userId,
                text: cf.text,
                sourceStoryId: storyId,
                createdAt: Date()
            )
            _ = try? await SupabaseService.shared.createSelfFact(fact)
        }
        if !kept.isEmpty {
            AppEvents.storyChanged()
        }
    }

    func toggleFact(_ id: UUID) {
        guard let i = candidateFacts.firstIndex(where: { $0.id == id }) else { return }
        candidateFacts[i].keep.toggle()
    }
}
