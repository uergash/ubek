-- User-controllable feature toggles.
-- ai_features_enabled gates all Claude calls (summaries, nudges, fact
-- extraction, bond-line). voice_enabled gates the in-app mic affordance.
-- Both default to true so existing users keep current behaviour.

alter table public.profiles
  add column ai_features_enabled boolean not null default true;

alter table public.profiles
  add column voice_enabled boolean not null default true;
