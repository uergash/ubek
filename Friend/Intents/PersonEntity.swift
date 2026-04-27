import AppIntents
import Foundation

/// AppEntity representation of a Person, used by `AddNoteIntent` for the
/// dynamic options provider so Siri can show a list of people to pick from.
struct PersonEntity: AppEntity, Identifiable {
    let id: UUID
    let name: String

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Person"
    static let defaultQuery = PersonQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct PersonQuery: EntityQuery {
    func entities(for identifiers: [PersonEntity.ID]) async throws -> [PersonEntity] {
        let people = (try? await SupabaseService.shared.fetchPeople()) ?? []
        return people
            .filter { identifiers.contains($0.id) }
            .map { PersonEntity(id: $0.id, name: $0.name) }
    }

    func suggestedEntities() async throws -> [PersonEntity] {
        let people = (try? await SupabaseService.shared.fetchPeople()) ?? []
        return people.map { PersonEntity(id: $0.id, name: $0.name) }
    }
}
