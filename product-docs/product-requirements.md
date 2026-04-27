# "Friend" App — Product Requirements

## Problem & Intent

The user has difficulty remembering details from conversations with friends and family — past stories, important life events, shared experiences — which makes it hard to reconnect meaningfully. This app acts as a personal relationship manager (personal CRM) that helps the user remember who people are, what they care about, and when and how to reach out.

---

## Platform

- **iOS only** (iPhone-first; Android deferred)
- **Backend:** Supabase (auth, database, storage)
- **AI layer:** Claude API (fact extraction, profile summaries, reach-out suggestions)
- **Speech-to-text:** iOS native Speech framework

---

## Authentication & Account

- Account creation and login via Supabase Auth (email/password at minimum; social login optional)
- Full onboarding flow: create account → import contacts (optional) → land on home screen
- Data is tied to the user's account and synced via Supabase; accessible if user switches devices

---

## Core Entities

### Person Profile
Each person has:
- **Basic info:** name, photo, relationship type (friend, family, colleague, etc.)
- **Contact link:** optionally imported from or linked to iOS Contacts
- **Important dates:** birthday, anniversary, and any custom labeled dates (e.g., "started new job", "due date")
- **Key facts:** AI-extracted highlights from notes (e.g., "has a dog named Max", "training for a triathlon") — displayed as tags or a short list
- **Notes feed:** chronological log of notes (see Notes section)
- **Gift wishlist:** per-person list of gift ideas (see Gifts section)
- **Profile overview tab:** the landing view when opening a profile — shows key facts, upcoming important dates, and an LLM-generated summary of recent interactions

### Group
- A named collection of people (e.g., "College Friends", "Family")
- Organizational only — no group-level notes or reminders in v1
- A person can belong to multiple groups

---

## Notes & Interaction Logging

- **Manual text entry:** user types a note directly
- **Voice-to-text entry:** user taps a microphone button, speaks, and the transcript is saved as a note
- **Interaction type:** each note/log entry includes an optional interaction type (call, coffee/in-person, text, event, other) — enables distinguishing "talked" vs. "just texted"
- Each note is timestamped and attached to a person
- **AI fact extraction:** after a note is saved, the AI identifies and surfaces key facts (names, events, preferences, milestones) and adds them to the person's Key Facts
- Notes are displayed in a feed on the person's profile

---

## Profile Overview (First Tab on Profile)

- Displayed as the default landing tab when opening a person's profile
- Contains:
  - **Key facts** (AI-extracted highlights, shown as scannable chips or a short list)
  - **Upcoming important dates** (next birthday, next custom date, etc.)
  - **Recent interactions summary:** LLM-generated 2–4 sentence summary of the most recent notes/interactions ("Last time you talked, Alex mentioned he was training for a triathlon in June and that his dog Milo had surgery.")
- This acts as a pre-conversation "cheat sheet" without being an explicit "prep mode"

---

## Gift Tracking

Per person:
- **Wishlist:** add gift ideas with optional notes (e.g., "noise-cancelling headphones — she mentioned wanting these for her commute")
- **Mark as given:** mark an idea as gifted, with the occasion and date
- **Reaction tracking:** after giving, log whether they liked it (liked / neutral / didn't like)
- Gifted items are archived but viewable (to avoid re-gifting)

---

## Reminders & Nudges

### Event-based reminders
- Push notification before important dates (birthday, anniversary, custom dates)
- Configurable lead time (e.g., 1 day before, 1 week before)

### Proactive reach-out nudges
- App tracks the last time the user added a note or logged an interaction with each person
- If a configurable time threshold passes (e.g., 3 weeks, 1 month — user sets this globally or per person), the app sends a push notification suggesting a reach-out
- The notification includes an AI-generated suggestion of *what to talk about*, grounded in past notes (e.g., "You haven't talked to Alex in 3 weeks. You could ask him how his triathlon went.")
- Tapping the notification opens the person's profile

---

## Home Screen

- List of all people, searchable and filterable by group
- Each person card shows a **relationship health indicator** — a simple visual (e.g., green/yellow/red dot) based on time since last interaction relative to the user's configured contact frequency for that person
- Upcoming important dates surfaced at the top (next 30 days)
- Pending nudges or reminders visible as a section or badge

---

## Contacts Import

- On onboarding (and available later in settings), user can import from iOS Contacts
- Imported contacts create a basic profile (name, photo if available, birthday if available)
- User selects which contacts to import — not a bulk forced import
- Profiles remain editable after import

---

## AI Integration (Claude API)

Used for four features:
1. **Fact extraction** — after a note is saved, extract key facts and surface them as profile highlights
2. **Profile overview summary** — generate a short natural-language summary of recent notes for the profile overview tab
3. **Reach-out suggestion copy** — when generating a nudge notification, produce a specific, context-aware suggestion of what to say
4. **Annual/occasion summaries** — before a significant date (birthday, anniversary), generate a summary of the past year with that person: topics discussed, life events, gifts given

User has acknowledged that note content will be sent to Claude (or similar) to power these features.

---

## iOS Home Screen Widget

- A small/medium widget showing:
  - Today's birthdays or upcoming dates (next 7 days)
  - Top 1–2 active reach-out nudges
- Tapping the widget deep-links into the relevant person's profile
- Supports iOS WidgetKit (iOS 16+)

---

## Siri Shortcuts & Quick Capture

- Siri Shortcut: "Add a note for [person name]" — opens directly to the voice note recorder for that person, without navigating the app
- App registers an App Intent so the shortcut works hands-free (e.g., right after hanging up a call)
- Optionally: a Lock Screen / Dynamic Island quick-capture action for the most recently contacted person

---

## Search

- Global search across all people and all notes
- Search matches on: person name, note content, key facts, gift ideas
- Results show the person's name + a snippet of the matching note with the search term highlighted

---

## Non-Goals (v1)

- Android support
- Sending messages from within the app (suggestions only, no compose/send)
- Group-level notes or reminders
- Social or shared profiles (single-user app)
- Calendar integration beyond push notifications

---

## Verification Checklist

- [ ] User can create an account and log in via Supabase Auth
- [ ] User can import contacts from iOS and create profiles
- [ ] User can add a voice note; it transcribes correctly and AI extracts key facts
- [ ] Interaction type (call, coffee, text, etc.) can be logged with each note
- [ ] Profile overview tab shows key facts, upcoming dates, and a recent-interactions summary
- [ ] Gift wishlist allows adding, giving, and rating a gift idea
- [ ] Birthday reminder fires as a push notification with correct lead time
- [ ] Proactive nudge fires after the inactivity threshold and includes a context-aware suggestion
- [ ] Groups can be created and people assigned to them; home screen filters by group
- [ ] Relationship health indicator updates correctly on the home screen contact card
- [ ] Home screen widget shows upcoming dates and active nudges; tapping deep-links to the profile
- [ ] Siri Shortcut "Add a note for [name]" opens voice recorder for the correct person
- [ ] Global search returns results across people names, notes, key facts, and gift ideas
- [ ] Annual summary generates correctly before a birthday/anniversary event
