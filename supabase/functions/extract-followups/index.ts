// extract-followups: scans a note for time-bound events worth following up on,
// and proposes reminders with appropriate due dates ("Ask how Alex's interview
// went" → due the day after the interview).
//
// Input:  { noteBody, personName, today }   today = ISO date (yyyy-mm-dd)
// Output: { followups: Array<{ title: string, dueAt: ISO8601 }> }

import { corsHeaders } from "../_shared/cors.ts";
import { callClaude } from "../_shared/claude.ts";
import { requireUser } from "../_shared/auth.ts";

interface RequestBody {
  noteBody: string;
  personName: string;
  today: string; // yyyy-mm-dd
}

const SYSTEM = `You read short personal notes and extract time-bound events
the user should follow up on later. The user is logging interactions with a
specific person; your job is to surface things worth a future check-in.

Output: JSON array of objects with two fields:
- "title": short imperative phrase, max ~8 words, that reads as a reminder.
  Use the person's first name. Specific over vague.
  Examples: "Ask how Alex's interview went", "Check in on Priya's move",
  "Follow up on the Lisbon trip", "See how Sam's first week went".
- "dueAt": ISO 8601 date-time (e.g. "2026-05-12T09:00:00Z"). Pick a date
  AFTER the event so the prompt actually triggers a follow-up:
  - Singular events (interview, date, performance): event day + 1.
  - Multi-day events / trips: end day + 1.
  - Ongoing situations with a milestone (e.g. "starts new job March 1"):
    milestone + 7 days, so you can ask about the first week.
  Default time of day: 09:00 UTC.

Rules:
- Only extract events with concrete or roughly-concrete dates. "Next Tuesday",
  "this Saturday", "May 5", "next month" all qualify. Skip vague mentions
  like "soon", "eventually", "at some point".
- Skip already-past events (the note may describe something that happened —
  no follow-up needed for that).
- Use today's date as the anchor for relative dates.
- Return [] when there's nothing time-bound worth surfacing.
- Output JUST the JSON array, no prose, no markdown fences.`;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    await requireUser(req);
    const body = (await req.json()) as RequestBody;

    const userMessage = `Today: ${body.today}
Person: ${body.personName}

Note:
${body.noteBody}

Extract follow-ups as a JSON array.`;

    const raw = (await callClaude({
      system: SYSTEM,
      messages: [{ role: "user", content: userMessage }],
      maxTokens: 400,
      temperature: 0.4,
    })).trim();

    // Strip code-fence wrappers if Claude adds them despite instructions.
    const cleaned = raw.replace(/^```(?:json)?\s*/i, "").replace(/\s*```$/, "");
    const parsed = JSON.parse(cleaned);

    const followups = Array.isArray(parsed) ? parsed : [];
    return new Response(JSON.stringify({ followups }), {
      headers: { ...corsHeaders, "content-type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: (e as Error).message }), {
      status: 400,
      headers: { ...corsHeaders, "content-type": "application/json" },
    });
  }
});
