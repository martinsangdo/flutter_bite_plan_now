-- Run in the Supabase SQL editor. Enable Authentication > Providers > Anonymous sign-ins first.
create table if not exists public.meal_history (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  recipe_id text not null,
  title text not null,
  recipe jsonb not null,
  cooked_at timestamptz not null default now()
);

alter table public.meal_history enable row level security;

create policy "own rows: select" on public.meal_history
  for select using (user_id = auth.uid());
create policy "own rows: insert" on public.meal_history
  for insert with check (user_id = auth.uid());
