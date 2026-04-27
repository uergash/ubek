// generate-annual-summary: a celebratory retrospective shown on someone's
// birthday or anniversary. Pulls together the past year of notes, key facts,
// and gifts into a warm 4-5 sentence reflection.
//
// Input:  { personName, occasionLabel, notes[], keyFacts[], gifts[] }
// Output: { headline, summary }

import { corsHeaders } from "../_shared/cors.ts";
import { callClaude } from "../_shared/claude.ts";
import { requireUser } from "../_shared/auth.ts";

interface RequestBody {
  personName: string;
  occasionLabel: string; // "birthday" | "anniversary"
  notes: Array<{ type: string; body: string; date: string }>;
  keyFacts: string[];
  gifts: Array<{ name: string; occasion: string | null; reaction: string | null }>;
}

const SYSTEM = `You write a celebratory retrospective shown to a user on a
specific person's birthday or anniversary. The user is about to reach out and
wants to be grounded in the year that just passed.

Output a JSON object with two fields:
- "headline": one short, warm line (max ~6 words) e.g. "What a year with Alex".
  No emoji, no quotes.
- "summary": 4 to 5 sentences. Past tense for things that happened, present
  for ongoing situations. Cover topics, life moments, and any notable gifts
  given. Refer to the person by their first name. Specific over generic — pull
  small concrete details from the notes/facts rather than general statements
  like "you had a great year". No flowery openings, no "as you celebrate" or
  birthday tropes. End on a forward-looking note when natural.

If the user has no notes from the past year, return:
- headline: "Wishing [name] well today"
- summary: A two-sentence note acknowledging the lack of recent context and
  encouraging the user to reach out and capture a fresh memory.

Output JUST the JSON object. No prose around it, no markdown fences.`;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    await requireUser(req);
    const body = (await req.json()) as RequestBody;

    const factsBlock = body.keyFacts.length
      ? `Known facts:\n${body.keyFacts.map((f) => `- ${f}`).join("\n")}`
      : "";
    const notesBlock = body.notes.length
      ? `Notes from the past year (newest first):\n${body.notes
          .map((n) => `- (${n.date}, ${n.type}) ${n.body}`)
          .join("\n")}`
      : "";
    const giftsBlock = body.gifts.length
      ? `Gifts given this past year:\n${body.gifts
          .map((g) => `- ${g.name}${g.occasion ? ` (${g.occasion})` : ""}${g.reaction ? ` — they ${g.reaction} it` : ""}`)
          .join("\n")}`
      : "";

    const userMessage = [
      `Person: ${body.personName}`,
      `Occasion: ${body.occasionLabel}`,
      factsBlock,
      notesBlock,
      giftsBlock,
      "",
      "Write the JSON object.",
    ].filter(Boolean).join("\n\n");

    const raw = (await callClaude({
      system: SYSTEM,
      messages: [{ role: "user", content: userMessage }],
      maxTokens: 400,
      temperature: 0.6,
    })).trim();

    // Defensive: strip code-fence wrappers if Claude adds them despite instructions.
    const cleaned = raw.replace(/^```(?:json)?\s*/i, "").replace(/\s*```$/, "");
    const parsed = JSON.parse(cleaned);

    return new Response(
      JSON.stringify({ headline: parsed.headline, summary: parsed.summary }),
      { headers: { ...corsHeaders, "content-type": "application/json" } },
    );
  } catch (e) {
    return new Response(JSON.stringify({ error: (e as Error).message }), {
      status: 400,
      headers: { ...corsHeaders, "content-type": "application/json" },
    });
  }
});
