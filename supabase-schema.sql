-- Homely Supabase schema
-- Run this entire script in Supabase SQL Editor.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  language text not null default 'en',
  accessibility jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.households (
  id uuid primary key default gen_random_uuid(),
  name text not null default 'My Homely Home',
  owner_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.household_members (
  household_id uuid not null references public.households(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'member' check (role in ('owner','admin','member')),
  created_at timestamptz not null default now(),
  primary key (household_id,user_id)
);

create table if not exists public.rooms (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  name text not null,
  name_fil text,
  icon text not null default '🏠',
  created_at timestamptz not null default now()
);

create table if not exists public.chores (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  room_id uuid references public.rooms(id) on delete set null,
  name text not null,
  name_fil text,
  duration text,
  repeat_type text not null default 'daily' check (repeat_type in ('daily','weekly','monthly','custom')),
  repeat_config jsonb not null default '{}'::jsonb,
  reminder_time time,
  priority text not null default 'normal' check (priority in ('low','normal','high')),
  notes text,
  active boolean not null default true,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.chore_completions (
  id uuid primary key default gen_random_uuid(),
  chore_id uuid not null references public.chores(id) on delete cascade,
  household_id uuid not null references public.households(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  date_key date not null,
  completed_at timestamptz not null default now(),
  unique(chore_id,user_id,date_key)
);

create index if not exists idx_household_members_user on public.household_members(user_id);
create index if not exists idx_rooms_household on public.rooms(household_id);
create index if not exists idx_chores_household on public.chores(household_id);
create index if not exists idx_completions_household on public.chore_completions(household_id);

alter table public.profiles enable row level security;
alter table public.households enable row level security;
alter table public.household_members enable row level security;
alter table public.rooms enable row level security;
alter table public.chores enable row level security;
alter table public.chore_completions enable row level security;

-- Helper: whether the signed-in user belongs to a household.
create or replace function public.is_household_member(target_household uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.household_members hm
    where hm.household_id = target_household and hm.user_id = auth.uid()
  );
$$;

-- Profiles
 drop policy if exists "profiles own select" on public.profiles;
create policy "profiles own select" on public.profiles for select using (user_id = auth.uid());
drop policy if exists "profiles own insert" on public.profiles;
create policy "profiles own insert" on public.profiles for insert with check (user_id = auth.uid());
drop policy if exists "profiles own update" on public.profiles;
create policy "profiles own update" on public.profiles for update using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Households
 drop policy if exists "households member select" on public.households;
create policy "households member select" on public.households for select using (public.is_household_member(id) or owner_id = auth.uid());
drop policy if exists "households owner insert" on public.households;
create policy "households owner insert" on public.households for insert with check (owner_id = auth.uid());
drop policy if exists "households owner update" on public.households;
create policy "households owner update" on public.households for update using (owner_id = auth.uid()) with check (owner_id = auth.uid());

-- Membership
 drop policy if exists "members own or household select" on public.household_members;
create policy "members own or household select" on public.household_members for select using (user_id = auth.uid() or public.is_household_member(household_id));
drop policy if exists "members self insert" on public.household_members;
create policy "members self insert" on public.household_members for insert with check (user_id = auth.uid() and exists(select 1 from public.households h where h.id=household_id and h.owner_id=auth.uid()));

-- Rooms
 drop policy if exists "rooms member select" on public.rooms;
create policy "rooms member select" on public.rooms for select using (public.is_household_member(household_id));
drop policy if exists "rooms member insert" on public.rooms;
create policy "rooms member insert" on public.rooms for insert with check (public.is_household_member(household_id));
drop policy if exists "rooms member update" on public.rooms;
create policy "rooms member update" on public.rooms for update using (public.is_household_member(household_id)) with check (public.is_household_member(household_id));
drop policy if exists "rooms member delete" on public.rooms;
create policy "rooms member delete" on public.rooms for delete using (public.is_household_member(household_id));

-- Chores
 drop policy if exists "chores member select" on public.chores;
create policy "chores member select" on public.chores for select using (public.is_household_member(household_id));
drop policy if exists "chores member insert" on public.chores;
create policy "chores member insert" on public.chores for insert with check (public.is_household_member(household_id) and created_by = auth.uid());
drop policy if exists "chores member update" on public.chores;
create policy "chores member update" on public.chores for update using (public.is_household_member(household_id)) with check (public.is_household_member(household_id));
drop policy if exists "chores member delete" on public.chores;
create policy "chores member delete" on public.chores for delete using (public.is_household_member(household_id));

-- Completions
 drop policy if exists "completions member select" on public.chore_completions;
create policy "completions member select" on public.chore_completions for select using (public.is_household_member(household_id));
drop policy if exists "completions self insert" on public.chore_completions;
create policy "completions self insert" on public.chore_completions for insert with check (public.is_household_member(household_id) and user_id = auth.uid());
drop policy if exists "completions self update" on public.chore_completions;
create policy "completions self update" on public.chore_completions for update using (user_id = auth.uid() and public.is_household_member(household_id)) with check (user_id = auth.uid() and public.is_household_member(household_id));
drop policy if exists "completions self delete" on public.chore_completions;
create policy "completions self delete" on public.chore_completions for delete using (user_id = auth.uid() and public.is_household_member(household_id));

-- Optional convenience trigger for profile creation when users sign up.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles(user_id, display_name)
  values (new.id, split_part(coalesce(new.email,''),'@',1))
  on conflict (user_id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

-- Grants for the browser client. RLS remains the access control layer.
grant usage on schema public to anon, authenticated;
grant select, insert, update on public.profiles to authenticated;
grant select, insert, update on public.households to authenticated;
grant select, insert on public.household_members to authenticated;
grant select, insert, update, delete on public.rooms to authenticated;
grant select, insert, update, delete on public.chores to authenticated;
grant select, insert, update, delete on public.chore_completions to authenticated;
