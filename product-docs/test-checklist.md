# Friend — Manual Test Checklist

A scripted run-through to surface bugs, UX rough edges, and UI issues. Work top-to-bottom; items in **bold** require a real device.

## Automated coverage (skip the manual versions when these pass)

Run the automated suite first — it covers most golden-path flows:

```bash
# View-model unit tests + SwiftUI snapshot tests
xcodebuild -project Friend.xcodeproj -scheme Friend \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=latest' test

# End-to-end Maestro flows (sign-in once, then run others in order)
source maestro/.env.local
maestro test maestro/login.yaml
maestro test maestro/                       # all flows
```

| Area | Automated | What to still do manually |
|---|---|---|
| Auth (sign-in, sign-out) | login.yaml, signout.yaml | bad-password, offline launch |
| Home tab navigation | app-navigation.yaml | empty state, pull-to-refresh |
| People + groups | profile-tabs.yaml, group-filter.yaml, create-group.yaml | top-contacts ranking, empty list |
| Add / edit person | add-person.yaml, edit-person.yaml | delete person + cascade, custom relation, avatar swatch |
| Spotlight (person of the day) | spotlight.yaml | Claude-generated bond line wording |
| Note flow (single + multi-person) | single-person-note.yaml, multi-person-note.yaml | edit mid-compose, very long body, emoji |
| Gifts | gifts.yaml | reactions ≠ "loved", multiple wishlist items |
| Dates | add-date.yaml | edit/delete, label-required validation |
| Reminders | add-reminder.yaml, complete-reminder.yaml | overdue rendering, delete |
| Settings (frequency) | change-frequency.yaml | account deletion |
| Settings (AI / voice toggles) | settings-ai-toggle.yaml, settings-voice-toggle.yaml | edge cases (toggle while sheet open) |
| Settings (quiet hours) | quiet-hours.yaml | actually shifting notification times |
| Year-in-review | year-in-review.yaml | the rendered reflection content |
| On this day | not automated | seeded notes from past years on Home |
| Occasion takeover (birthday/anniversary) | not automated (depends on today's date) | manually set a person's birthday to today and verify Home + Profile cards |
| Nudges | nudge-tap-expand.yaml | dismiss + reappear, multiple pills |
| **Send-text deep link** 📱 | not automated (no Messages app on sim) | tap "Send text" on Home / People nudge / Spotlight, confirm Messages opens with recipient |
| **Voice capture** 📱 | not automated | full Section 7 manually |
| **Notifications** 📱 | not automated | full Section 10 manually |
| **Widget** 📱 | not automated | full Section 11 manually |
| **Siri / Contacts import** 📱 | not automated | Sections 12–13 |
| Visual polish | snapshot tests for NoteCard / NudgesStrip | full Section 16 manually |

Edge cases / robustness in Section 15 are still worth running through occasionally.

---

## 0. Setup

- [ ] Apply latest migrations: `supabase db push` (or your usual flow). Verify `notes.note_group_id` column exists.
- [ ] Seed sample data via `scripts/seed-sample-data.sql` (update the `uid` to your auth user id first).
- [ ] Confirm at least 5 people, varied health states (red/yellow/green), and several notes/facts/gifts/dates exist.
- [ ] Run on **simulator** for the bulk of UI flows. Switch to a **physical device** for sections marked with 📱.

---

## 1. Auth & onboarding

- [ ] Fresh install → signup with new email. Profile row auto-created.
- [ ] Sign out, sign back in. Session persists across cold launch.
- [ ] **Bad password / wrong email** → clear error, no crash.
- [ ] **Offline launch** with stale session → app loads cached state or shows a sensible message (no infinite spinner).
- [ ] Onboarding Contacts import (if you reach it): grant + deny permission paths both work. Denied path doesn't block app usage.

## 2. Home screen

- [ ] Greeting reflects time of day and first name.
- [ ] **Upcoming** dates strip shows next 30 days, sorted by `daysUntilNext`. Tapping a card opens that profile.
- [ ] **Coming due** reminders only shows uncompleted, due ≤14d or overdue. Overdue items render in red.
- [ ] **Reach out** nudges show only red-health people; suggestions are non-empty AI copy (not "[error]" or empty string).
- [ ] **Recently engaged** shows the 6 most recent notes globally. Date/icon/interaction type all render.
- [ ] **Empty state** (test by signing in as a fresh user with no people): correct empty illustration, no broken sections.
- [ ] Pull-to-refresh works and reloads sections.
- [ ] Tap a person card → profile opens; back button returns to Home with state intact (scroll position, etc.).

## 3. People page

- [ ] Header, search pill render.
- [ ] **Nudges strip** — pills are compact (avatar + name + days). Horizontal scroll smooth, no clipping.
- [ ] Tap a pill → expanded card appears below with full suggestion + Open profile + ×. Tap same pill again → collapses.
- [ ] Tap × in expanded card → suggestion dismissed and removed; verify it doesn't reappear on refresh (until cooldown elapses).
- [ ] **Top contacts** strip shows up to 5 highest-engagement people.
- [ ] **Groups section** — existing groups appear as cards with member counts. "+ New group" card at end of strip.
- [ ] Tap "New group" (card or section header action) → sheet appears.
- [ ] In NewGroupSheet: enter empty name → "Create" disabled. Enter name with only spaces → still disabled.
- [ ] Select 0 members and create → group created with 0 members, count shows 0.
- [ ] Select 3+ members and create → group appears in strip with correct count.
- [ ] Tap a group card → AllPeopleView opens with that group filter pre-selected. Switching filter chips works.
- [ ] Tap "Search all people" pill or "See all people" button → AllPeopleView opens with **All** filter (not the previously tapped group).

## 4. Profile page

- [ ] Open a profile with notes + facts + gifts + dates → all four tabs populate.
- [ ] **Overview tab**: AI summary appears (or "Add a note to start building..." if empty). Key facts chips render.
- [ ] **Notes tab**: most-recent first. Date and interaction icon correct.
- [ ] Multi-person notes (after Section 6) show "With X, Y" attribution row with mini avatars.
- [ ] Each note's extracted facts appear as chips on its card.
- [ ] **Gifts tab**: wishlist + given sections. Mark a wishlist gift as given → reaction prompt → moves to given list.
- [ ] **Dates tab**: birthdays/anniversaries/custom render with correct upcoming-days label. Toggle remind → setting persists.
- [ ] **Reminders tab**: add a reminder → appears in list and on Home "Coming due". Toggle complete → strikethrough/removed from due. Delete → gone.

## 5. Note creation — single person

- [ ] Tap + in tab bar → PersonPickerSheet.
- [ ] Tap one person → checkbox lights up. **It does NOT auto-advance.**
- [ ] Tap "Next" → AddNoteView opens, header shows that one person's avatar + name.
- [ ] Type a note (long, multi-line). Try emojis. Try only whitespace → Save disabled.
- [ ] Pick each interaction type chip; selection visually persists.
- [ ] Save → spinner → fact extraction view → confirm/skip facts → returns to caller.
- [ ] Verify: note appears on profile Notes tab; kept facts appear on Overview; `last_interaction_at` updated (Recently engaged on Home shows it).
- [ ] **Cancel mid-compose** → returns without saving anything.

## 6. Note creation — multi-person 🆕

- [ ] Tap +, select 2 people via checkboxes. Title becomes "New note for 2".
- [ ] Tap a third → "New note for 3". Tap one again → deselects, count drops.
- [ ] Hit "Next" → AddNoteView header shows stacked avatars + comma-separated first names.
- [ ] Save the note. After fact extraction, confirm copy mentions: "logged for everyone" / facts only attributed to primary.
- [ ] Open each selected person's profile → all show the note in their feed, with "With \[other people]" attribution.
- [ ] Open the **first-selected** (primary) person's Overview → kept key facts appear. Open another attendee's Overview → those facts do **NOT** appear (intentional).
- [ ] Recently engaged on Home shows the note(s); confirm it doesn't appear duplicated weirdly.
- [ ] Database check (optional): `select id, person_id, note_group_id from notes where note_group_id is not null;` — N rows share the same group id.

## 7. Voice capture 📱

- [ ] Tap mic on AddNoteView → permission prompt fires first time.
- [ ] **Deny mic** → graceful fallback (clear error, return to compose).
- [ ] Grant mic. Live transcript appears as you speak. Waveform animates with audio level.
- [ ] Tap Done → transcript lands in the text editor.
- [ ] Edit the transcript before saving → edits persist.
- [ ] Speak nothing for several seconds → no crash, transcript empty.
- [ ] **Background the app while recording** → resume → no audio session leak (test next mic launch still works).
- [ ] Long recording (>1 min) → transcript keeps appending without hangs.

## 8. AI fact extraction

- [ ] After save, "Pulling out the key facts…" appears, then the facts list.
- [ ] Empty notes / chitchat → "No new facts to add this time" path renders.
- [ ] Toggle keep/skip on each fact → state preserved through scroll.
- [ ] Tap Save → only kept facts persist on profile.
- [ ] Long fact text wraps correctly in chip view.
- [ ] **Network failure during extraction** (toggle airplane mode after Save): note still persisted, error surfaced sensibly.

## 9. Reach-out nudges

- [ ] Force a person into red state (last_interaction_at >> threshold). Reload → they appear on Home Reach out + People Nudges strip.
- [ ] Suggestion text references the person and is plausible (not generic).
- [ ] Dismiss from People → also disappears from Home on reload.
- [ ] After logging a note for that person → they leave the nudge list.

## 10. Reminders & notifications 📱

- [ ] Add a reminder for in 5 minutes → notification fires.
- [ ] Add a date reminder (birthday in next few days) → schedules correctly.
- [ ] Tap notification → app opens to that person's profile.
- [ ] Disable a date's `remind` toggle → no notification fires.
- [ ] Quiet hours respected (set quiet hours to current time, schedule reminder, verify suppressed/deferred).
- [ ] **Background app + lock device** → notifications still arrive.

## 11. Widget 📱

- [ ] Add Friend widget to home screen.
- [ ] Widget shows top 5 upcoming dates + 2 nudges. Names, dates, and avatar colors correct.
- [ ] Add a new note in app → widget refreshes (may take a few seconds).
- [ ] Tap a widget row → app opens to that person's profile.
- [ ] Widget on a fresh install with no data → empty/placeholder state, not a crash.

## 12. Siri / App Intents 📱

- [ ] "Hey Siri, add a note for \[person]" via Shortcut → triggers add-note flow on the right person.
- [ ] Person name not found → graceful failure copy.

## 13. Contacts import 📱

- [ ] Settings → import. Permission denied → no crash.
- [ ] Permission granted → contacts list shown, multi-select works, dedupes against existing people.

## 14. Settings

- [ ] Update default contact frequency → reflects in health-state calculation on next refresh.
- [ ] Update quiet hours → respected by next reminder schedule.
- [ ] Sign out → returns to auth, no stale data leaks into next account.

## 15. Edge cases / robustness

- [ ] Person with very long name (40+ chars) → truncates correctly in cards/rows/headers, doesn't break layout.
- [ ] Person with emoji in name → renders.
- [ ] Note body 5,000+ chars → scrolls within profile feed without breaking.
- [ ] 100+ people seeded → People page, AllPeopleView, and PersonPickerSheet stay responsive.
- [ ] Group with 0 members → tappable, AllPeopleView shows empty list gracefully.
- [ ] Group with all members → list shows everyone.
- [ ] Delete a person who is in a group / has notes → cascades correctly, no orphan UI references.
- [ ] Rapid tap "+" → only one picker sheet at a time (no double-stacking).
- [ ] **Airplane mode** for entire session → reads from Supabase fail; UI degrades sensibly (no infinite spinners, no lost in-progress text).
- [ ] **Background then foreground** during voice capture, fact extraction, and group creation → no zombie sheets, no stuck loading states.

## 16. Visual polish

- [ ] Consistent corner radii, shadows, padding across cards.
- [ ] Health dot colors match brand spec (no off-shade reds/yellows).
- [ ] Dark mode (if supported) renders cleanly — no white-on-white text.
- [ ] Dynamic type at largest accessibility size → text doesn't overlap or get cut off.
- [ ] Avatar gradient hues distinct enough across people; initials always centered.
- [ ] No SwiftUI warnings about ambiguous frames / NaN sizes in the console.

---

## How to log issues found

Append to [known-issues.md](known-issues.md) with:

```
### <short title>
- **Where:** <screen / flow>
- **Steps:** <reproduction>
- **Expected vs actual:** <…>
- **Severity:** blocker / major / polish
```
