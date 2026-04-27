-- AI content reports — required by App Store review for apps with generative AI.
-- Lets users flag a generated summary, nudge, or extracted fact as inappropriate
-- or wrong, so we can review and improve prompts.

create table if not exists public.ai_reports (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles on delete cascade,
  kind text not null check (kind in ('summary', 'nudge', 'fact')),
  content text not null,
  reason text,
  person_id uuid references public.people on delete set null,
  created_at timestamptz not null default now()
);

alter table public.ai_reports enable row level security;

create policy "users insert own reports" on public.ai_reports
  for insert with check (auth.uid() = user_id);

create policy "users read own reports" on public.ai_reports
  for select using (auth.uid() = user_id);
