-- Reminders: one-shot, time-bound to-dos attached to a person, distinct
-- from the recurring `important_dates` (which fire every year).

create table public.reminders (
  id uuid primary key default gen_random_uuid(),
  person_id uuid not null references public.people on delete cascade,
  title text not null,
  due_at timestamptz not null,
  completed boolean not null default false,
  created_at timestamptz not null default now()
);

create index reminders_person_idx on public.reminders (person_id);
create index reminders_due_idx on public.reminders (due_at) where not completed;

alter table public.reminders enable row level security;

create policy "own reminders" on public.reminders for all
  using (person_id in (select id from public.people where user_id = auth.uid()))
  with check (person_id in (select id from public.people where user_id = auth.uid()));
