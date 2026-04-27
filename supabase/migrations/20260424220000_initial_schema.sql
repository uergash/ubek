-- Friend app — initial schema
-- Tables: profiles, people, important_dates, notes, key_facts, gifts, groups, group_members
-- All tables have RLS enabled so users only see their own data.

-- ─── profiles ──────────────────────────────────────────────────────────────
create table public.profiles (
  id uuid primary key references auth.users on delete cascade,
  name text not null,
  email text,
  default_contact_frequency_days int not null default 21,
  quiet_hours_start int not null default 21,
  quiet_hours_end int not null default 8,
  created_at timestamptz not null default now()
);

-- ─── people ────────────────────────────────────────────────────────────────
create table public.people (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles on delete cascade,
  name text not null,
  relation text not null default 'Friend',
  avatar_hue int not null default 200,
  phone text,
  email text,
  ios_contact_id text,
  contact_frequency_days int,
  last_interaction_at timestamptz,
  created_at timestamptz not null default now()
);
create index people_user_id_idx on public.people (user_id);
create index people_last_interaction_idx on public.people (user_id, last_interaction_at);

-- ─── important_dates ───────────────────────────────────────────────────────
create table public.important_dates (
  id uuid primary key default gen_random_uuid(),
  person_id uuid not null references public.people on delete cascade,
  kind text not null check (kind in ('birthday','anniversary','custom')),
  label text not null,
  date_month int not null check (date_month between 1 and 12),
  date_day int not null check (date_day between 1 and 31),
  remind boolean not null default true,
  remind_days_before int not null default 1,
  created_at timestamptz not null default now()
);
create index important_dates_person_idx on public.important_dates (person_id);

-- ─── notes ─────────────────────────────────────────────────────────────────
create table public.notes (
  id uuid primary key default gen_random_uuid(),
  person_id uuid not null references public.people on delete cascade,
  interaction_type text not null
    check (interaction_type in ('Call','Coffee','Text','Event','Other')),
  body text not null,
  created_at timestamptz not null default now()
);
create index notes_person_idx on public.notes (person_id, created_at desc);

-- ─── key_facts ─────────────────────────────────────────────────────────────
create table public.key_facts (
  id uuid primary key default gen_random_uuid(),
  person_id uuid not null references public.people on delete cascade,
  text text not null,
  source_note_id uuid references public.notes on delete set null,
  created_at timestamptz not null default now()
);
create index key_facts_person_idx on public.key_facts (person_id);

-- ─── gifts ─────────────────────────────────────────────────────────────────
create table public.gifts (
  id uuid primary key default gen_random_uuid(),
  person_id uuid not null references public.people on delete cascade,
  name text not null,
  note text,
  status text not null default 'wishlist'
    check (status in ('wishlist','given')),
  occasion text,
  given_date date,
  reaction text check (reaction in ('loved','neutral','disliked')),
  created_at timestamptz not null default now()
);
create index gifts_person_idx on public.gifts (person_id, status);

-- ─── groups & members ──────────────────────────────────────────────────────
create table public.groups (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles on delete cascade,
  name text not null,
  created_at timestamptz not null default now()
);
create index groups_user_idx on public.groups (user_id);

create table public.group_members (
  group_id uuid not null references public.groups on delete cascade,
  person_id uuid not null references public.people on delete cascade,
  primary key (group_id, person_id)
);

-- ─── automatic last_interaction_at on note insert ─────────────────────────
create or replace function public.touch_person_last_interaction()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  update public.people
     set last_interaction_at = greatest(coalesce(last_interaction_at, new.created_at), new.created_at)
   where id = new.person_id;
  return new;
end;
$$;

create trigger notes_touch_last_interaction
  after insert on public.notes
  for each row execute function public.touch_person_last_interaction();

-- ─── auto-create profile row when a user signs up ─────────────────────────
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, name, email)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)),
    new.email
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ─── Row Level Security ────────────────────────────────────────────────────
alter table public.profiles        enable row level security;
alter table public.people          enable row level security;
alter table public.important_dates enable row level security;
alter table public.notes           enable row level security;
alter table public.key_facts       enable row level security;
alter table public.gifts           enable row level security;
alter table public.groups          enable row level security;
alter table public.group_members   enable row level security;

create policy "own profile"  on public.profiles for all
  using (auth.uid() = id) with check (auth.uid() = id);

create policy "own people"   on public.people for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "own dates"    on public.important_dates for all
  using (person_id in (select id from public.people where user_id = auth.uid()))
  with check (person_id in (select id from public.people where user_id = auth.uid()));

create policy "own notes"    on public.notes for all
  using (person_id in (select id from public.people where user_id = auth.uid()))
  with check (person_id in (select id from public.people where user_id = auth.uid()));

create policy "own facts"    on public.key_facts for all
  using (person_id in (select id from public.people where user_id = auth.uid()))
  with check (person_id in (select id from public.people where user_id = auth.uid()));

create policy "own gifts"    on public.gifts for all
  using (person_id in (select id from public.people where user_id = auth.uid()))
  with check (person_id in (select id from public.people where user_id = auth.uid()));

create policy "own groups"   on public.groups for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "own members"  on public.group_members for all
  using (group_id in (select id from public.groups where user_id = auth.uid()))
  with check (group_id in (select id from public.groups where user_id = auth.uid()));
