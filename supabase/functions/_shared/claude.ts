// Thin Claude API wrapper for Edge Functions.
// Requires the ANTHROPIC_API_KEY secret to be set in Supabase.

const ANTHROPIC_VERSION = "2023-06-01";
const DEFAULT_MODEL = "claude-haiku-4-5-20251001";

export interface ClaudeMessage {
  role: "user" | "assistant";
  content: string;
}

export interface ClaudeOptions {
  system: string;
  messages: ClaudeMessage[];
  maxTokens?: number;
  model?: string;
  temperature?: number;
}

export async function callClaude(opts: ClaudeOptions): Promise<string> {
  const apiKey = Deno.env.get("ANTHROPIC_API_KEY");
  if (!apiKey) throw new Error("ANTHROPIC_API_KEY is not set");

  const res = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "x-api-key": apiKey,
      "anthropic-version": ANTHROPIC_VERSION,
      "content-type": "application/json",
    },
    body: JSON.stringify({
      model: opts.model ?? DEFAULT_MODEL,
      max_tokens: opts.maxTokens ?? 512,
      temperature: opts.temperature ?? 0.4,
      system: opts.system,
      messages: opts.messages,
    }),
  });

  if (!res.ok) {
    const detail = await res.text();
    throw new Error(`Claude API error ${res.status}: ${detail}`);
  }

  const data = await res.json();
  // content is an array of blocks; we expect a single text block.
  const block = data.content?.[0];
  if (!block || block.type !== "text") {
    throw new Error("Claude returned no text content");
  }
  return block.text as string;
}

/// Try to parse a JSON value out of a Claude response, tolerating Markdown
/// fences and extra prose around it.
export function extractJSON<T>(text: string): T {
  const fenced = text.match(/```(?:json)?\s*([\s\S]*?)```/i);
  const candidate = fenced ? fenced[1] : text;
  const trimmed = candidate.trim();
  // Find the first { or [ to start parsing from
  const start = trimmed.search(/[\[{]/);
  if (start < 0) throw new Error("No JSON found in Claude response");
  return JSON.parse(trimmed.slice(start)) as T;
}
