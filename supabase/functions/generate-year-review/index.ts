// generate-year-review: Spotify-Wrapped-style retrospective of the user's
// year of relationships. Returns a hero headline + a 4-6 sentence reflection
// across the whole year, with reference to top people, gifts, life moments.
//
// Input: { year, totalNotes, totalGifts, topPeople[], notableNotes[], giftsWithReactions[] }
// Output: { headline, reflection }

import { corsHeaders } from "../_shared/cors.ts";
import { callClaude } from "../_shared/claude.ts";
import { requireUser } from "../_shared/auth.ts";

interface RequestBody {
  year: number;
  totalNotes: number;
  totalGifts: number;
  topPeople: Array<{ name: string; noteCount: number }>;
  notableNotes: Array<{ personName: string; type: string; body: string; date: string }>;
  giftsWithReactions: Array<{ personName: string; name: string; reaction: string | null }>;
}

const SYSTEM = `You write a warm, reflective 4 to 6 sentence retrospective on
a user's year of friendships and relationships, shown in their personal CRM.

Output a JSON object with two fields:
- "headline": a single short, evocative line (max ~7 words). No emoji, no quotes.
  Examples: "A year of showing up", "The year you stayed close".
- "reflection": 4 to 6 sentences. Reference 2-3 specific people by name, lean
  on concrete details from the provided notes (life events, things they care
  about, things they've been through). Acknowledge gifts when they're notable.
  No flowery openings, no "as you reflect on this year". End on a forward-
  looking note when natural.

If totalNotes is small or zero, still produce a kind, honest output:
- headline: "A quieter year of beginnings"
- reflection: A short note acknowledging that the user is just getting started
  and encouraging them to keep logging.

Output JUST the JSON object. No prose around it, no markdown fences.`;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    await requireUser(req);
    const body = (await req.json()) as RequestBody;

    const peopleBlock = body.topPeople.length
      ? `Top people (by note count):\n${body.topPeople
          .map((p) => `- ${p.name}: ${p.noteCount} notes`)
          .join("\n")}`
      : "";
    const notesBlock = body.notableNotes.length
      ? `Notable notes from the year:\n${body.notableNotes
          .map((n) => `- (${n.date}, ${n.personName}, ${n.type}) ${n.body}`)
          .join("\n")}`
      : "";
    const giftsBlock = body.giftsWithReactions.length
      ? `Gifts given:\n${body.giftsWithReactions
          .map((g) => `- ${g.name} for ${g.personName}${g.reaction ? ` — they ${g.reaction} it` : ""}`)
          .join("\n")}`
      : "";

    const userMessage = [
      `Year: ${body.year}`,
      `Total notes: ${body.totalNotes}`,
      `Total gifts given: ${body.totalGifts}`,
      peopleBlock,
      notesBlock,
      giftsBlock,
      "",
      "Write the JSON object.",
    ].filter(Boolean).join("\n\n");

    const raw = (await callClaude({
      system: SYSTEM,
      messages: [{ role: "user", content: userMessage }],
      maxTokens: 500,
      temperature: 0.6,
    })).trim();

    const cleaned = raw.replace(/^```(?:json)?\s*/i, "").replace(/\s*```$/, "");
    const parsed = JSON.parse(cleaned);

    return new Response(
      JSON.stringify({ headline: parsed.headline, reflection: parsed.reflection }),
      { headers: { ...corsHeaders, "content-type": "application/json" } },
    );
  } catch (e) {
    return new Response(JSON.stringify({ error: (e as Error).message }), {
      status: 400,
      headers: { ...corsHeaders, "content-type": "application/json" },
    });
  }
});
