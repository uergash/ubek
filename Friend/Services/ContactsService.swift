import Foundation
import Contacts

/// Wraps CNContactStore for our import flow.
@MainActor
final class ContactsService {
    static let shared = ContactsService()
    private let store = CNContactStore()
    private init() {}

    enum AccessState {
        case notDetermined, denied, authorized, restricted
    }

    var currentAccess: AccessState {
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .notDetermined: return .notDetermined
        case .denied:        return .denied
        case .restricted:    return .restricted
        case .authorized:    return .authorized
        @unknown default:    return .denied
        }
    }

    func requestAccess() async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            store.requestAccess(for: .contacts) { granted, error in
                if let error { continuation.resume(throwing: error) }
                else { continuation.resume(returning: granted) }
            }
        }
    }

    /// Pulls all contacts (with the keys we care about) and maps them to a
    /// lightweight DTO we can render in a checklist.
    func fetchContacts() async throws -> [ImportableContact] {
        let keys: [CNKeyDescriptor] = [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactOrganizationNameKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor,
            CNContactBirthdayKey as CNKeyDescriptor,
            CNContactIdentifierKey as CNKeyDescriptor,
            CNContactThumbnailImageDataKey as CNKeyDescriptor,
        ]
        let request = CNContactFetchRequest(keysToFetch: keys)
        request.sortOrder = .givenName

        return try await Task.detached(priority: .userInitiated) {
            var results: [ImportableContact] = []
            try CNContactStore().enumerateContacts(with: request) { contact, _ in
                let name = [contact.givenName, contact.familyName]
                    .filter { !$0.isEmpty }
                    .joined(separator: " ")
                guard !name.isEmpty else { return }

                results.append(ImportableContact(
                    id: contact.identifier,
                    name: name,
                    phone: contact.phoneNumbers.first?.value.stringValue,
                    email: contact.emailAddresses.first?.value as String?,
                    birthdayMonth: contact.birthday?.month,
                    birthdayDay: contact.birthday?.day,
                    thumbnailImageData: contact.thumbnailImageData
                ))
            }
            return results
        }.value
    }
}

struct ImportableContact: Identifiable, Hashable {
    let id: String
    let name: String
    let phone: String?
    let email: String?
    let birthdayMonth: Int?
    let birthdayDay: Int?
    /// CNContact.thumbnailImageData (small JPEG, ~5–15KB). Nil when the
    /// source contact has no photo.
    let thumbnailImageData: Data?

    var hasBirthday: Bool { birthdayMonth != nil && birthdayDay != nil }

    var birthdayLabel: String? {
        guard let m = birthdayMonth, let d = birthdayDay else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        var components = DateComponents(year: 2000, month: m, day: d)
        let cal = Calendar.current
        guard let date = cal.date(from: components) else { return nil }
        return "Birthday \(formatter.string(from: date))"
    }
}

extension ImportableContact {
    /// Stable hue derived from the id, so each contact gets a consistent avatar color.
    var avatarHue: Int {
        let hash = abs(id.hashValue)
        return hash % 360
    }
}
