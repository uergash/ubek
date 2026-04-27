# Friend App — Build Plan

## Context

iOS personal relationship manager. Full requirements in `product-docs/product-requirements.md`. Design fully reviewed — all screens, tokens, and interactions are understood. This is a greenfield SwiftUI app targeting iOS 17+.

**Stack:** SwiftUI · Supabase (auth + PostgreSQL + storage) · Claude API via Supabase Edge Functions · iOS Speech framework · WidgetKit · App Intents

**Prerequisites before starting:**
- Xcode 15+ installed
- A Supabase project created at supabase.com — need the project URL and `anon` key
- An Anthropic API key for Edge Functions
- Apple Developer account (for push notifications + WidgetKit)

---

## Architecture Decisions

- **State management:** `@Observable` macro (iOS 17) for all ViewModels; `@Environment` for app-wide objects (auth session, Supabase client)
- **Navigation:** `NavigationStack` + `NavigationPath` for push navigation; `.sheet` for Add Note modal
- **Claude API:** Always called via Supabase Edge Functions — API key never in the iOS client
- **Notifications:** Local `UNUserNotificationCenter` for birthday/date reminders (scheduled on-device); proactive nudges computed by a background refresh task (`BGTaskScheduler`)
- **Voice transcription:** `SFSpeechRecognizer` + `AVAudioEngine` for real-time on-device transcription
- **Health indicator:** `lastDays / frequency` — green < 0.85, yellow < 1.25, red ≥ 1.25 (matches design)

---

## Project Structure

```
Friend/                          ← main app target
├── FriendApp.swift
├── AppRootView.swift            ← routes between onboarding + main app
├── App/
│   └── SupabaseConfig.swift     ← singleton Supabase client
├── Design/
│   ├── DesignTokens.swift       ← Color + Font extensions (matches CSS vars)
│   └── Components/
│       ├── AvatarView.swift
│       ├── HealthDotView.swift
│       ├── ChipView.swift
│       ├── FactChipView.swift
│       ├── CardView.swift
│       ├── SectionHeaderView.swift
│       └── MainTabBar.swift
├── Models/
│   ├── Person.swift
│   ├── Note.swift
│   ├── KeyFact.swift
│   ├── Gift.swift
│   ├── ImportantDate.swift
│   └── FriendGroup.swift
├── Services/
│   ├── SupabaseService.swift    ← all CRUD; one method per operation
│   ├── ClaudeService.swift      ← calls Edge Functions
│   ├── ContactsService.swift    ← CNContactStore import
│   └── NotificationService.swift
├── Auth/
│   ├── AuthViewModel.swift
│   ├── WelcomeView.swift
│   ├── SignUpView.swift / SignInView.swift
│   ├── ImportContactsView.swift
│   └── NotificationsPermissionView.swift
├── Home/
│   ├── HomeViewModel.swift
│   ├── HomeView.swift
│   ├── UpcomingCardView.swift
│   └── NudgeCardView.swift
├── Profile/
│   ├── ProfileViewModel.swift
│   ├── ProfileView.swift        ← header + tab switcher
│   ├── OverviewTabView.swift
│   ├── NotesTabView.swift + NoteCardView.swift
│   ├── GiftsTabView.swift + GiftCardView.swift
│   └── DatesTabView.swift
├── Notes/
│   ├── AddNoteViewModel.swift
│   ├── AddNoteView.swift        ← compose mode
│   ├── VoiceCaptureView.swift
│   └── FactExtractionView.swift
├── Search/
│   ├── SearchViewModel.swift
│   └── SearchView.swift
├── Settings/
│   ├── SettingsViewModel.swift
│   └── SettingsView.swift
├── Widget/                      ← FriendWidget extension target
│   ├── FriendWidget.swift
│   └── WidgetProvider.swift
└── Intents/
    └── AddNoteIntent.swift      ← App Intent for Siri

supabase/
├── migrations/
│   └── 001_initial_schema.sql
└── functions/
    ├── extract-facts/index.ts
    ├── generate-summary/index.ts
    └── generate-nudge/index.ts
```

