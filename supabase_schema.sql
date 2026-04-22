-- ============================================
-- GymGrind — Supabase Schema
-- Corre isto no SQL Editor do Supabase
-- ============================================

-- Profiles (extends auth.users)
create table public.profiles (
  id uuid references auth.users on delete cascade primary key,
  username text default '',
  weight_unit text default 'kg',
  calorie_goal int default 2500,
  protein_goal float default 150,
  carbs_goal float default 300,
  fat_goal float default 80,
  water_goal_ml int default 2500,
  created_at timestamp with time zone default now()
);

-- Workout Sessions
create table public.workout_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users on delete cascade not null,
  name text not null default 'Workout',
  date timestamp with time zone not null default now(),
  duration_minutes int default 0,
  created_at timestamp with time zone default now()
);

-- Exercise Entries
create table public.exercise_entries (
  id uuid primary key default gen_random_uuid(),
  session_id uuid references public.workout_sessions on delete cascade not null,
  exercise_name text not null,
  order_index int default 0,
  created_at timestamp with time zone default now()
);

-- Set Entries
create table public.set_entries (
  id uuid primary key default gen_random_uuid(),
  exercise_id uuid references public.exercise_entries on delete cascade not null,
  set_number int not null default 1,
  weight_kg float default 0,
  reps int default 0,
  completed boolean default false,
  is_pr boolean default false,
  created_at timestamp with time zone default now()
);

-- Food Entries
create table public.food_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users on delete cascade not null,
  date timestamp with time zone not null default now(),
  meal text not null default 'snack',
  name text not null,
  calories int default 0,
  protein_g float default 0,
  carbs_g float default 0,
  fat_g float default 0,
  created_at timestamp with time zone default now()
);

-- Body Metrics
create table public.body_metrics (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users on delete cascade not null,
  date timestamp with time zone not null default now(),
  weight_kg float not null,
  body_fat_percent float,
  created_at timestamp with time zone default now()
);

-- Workout Templates
create table public.workout_templates (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users on delete cascade not null,
  name text not null,
  exercise_names text[] default '{}',
  created_at timestamp with time zone default now()
);

-- ============================================
-- Row Level Security (cada user só vê os seus dados)
-- ============================================
alter table public.profiles enable row level security;
alter table public.workout_sessions enable row level security;
alter table public.exercise_entries enable row level security;
alter table public.set_entries enable row level security;
alter table public.food_entries enable row level security;
alter table public.body_metrics enable row level security;
alter table public.workout_templates enable row level security;

-- Profiles
create policy "own profile" on public.profiles for all using (auth.uid() = id) with check (auth.uid() = id);

-- Workout sessions
create policy "own sessions" on public.workout_sessions for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Exercise entries (via session ownership)
create policy "own exercises" on public.exercise_entries for all using (
  exists (select 1 from public.workout_sessions where id = exercise_entries.session_id and user_id = auth.uid())
) with check (
  exists (select 1 from public.workout_sessions where id = exercise_entries.session_id and user_id = auth.uid())
);

-- Set entries (via exercise → session ownership)
create policy "own sets" on public.set_entries for all using (
  exists (
    select 1 from public.exercise_entries e
    join public.workout_sessions s on s.id = e.session_id
    where e.id = set_entries.exercise_id and s.user_id = auth.uid()
  )
) with check (
  exists (
    select 1 from public.exercise_entries e
    join public.workout_sessions s on s.id = e.session_id
    where e.id = set_entries.exercise_id and s.user_id = auth.uid()
  )
);

-- Food entries
create policy "own food" on public.food_entries for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Body metrics
create policy "own metrics" on public.body_metrics for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Templates
create policy "own templates" on public.workout_templates for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ============================================
-- Auto-criar profile quando user se regista
-- ============================================
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, username)
  values (new.id, coalesce(new.raw_user_meta_data->>'username', ''));
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
