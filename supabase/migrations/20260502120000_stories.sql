-- Stories: user-owned anecdotes with no per-person association.
-- Powers the Stories tab — a personal pool of jot-downs to recall before
-- social settings or the cold "what's new with you?" question.

create table public.stories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles on delete cascade,
  body text not null,
  archived_at timestamptz,
  created_at timestamptz not null default now()
);
create index stories_user_active_idx
  on public.stories (user_id, created_at desc)
  where archived_at is null;
create index stories_user_all_idx
  on public.stories (user_id, created_at desc);

create table public.self_facts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles on delete cascade,
  text text not null,
  source_story_id uuid references public.stories on delete set null,
  created_at timestamptz not null default now()
);
create index self_facts_user_idx on public.self_facts (user_id, created_at desc);

alter table public.stories    enable row level security;
alter table public.self_facts enable row level security;

create policy "own stories"     on public.stories for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "own self facts"  on public.self_facts for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);