---

## Supabase Schema (`001_initial_schema.sql`)

```sql
create table profiles (
  id uuid primary key references auth.users on delete cascade,
  name text not null,
  email text,
  default_contact_frequency_days int not null default 21,
  quiet_hours_start int not null default 21,
  quiet_hours_end int not null default 8,
  created_at timestamptz default now()
);

create table people (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles on delete cascade,
  name text not null,
  relation text not null default 'Friend',
  avatar_hue int not null default 200,
  phone text,
  email text,
  ios_contact_id text,
  contact_frequency_days int,         -- null = use profile default
  last_interaction_at timestamptz,
  created_at timestamptz default now()
);

create table important_dates (
  id uuid primary key default gen_random_uuid(),
  person_id uuid not null references people on delete cascade,
  kind text not null check (kind in ('birthday','anniversary','custom')),
  label text not null,
  date_month int not null,
  date_day int not null,
  remind bool not null default true,
  remind_days_before int not null default 1,
  created_at timestamptz default now()
);

create table notes (
  id uuid primary key default gen_random_uuid(),
  person_id uuid not null references people on delete cascade,
  interaction_type text not null
    check (interaction_type in ('Call','Coffee','Text','Event','Other')),
  body text not null,
  created_at timestamptz default now()
);

create table key_facts (
  id uuid primary key default gen_random_uuid(),
  person_id uuid not null references people on delete cascade,
  text text not null,
  source_note_id uuid references notes,
  created_at timestamptz default now()
);

create table gifts (
  id uuid primary key default gen_random_uuid(),
  person_id uuid not null references people on delete cascade,
  name text not null,
  note text,
  status text not null default 'wishlist' check (status in ('wishlist','given')),
  occasion text,
  given_date date,
  reaction text check (reaction in ('loved','neutral','disliked')),
  created_at timestamptz default now()
);

create table groups (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles on delete cascade,
  name text not null,
  created_at timestamptz default now()
);

create table group_members (
  group_id uuid not null references groups on delete cascade,
  person_id uuid not null references people on delete cascade,
  primary key (group_id, person_id)
);

-- Row Level Security: users only see their own data
alter table profiles enable row level security;
alter table people enable row level security;
alter table important_dates enable row level security;
alter table notes enable row level security;
alter table key_facts enable row level security;
alter table gifts enable row level security;
alter table groups enable row level security;
alter table group_members enable row level security;

create policy "own profile" on profiles for all using (auth.uid() = id);
create policy "own people" on people for all using (auth.uid() = user_id);
create policy "own dates" on important_dates for all
  using (person_id in (select id from people where user_id = auth.uid()));
create policy "own notes" on notes for all
  using (person_id in (select id from people where user_id = auth.uid()));
create policy "own facts" on key_facts for all
  using (person_id in (select id from people where user_id = auth.uid()));
create policy "own gifts" on gifts for all
  using (person_id in (select id from people where user_id = auth.uid()));
create policy "own groups" on groups for all using (auth.uid() = user_id);
create policy "own members" on group_members for all
  using (group_id in (select id from groups where user_id = auth.uid()));
```

---

## Edge Functions

### `extract-facts/index.ts`
- Input: `{ noteBody: string, personName: string, existingFacts: string[] }`
- Calls Claude with a prompt to extract 0–5 new key facts as a JSON array of strings
- Returns: `{ facts: string[] }`

### `generate-summary/index.ts`
- Input: `{ personName: string, notes: Array<{type, body, date}> }`
- Calls Claude to produce a 2–4 sentence natural-language recent-interactions summary
- Returns: `{ summary: string }`

### `generate-nudge/index.ts`
- Input: `{ personName: string, keyFacts: string[], lastNotes: Array<{type, body, date}>, daysSince: number }`
- Calls Claude to produce a 1–2 sentence reach-out suggestion
- Returns: `{ suggestion: string }`

