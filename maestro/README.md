# Maestro flows

End-to-end UI flows for the Friend iOS app, run via [Maestro](https://maestro.mobile.dev).

## Install

```bash
brew install --cask maestro
# or:
curl -Ls "https://get.maestro.mobile.dev" | bash
```

## Setup

These flows assume:

1. The app is already installed in the booted simulator (or signed onto a real device). Build + install once via Xcode or:
   ```bash
   xcodebuild -project Friend.xcodeproj -scheme Friend \
     -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
     -derivedDataPath build/ build
   xcrun simctl install booted build/Build/Products/Debug-iphonesimulator/Friend.app
   ```

2. Test credentials are exported in your shell. Easiest way is to keep them in
   `maestro/.env.local` (gitignored) and source it per session:
   ```bash
   source maestro/.env.local
   ```
   Or export inline:
   ```bash
   export MAESTRO_FRIEND_EMAIL="qa+friend@example.com"
   export MAESTRO_FRIEND_PASSWORD="<password>"
   ```
   Use a dedicated test account — flows create + mutate data.

3. The test account already has at least 3 people seeded (run `scripts/seed-sample-data.sql` against that user's id, or create the people via the app once).

## Run

```bash
# single flow
maestro test maestro/login.yaml

# whole suite
maestro test maestro/
```

## Flows

- `login.yaml` — auth happy path. Run first; subsequent flows assume you're signed in.
- `multi-person-note.yaml` — exercises the new multi-person note flow end-to-end.
- `create-group.yaml` — opens the New Group sheet, names it, picks members, creates.

## Tips

- `maestro studio` opens an interactive recorder — useful for figuring out element selectors.
- Flows are flaky on the very first cold launch (LaunchScreen / fonts loading). Add a `- waitForAnimationToEnd` before the first assertion if needed.
- Element matching uses accessibility identifiers when available, falling back to visible text. If a flow fails, check whether copy or layout changed.
