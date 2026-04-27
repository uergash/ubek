# Friend App

A personal relationship manager (personal CRM) for iOS that helps the user remember details about friends and family, track important dates, log notes from conversations, and get proactive nudges to stay in touch.

## Tech Stack

- **Platform:** iOS (SwiftUI)
- **Backend:** Supabase (auth + PostgreSQL database + storage)
- **AI:** Claude API (Anthropic) — fact extraction, profile summaries, reach-out suggestions
- **Speech-to-text:** iOS native Speech framework (SFSpeechRecognizer)
- **Notifications:** iOS UserNotifications framework
- **Widget:** iOS WidgetKit
- **Siri integration:** App Intents framework

## Project Structure

```
Friend/
├── App/                  # App entry point, root navigation
├── Auth/                 # Login, signup, onboarding flows
├── Home/                 # Home screen — people list, nudges, upcoming dates
├── Profile/              # Person profile — overview, notes, gifts, dates
├── Notes/                # Note creation, voice capture, AI extraction
├── Gifts/                # Gift wishlist per person
├── Groups/               # Group management
├── Search/               # Global search
├── Reminders/            # Notification scheduling logic
├── Widget/               # WidgetKit extension
├── Intents/              # App Intents for Siri Shortcuts
├── Services/
│   ├── SupabaseService   # All database read/write
│   ├── ClaudeService     # Claude API calls
│   └── ContactsService   # iOS Contacts import
└── Models/               # Data models (Person, Note, Gift, Group, etc.)
```

## Key Product Requirements

See [product-requirements.md](product-requirements.md) for the full requirements doc.

### Core features
- Person profiles with key facts, important dates, notes feed, gift wishlist
- Voice-to-text note capture with AI fact extraction
- Profile overview tab: key facts + AI-generated recent interactions summary
- Proactive reach-out nudges when contact frequency threshold is exceeded
- Event-based reminders (birthdays, anniversaries, custom dates)
- Relationship health indicator (green/yellow/red) on home screen cards
- Gift tracking: wishlist → mark as given → log reaction
- Groups as organizational containers
- iOS Contacts import at onboarding

### AI features (Claude API)
1. Fact extraction from notes → populates Key Facts on profile
2. Profile overview summary → short natural-language recent-interactions summary
3. Reach-out nudge copy → context-aware suggestion of what to say
4. Annual/occasion summaries → surfaced before birthdays/anniversaries

### iOS-specific features
- WidgetKit home screen widget (upcoming dates + top nudges)
- Siri Shortcut via App Intents: "Add a note for [name]"

## Supabase Schema (reference)

Core tables:
- `profiles` — app user accounts (linked to Supabase auth.users)
- `people` — contact profiles owned by a user
- `important_dates` — dates attached to a person (birthday, anniversary, custom)
- `notes` — timestamped notes attached to a person, with interaction_type
- `key_facts` — AI-extracted facts attached to a person
- `gifts` — gift wishlist items per person
- `groups` — named collections
- `group_members` — join table: people ↔ groups

## Development Notes

- Target iOS 17+ to use latest SwiftUI, WidgetKit, and App Intents APIs
- All Claude API calls should be made server-side via a Supabase Edge Function to avoid exposing the API key in the client
- Speech recognition requires NSMicrophoneUsageDescription and NSSpeechRecognitionUsageDescription in Info.plist
- Contacts import requires NSContactsUsageDescription in Info.plist
- Push notifications require APNs setup and a Supabase Edge Function for scheduled nudge delivery