All three functions authenticate via Supabase JWT (verify `Authorization: Bearer <token>` header).

---

## Build Phases

### Phase 1 — Foundation
**Goal:** Runnable skeleton with design system and models in place.

1. Create Xcode project: `Friend`, SwiftUI, iOS 17, Swift Package Manager
2. Add dependency: `github.com/supabase/supabase-swift` (latest)
3. `DesignTokens.swift` — Color extensions matching CSS vars:
   - `Color.bg`, `.card`, `.cardSoft`, `.ink`, `.inkSoft`, `.muted`, `.hairline`, `.chipBg`
   - `Color.accent`, `.accentDeep`, `.accentSoft`, `.accentTint`
   - `Color.healthGreen`, `.healthYellow`, `.healthRed`
4. Shared UI components (match design file primitives exactly):
   - `AvatarView` — gradient circle with initials, `hue` parameter
   - `HealthDotView` — 8pt colored dot
   - `ChipView` — pill button, active/inactive states
   - `FactChipView` — accent-soft pill with star icon
   - `CardView` — white card, 20pt radius, subtle shadow
   - `SectionHeaderView` — uppercase muted label + optional action
   - `MainTabBar` — 5-tab bar with centered accent FAB
5. `Models/` — all Codable structs with snake_case CodingKeys for Supabase
6. `SupabaseConfig.swift` — `SupabaseClient` singleton initialized with project URL + anon key (from `Config.xcconfig`, gitignored)
7. `AppRootView.swift` — shows `OnboardingFlow` if no session, else `MainTabView`

---

### Phase 2 — Supabase Backend
**Goal:** Schema + Edge Functions deployed; can call them from a test harness.

1. Write and apply `001_initial_schema.sql` via Supabase dashboard or CLI
2. Write `SupabaseService.swift` with methods:
   - `fetchPeople()`, `createPerson()`, `updatePerson()`, `deletePerson()`
   - `fetchNotes(for:)`, `createNote()`, `updateLastInteraction()`
   - `fetchKeyFacts(for:)`, `createKeyFact()`, `deleteKeyFact()`
   - `fetchGifts(for:)`, `createGift()`, `updateGift()`, `deleteGift()`
   - `fetchDates(for:)`, `createDate()`, `updateDate()`, `deleteDate()`
   - `fetchGroups()`, `createGroup()`, `addMember()`, `removeMember()`
3. Write `ClaudeService.swift` — calls each Edge Function via `supabase.functions.invoke()`
4. Write and deploy the three Edge Functions with Supabase CLI (`supabase functions deploy`)
5. Set Edge Function secrets: `ANTHROPIC_API_KEY`

---

### Phase 3 — Auth & Onboarding
**Goal:** Full 4-screen onboarding flow; auth state persists across launches.

1. `AuthViewModel.swift` — wraps `supabase.auth`, publishes `session`
2. `WelcomeView` — heart logo, tagline, Get Started / I have an account (matches design)
3. `SignUpView` / `SignInView` — name, email, password fields; calls `supabase.auth.signUp()` / `signIn()`; on signup creates `profiles` row
4. `ImportContactsView` — uses `ContactsService` (`CNContactStore`); checkbox list; "Add N people" button creates `people` rows
5. `NotificationsPermissionView` — lists the 3 nudge types; calls `NotificationService.requestPermission()`
6. Wire `AppRootView` to skip onboarding once session exists

**Info.plist additions:**
- `NSContactsUsageDescription`
- `NSMicrophoneUsageDescription`
- `NSSpeechRecognitionUsageDescription`

---

### Phase 4 — Home Screen
**Goal:** Scrollable home with real data from Supabase.

1. `HomeViewModel.swift`:
   - Fetches all people + their `last_interaction_at` + upcoming dates
   - Computes `health(person)` ratio
   - Sorts people: red → yellow → green
   - Surfaces upcoming dates (next 30 days)
   - Fetches or generates nudges (calls `ClaudeService.generateNudge` for overdue people)
