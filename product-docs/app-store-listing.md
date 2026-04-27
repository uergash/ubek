# App Store Listing — Friend

Draft copy for App Store Connect. Replace anything in `[brackets]` before submitting.

## App name (30 chars max)
Friend — Personal CRM

## Subtitle (30 chars max)
Remember the people you love

## Promotional text (170 chars max)
Voice-capture the little things — birthdays, what they're up to, what to send. Friend nudges you to reach out, and remembers everything you don't want to forget.

## Description

Friend is a personal CRM for the people who matter most. Keep track of birthdays, anniversaries, and the small details that make your relationships feel cared-for — without spreadsheets, contact app notes, or scattered reminders.

**Built for staying in touch**
- Voice-dictate notes after a conversation. Friend transcribes them on-device and saves them to that person.
- See "key facts" auto-extracted from your notes — partner's name, where they work, things they're into.
- Get gentle nudges when you haven't reached out to someone in a while. Pick the cadence per person.
- Birthdays, anniversaries, and custom dates show up in advance with reminders you'll actually open.

**Smart, but you stay in control**
- Friend uses Anthropic's Claude AI to summarize recent interactions and suggest what to say. AI output may be inaccurate — every summary, fact, and nudge is editable, deletable, and reportable.

**Private by design**
- Your data is yours. We don't sell it, share it with advertisers, or use it to train AI.
- Imported contacts are limited to the ones you tap "Add" — nothing else leaves your device.
- Delete your account at any time and your data goes with it.

**On your home screen and in Siri**
- Widget showing upcoming birthdays and the people you should reach out to.
- "Hey Siri, add a note for Mom" — voice-capture without opening the app.

Built for iPhone. Requires iOS 17.

## Keywords (100 chars total, comma separated)
personal crm,relationships,friends,family,birthdays,reminders,notes,contacts,journal,nudge

## What's New (4000 chars max — for first release)
First release of Friend. Capture voice notes about the people you love, keep track of birthdays and key facts, and get nudged to stay in touch.

## Support URL
[TODO — point to a simple support page or mailto: link]

## Marketing URL (optional)
[TODO — landing page if you have one]

## Privacy Policy URL
[TODO — host the file at /product-docs/privacy-policy.md publicly and paste the URL]

## Age Rating
12+ — generative AI features can produce text that may not be suitable for all ages.
- Infrequent/Mild Mature/Suggestive Themes: No
- Unrestricted Web Access: No
- Generative AI: Yes (Anthropic Claude — used to summarize user-provided notes only)

## App Review Notes (Apple-facing)

Friend is a personal CRM for individuals to track their personal relationships. There is no social/multiplayer component — all data is private to the signed-in user.

Demo account:
- Email: [TODO]
- Password: [TODO]
This account has 8 sample people, ~30 sample notes, and several upcoming birthdays so reviewers can exercise every feature.

Generative AI:
- Friend uses the Anthropic Claude API server-side via Supabase Edge Functions.
- AI features: (1) extract durable "key facts" from a saved note, (2) summarize recent interactions with a person, (3) suggest a sentence or two for a reach-out nudge.
- Users can flag any AI output via long-press → "Report this output" on the home screen nudges and profile summary.
- Disclosure is shown on the welcome screen before sign-up.

Permissions:
- Contacts: requested only after the user explicitly taps "Choose contacts" in onboarding (skippable).
- Microphone + Speech Recognition: requested only when the user taps the mic on the New Note screen (skippable — they can type instead).
- Notifications: requested in onboarding for date and reach-out reminders (skippable; not used for marketing).

Account deletion: Settings → Delete account. The action calls a Supabase Edge Function that removes the auth.users row, and database FK cascades remove all associated content.

## Categories
- Primary: Productivity
- Secondary: Lifestyle
