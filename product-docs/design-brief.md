# Friend App — Design Brief for Claude Design

## What is this app?

"Friend" is a personal relationship manager for iOS. It solves a specific problem: the user has difficulty remembering details about conversations with friends and family — past stories, important milestones, shared experiences — which makes it hard to reconnect meaningfully. The app acts as a memory layer for relationships: track who people are, what matters to them, and when to reach out.

The tone should feel **warm, personal, and calm** — not productivity-tool cold, not social-network loud. Think of it as a private journal for your relationships.

---

## Screens to Design

### 1. Home Screen
- Header: greeting ("Good morning, Ubek") + date
- **Upcoming section:** horizontal scroll of cards for birthdays/events in the next 7 days — person photo, name, event name, days away
- **Nudges section:** 1–3 reach-out suggestion cards, each showing person photo, name, and a one-line AI suggestion ("Ask Alex how his triathlon went")
- **People list:** scrollable list of all contacts; each row shows:
  - Avatar / initials circle
  - Name + relationship type (friend, family, etc.)
  - Last interaction date ("3 weeks ago")
  - **Relationship health dot** (green = on track, yellow = due soon, red = overdue) based on configured contact frequency
- Search bar at top of people list
- Filter/group tabs (All, Family, Friends, [custom groups])
- Bottom tab bar: Home | Search | Add | [People] | Settings

### 2. Person Profile — Overview Tab
- Header: large avatar, name, relationship type, quick-action buttons (add note, add date)
- **Key facts chips:** horizontally scrollable pill tags — "Has a dog named Milo", "Loves hiking", "Works at Google"
- **Upcoming dates:** next birthday, anniversary, or custom date — compact card
- **Recent interactions summary:** a card with an AI-generated 2–4 sentence paragraph summarizing recent interactions in natural language ("Last time you talked in March, Alex mentioned he was training for a triathlon and that his dog Milo had recovered from surgery. He's been thinking about changing jobs.")
- **Tab bar** below header: Overview | Notes | Gifts | Dates

### 3. Person Profile — Notes Tab
- Chronological feed of note cards, newest first
- Each card: date + interaction type badge (Call, Coffee, Text, Event), note text, any extracted key facts highlighted
- FAB or top-right button to add a new note

### 4. Add Note Sheet (modal)
- Person name at top
- Interaction type selector: row of icon+label chips (Call, Coffee, Text, Event, Other)
- Large text area for note
- **Microphone button** — prominent, centered — to switch to voice capture mode
  - Voice mode: animated waveform, live transcript preview, done button
- AI fact extraction preview (after saving): "We found 2 key facts — tap to confirm"

### 5. Person Profile — Gifts Tab
- Wishlist section: list of gift ideas, each with name, optional note, and a "Mark as given" action
- Gifted section (collapsed by default): archived gifts with occasion, date, and reaction emoji (loved it / neutral / didn't like)
- FAB to add a new gift idea

### 6. Person Profile — Dates Tab
- List of all important dates for this person
- Each row: icon (cake for birthday, ring for anniversary, star for custom), label, date, "Remind me" toggle
- Add date button

### 7. Search Screen
- Full-width search bar (autofocused)
- Results grouped by type: People, Notes, Key Facts, Gifts
- Note results show person name + snippet with search term bolded

### 8. Onboarding Flow (3–4 screens)
- Screen 1: App name + tagline ("Remember what matters to the people you love") + Get Started
- Screen 2: Account creation (name, email, password)
- Screen 3: Import contacts prompt — "Start with people you already know" — with a contacts list and checkboxes; skip option
- Screen 4: Enable notifications prompt — explain the value ("We'll remind you when it's time to reach out")

### 9. iOS Home Screen Widget (small + medium)
- Small: next upcoming birthday or top nudge — person avatar + name + event/suggestion
- Medium: 2 upcoming dates on the left, top nudge on the right

---

## Design Direction

**Visual style:**
- Clean, minimal iOS-native feel
- Warm off-white or soft cream background (not pure white)
- Accent color: a warm, approachable hue — consider terracotta, sage green, or a muted indigo (avoid cold blues and sterile grays)
- Cards with subtle shadow and rounded corners (radius ~16pt)
- Avatar circles with soft gradient fallback for initials

**Typography:**
- SF Pro (system font) throughout
- Hierarchy: large bold title for names, medium weight for section headers, regular for body/notes

**Relationship health indicator:**
- Green dot: contacted within desired frequency
- Yellow dot: approaching overdue
- Red dot: overdue
- Small (8pt) dot, right-aligned on list row — subtle, not alarming

**Voice capture mode:**
- Full-screen or large sheet takeover
- Animated waveform (sine wave or bar visualizer) in accent color
- Live transcript text updating below waveform
- Large stop/done button

**Tone:**
- Friendly and human — not clinical
- Use first names in copy ("You haven't talked to Alex in a while")
- Avoid productivity/CRM language ("log", "record", "entry") in UI copy — prefer "note", "chat", "catch up"

---

## Key User Flows to Prototype

1. **Home → tap nudge → open profile → read overview summary → tap Add Note → voice capture → confirm key facts**
2. **Home → tap upcoming birthday → open profile → read annual summary → add gift idea**
3. **Onboarding: sign up → import contacts → enable notifications → land on home screen**
