import AppIntents
import SwiftUI
import UIKit
import Foundation

/// Siri Shortcut: "Add a note for [name]". Opens the app and deep-links to the
/// new-note sheet for the selected person via the friend://add-note/<id> URL.
struct AddNoteIntent: AppIntent {
    static let title: LocalizedStringResource = "Add a note"
    static let description: IntentDescription = "Capture a quick voice or text note about someone."
    static let openAppWhenRun: Bool = true

    @Parameter(title: "Person")
    var person: PersonEntity

    @MainActor
    func perform() async throws -> some IntentResult {
        // Deep-link via URL — main app's onOpenURL surfaces the AddNote sheet.
        let url = URL(string: "friend://add-note/\(person.id)")!
        await UIApplication.shared.open(url)
        return .result()
    }
}

struct FriendShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddNoteIntent(),
            phrases: [
                "Add a note in \(.applicationName)",
                "New \(.applicationName) note",
                "Capture a note in \(.applicationName)",
            ],
            shortTitle: "Add a note",
            systemImageName: "doc.text"
        )
    }
}