2. `UpcomingCardView` — 158pt wide horizontal scroll card (avatar, name, event icon, days badge)
3. `NudgeCardView` — avatar, name, "suggested" badge, suggestion text; taps open profile
4. `HomeView` — greeting header, Upcoming horizontal scroll, Reach Out section, search bar, group filter chips, people list sorted by health
5. Filter chips drive `HomeViewModel.filter` which re-sorts the list

---

### Phase 5 — Person Profile
**Goal:** All 4 profile tabs populated with real data.

1. `ProfileViewModel.swift` — loads person, notes, key facts, gifts, dates, AI summary
2. `ProfileView.swift` — centered avatar (92pt), name, health dot + relation + last interaction label, quick-action buttons (Add note / Add date / Gift), 4-tab switcher with accent underline indicator
3. **Overview tab:**
   - Horizontal scroll of `FactChipView` for key facts
   - "Coming up" `CardView` with icon, label, date, "in X days" pill
   - AI summary card with "SUMMARY" sparkle badge, paragraph text (calls `ClaudeService.generateSummary` on load if stale)
   - Latest note preview
4. **Notes tab:** Dashed "New note" button + chronological `NoteCardView` list (type icon + badge, body text, extracted fact chips)
5. **Gifts tab:** Wishlist cards ("Mark as given →" action → sheet to capture occasion + reaction); Gifted section (archived, reaction badge)
6. **Dates tab:** List card with icon, label, date, `Toggle` for remind

---

### Phase 6 — Add Note (Voice + AI)
**Goal:** Full note capture flow with voice transcription and fact extraction.

1. `AddNoteViewModel.swift` — manages `mode` (compose / recording / extracting / facts), holds transcript + text, calls services
2. `AddNoteView.swift` (compose mode):
   - "For [name]" header with avatar + "Change" tappable
   - Interaction type chip row (Call / Coffee / Text / Event / Other)
   - Borderless `TextEditor` with placeholder
   - Floating accent mic FAB ("Hold to talk · or tap")
3. `VoiceCaptureView.swift`:
   - Starts `SFSpeechRecognizer` + `AVAudioEngine` on appear
   - Animated 28-bar waveform (matches design — bars driven by audio power meter)
   - Live transcript updates in real-time
   - Done button → transitions to extraction mode
4. `FactExtractionView.swift`:
   - Shows transcript quote in a soft card
   - "We found N new facts" sparkle header
   - Each fact: check circle, text, Skip button
   - "Save note" creates the `notes` row, calls `ClaudeService.extractFacts`, creates confirmed `key_facts` rows, updates `last_interaction_at`

---

### Phase 7 — Search
**Goal:** Full-text search across people, notes, and key facts.

1. `SearchViewModel.swift` — debounced query (300ms); searches in-memory loaded data across `people.name`, `notes.body`, `key_facts.text`, `gifts.name`
2. `SearchView.swift`:
   - Back button + autofocused search input
   - Results grouped under People / Notes / Key Facts section headers
   - Matched text highlighted with accent-soft background (using `AttributedString`)
   - Tapping any result navigates to the profile

---

### Phase 8 — Settings
**Goal:** Settings screen wired to real user preferences.

1. `SettingsViewModel.swift` — loads/saves `profiles` row (default frequency, quiet hours), manages notification settings
2. `SettingsView.swift`:
   - User card (avatar, name, email)
   - **Reach-out cadence group:** Default frequency (stepper/picker), Quiet hours
   - **Data group:** Imported contacts count, voice transcription toggle, Claude summaries toggle
   - **Notifications group:** Birthday lead time, nudge toggle, widget refresh
   - Sign out button

---

### Phase 9 — Push Notifications
**Goal:** Birthday reminders and proactive nudge notifications.

1. `NotificationService.swift`:
   - `requestPermission()` — `UNUserNotificationCenter.requestAuthorization`
   - `scheduleBirthdayReminders(for:)` — iterates all people's `important_dates`, schedules a `UNCalendarNotificationTrigger` for each (fires annually, `remind_days_before` days before)
   - Notification body uses Claude nudge suggestion for context ("It's Alex's birthday in 2 days. Last time you talked he mentioned his Oakland triathlon.")
