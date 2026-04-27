import Foundation
import Supabase

/// Reads Supabase credentials from the app's Info.plist (populated by Config.xcconfig).
/// Until you set those values, the client is constructed lazily so the app still builds.
enum SupabaseConfig {
    static let shared: SupabaseClient = {
        let url = URL(string: projectURL) ?? URL(string: "https://placeholder.supabase.co")!
        return SupabaseClient(supabaseURL: url, supabaseKey: anonKey)
    }()

    static var isConfigured: Bool {
        !projectURL.contains("placeholder") && !anonKey.isEmpty
    }

    private static var projectURL: String {
        Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String
            ?? "https://placeholder.supabase.co"
    }

    private static var anonKey: String {
        Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String ?? ""
    }
}
