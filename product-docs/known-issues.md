# Known issues

## Simulator auth/session not loading after sign-in (P1)

**Symptom:** After sign-in, `auth.state == .signedIn` (so app routes to Home), but
`SupabaseClient.auth.currentUser` is `nil` and `auth.session` rejects with
`Swift.CancellationError`. Result: all RLS-gated PostgREST queries return `[]`
because no JWT is attached, and the user sees "No people yet".

**Likely cause:** Either a supabase-swift 2.x simulator-keychain bug, or a
race between the auth state listener firing and the session being persisted.
Possibly aggravated by the iOS Simulator's keychain not being properly
sandboxed across `simctl install` cycles.

**Things tried (none worked):**
- `nonisolated init()` on AuthViewModel + dispatch bootstrap to MainActor task
- Pre-warming `auth.session` from inside the auth state listener
- `resolveCurrentUserId()` helper that awaits `auth.session` if `currentUser` is nil
- Forcing `state = .signedOut` after `signOut()` regardless of API success
- Multiple `simctl uninstall` + `install` cycles
- Disabling email confirmation (Supabase auth settings)
- `.id()` on OnboardingFlow to prevent state reuse across signOut/signIn

**Suggested next steps when we come back to this:**
1. Test on a real device — simulator keychain is the prime suspect
2. Pin a specific supabase-swift version (try 2.5.x) instead of `from: 2.0.0`
3. Manually inject the JWT into a custom URLSession header to bypass the
   library's auth handling
4. Add a `try await client.auth.refreshSession()` in `bootstrap()` to validate
   the loaded session

**Workaround for now:** None — feature work proceeded without working auth
in the simulator. All features below the auth layer (data models, screens,
AI integration, etc.) are wired up and will come alive once auth is fixed.
