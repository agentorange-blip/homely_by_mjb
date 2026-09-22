-- Homely V8 optional database upgrade.
-- Run this ONCE in Supabase SQL Editor after the existing Homely schema.
-- Safe to run again because IF NOT EXISTS / DO blocks are used.

-- Extra chore controls used by V8.
alter table public.chores add column if not exists reminder_enabled boolean not null default true;
alter table public.chores add column if not exists assigned_to uuid references auth.users(id) on delete set null;

-- Home Tools: shopping / supplies.
create table if not exists public.shopping_items (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  name text not null,
  done boolean not null default false,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

-- Home Tools: maintenance.
create table if not exists public.maintenance_tasks (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  name text not null,
  due_date date,
  done boolean not null default false,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

alter table public.shopping_items enable row level security;
alter table public.maintenance_tasks enable row level security;

-- Browser client grants.
grant select, insert, update, delete on public.shopping_items to authenticated;
grant select, insert, update, delete on public.maintenance_tasks to authenticated;

-- Household membership helper. Uses existing household_members table.
create or replace function public.is_homely_household_member(hid uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.household_members hm
    where hm.household_id = hid and hm.user_id = auth.uid()
  );
$$;

grant execute on function public.is_homely_household_member(uuid) to authenticated;

-- Policies for Home Tools.
drop policy if exists "shopping_select_members" on public.shopping_items;
drop policy if exists "shopping_insert_members" on public.shopping_items;
drop policy if exists "shopping_update_members" on public.shopping_items;
drop policy if exists "shopping_delete_members" on public.shopping_items;
create policy "shopping_select_members" on public.shopping_items for select to authenticated using (public.is_homely_household_member(household_id));
create policy "shopping_insert_members" on public.shopping_items for insert to authenticated with check (public.is_homely_household_member(household_id));
create policy "shopping_update_members" on public.shopping_items for update to authenticated using (public.is_homely_household_member(household_id)) with check (public.is_homely_household_member(household_id));
create policy "shopping_delete_members" on public.shopping_items for delete to authenticated using (public.is_homely_household_member(household_id));

drop policy if exists "maintenance_select_members" on public.maintenance_tasks;
drop policy if exists "maintenance_insert_members" on public.maintenance_tasks;
drop policy if exists "maintenance_update_members" on public.maintenance_tasks;
drop policy if exists "maintenance_delete_members" on public.maintenance_tasks;
create policy "maintenance_select_members" on public.maintenance_tasks for select to authenticated using (public.is_homely_household_member(household_id));
create policy "maintenance_insert_members" on public.maintenance_tasks for insert to authenticated with check (public.is_homely_household_member(household_id));
create policy "maintenance_update_members" on public.maintenance_tasks for update to authenticated using (public.is_homely_household_member(household_id)) with check (public.is_homely_household_member(household_id));
create policy "maintenance_delete_members" on public.maintenance_tasks for delete to authenticated using (public.is_homely_household_member(household_id));

-- Make the two V8 chore columns available to the browser role.
grant select, insert, update, delete on public.chores to authenticated;
