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

-- Per-user daily quota for the Edge Function proxies (groq-recipes, gemini-vision, pexels-photo).
-- No policies on purpose: the table is only reachable through consume_quota().
create table if not exists public.api_usage (
  user_id uuid not null references auth.users on delete cascade,
  kind text not null,
  day date not null default current_date,
  used_count int not null default 0,
  primary key (user_id, kind, day)
);

alter table public.api_usage enable row level security;

create or replace function public.consume_quota(p_kind text, p_limit int)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  used int;
begin
  if auth.uid() is null then
    return false;
  end if;
  insert into api_usage (user_id, kind) values (auth.uid(), p_kind)
  on conflict (user_id, kind, day)
    do update set used_count = api_usage.used_count + 1
  returning used_count into used;
  return used <= p_limit;
end;
$$;

revoke all on function public.consume_quota(text, int) from public, anon;
grant execute on function public.consume_quota(text, int) to authenticated;
