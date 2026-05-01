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

const SYSTEM = `You write a celebratory retrospective shown to the USER on a
specific PERSON's birthday or anniversary. The user is about to reach out to
that person and wants to be grounded in the year that just passed.

Audience and voice — read carefully:
- The reader is the USER. The subject is the PERSON (not the reader).
- Write ABOUT the person in third person: "Helen", "she", "her".
- NEVER address the person in second person. Do not write "you walked the
  lake loop", "you started watercolor", etc. — the person will never read
  this; the user will.
- The user's notes are written first-person from the user's POV
  ("I drove up Saturday", "Mom called me"). Translate those into third
  person about the person ("Helen and the user walked the lake loop").
- "You" is fine ONLY when it refers to the user (e.g. "you flew out for
  the funeral"), but prefer rephrasing to keep the focus on the person.

Output a JSON object with two fields:
- "headline": one short, warm line (max ~6 words) about the person, e.g.
  "What a year for Alex" or "Helen, year 38". No emoji, no quotes. Do NOT
  address the person ("Happy anniversary, Mom" is wrong).
- "summary": 4 to 5 sentences in third person about the person. Past tense
  for things that happened, present for ongoing situations. Cover topics,
  life moments, and any notable gifts given. Refer to the person by their
  first name (or the relation label if it IS their name, e.g. "Mom").
  Specific over generic — pull small concrete details from the notes/facts
  rather than general statements like "she had a great year". No flowery
  openings, no "as we celebrate" or birthday tropes. End on a
  forward-looking note when natural.

If there are no notes from the past year, return:
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