2. Background nudge check via `BGAppRefreshTask`:
   - Registered in `Info.plist` as `com.friend.nudgeRefresh`
   - On trigger: fetch people, compute overdue (ratio ≥ 1.25), generate nudge suggestion via `ClaudeService`, post local notification
   - Reschedule task for next check
3. Tapping a notification deep-links to the person's profile via `UNNotificationResponse` handling in `AppRootView`

---

### Phase 10 — Widget
**Goal:** iOS home screen widget showing upcoming dates + top nudge.

1. New Xcode target: **FriendWidget** (WidgetKit extension)
2. `WidgetEntry.swift` — `TimelineEntry` with upcoming dates array + nudge person + nudge text
3. `WidgetProvider.swift` — `TimelineProvider`; reads from Supabase (or `UserDefaults` app group for offline) on refresh; refreshes every hour
4. `FriendWidget.swift` — `Widget` conforming type with `small` and `medium` `WidgetFamily` cases:
   - **Small:** event icon + "In Xd" badge, avatar, name, event label (matches design)
   - **Medium:** left column "Upcoming" (2 rows), right column "Reach out" (avatar + name + suggestion text)
5. Tapping widget deep-links to person profile via URL scheme `friend://person/<id>`

---

### Phase 11 — Siri Shortcuts
**Goal:** "Add a note for [name]" hands-free shortcut.

1. `AddNoteIntent.swift` — `AppIntent` conforming type:
   - `title`: "Add a note"
   - `@Parameter` for person name with `DynamicOptionsProvider` (returns all people from Supabase)
   - `perform()`: opens app directly to `AddNoteView` for the selected person via `@Environment(\.openURL)`
2. Register in `Info.plist` / `AppIntentPackage`

---

## Key Design Details to Match Exactly

| Element | Value |
|---|---|
| Background | `oklch(0.985 0.008 75)` ≈ `Color(hue:0.11, sat:0.04, bri:0.985)` |
| Accent | `oklch(0.66 0.13 40)` — warm terracotta |
| Card radius | 20pt |
| Avatar gradient | `135deg`, unique hue per person, oklch lightness 0.86→0.74 |
| Tab bar FAB | 52pt circle, accent, -10pt vertical offset, shadow |
| FactChip | Accent-soft background, accent-deep text, ★ icon prefix |
| Health dot | 8pt circle — green/yellow/red |
| Section header | 13pt, 600 weight, uppercase, 0.06em letter-spacing, muted color |
| Waveform | 28 bars, 4pt wide, animated height via `sin()` |

---

## Verification

- [ ] Auth: sign up, sign in, sign out, session persists on relaunch
- [ ] Contacts import: select contacts → people created in Supabase with correct data
- [ ] Home screen: people sorted by health, upcoming dates visible, nudge cards show
- [ ] Profile overview: key facts chips, coming up card, AI summary loads
- [ ] Notes tab: existing notes visible in chronological order
- [ ] Add note (text): saves to Supabase, `last_interaction_at` updates, health dot changes
- [ ] Add note (voice): transcription appears live, fact extraction runs, confirmed facts appear on profile
- [ ] Gifts: add wishlist item, mark as given, set reaction, see in Gifted section
- [ ] Dates: add custom date, reminder toggle saves to Supabase
- [ ] Search: query returns results across people, notes, key facts; matches highlighted
- [ ] Settings: changing default frequency updates profile; persists on relaunch
- [ ] Birthday notification: fires correct number of days before date
- [ ] Proactive nudge: fires for person whose `lastDays/frequency ≥ 1.25`
- [ ] Widget: medium shows 2 upcoming + 1 nudge; small shows nearest upcoming; tapping opens profile
- [ ] Siri: "Add a note for Alex" opens voice capture for Alex
