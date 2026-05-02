import Foundation
import Observation

@MainActor
@Observable
final class StoriesViewModel {
    private(set) var allStories: [Story] = []
    private(set) var selfFacts: [SelfFact] = []
    private(set) var hasLoaded = false
    var showArchived = false

    var activeStories: [Story] {
        allStories.filter { $0.archivedAt == nil }
    }

    var archivedStories: [Story] {
        allStories.filter { $0.archivedAt != nil }
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await load()
    }

    func load() async {
        async let storiesTask = SupabaseService.shared.fetchAllStories()
        async let factsTask = SupabaseService.shared.fetchSelfFacts()
        allStories = (try? await storiesTask) ?? []
        selfFacts = (try? await factsTask) ?? []
        hasLoaded = true
    }

    func archive(_ story: Story) async {
        try? await SupabaseService.shared.archiveStory(id: story.id)
        AppEvents.storyChanged()
        await load()
    }

    func unarchive(_ story: Story) async {
        try? await SupabaseService.shared.unarchiveStory(id: story.id)
        AppEvents.storyChanged()
        await load()
    }

    func delete(_ story: Story) async {
        try? await SupabaseService.shared.deleteStory(id: story.id)
        AppEvents.storyChanged()
        await load()
    }

    func deleteFact(_ fact: SelfFact) async {
        try? await SupabaseService.shared.deleteSelfFact(id: fact.id)
        await load()
    }
}
