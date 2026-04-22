# GymGrind

A native iOS fitness tracking app built with SwiftUI and Supabase. Log workouts, track nutrition, monitor body metrics, and visualise your progress — all synced to the cloud.

## Features

- **Workout Logging** — Create sessions, add exercises, log sets with weight & reps, and automatically detect personal records (PRs)
- **Workout Templates** — Save and reuse workout templates for faster session creation
- **Nutrition Tracking** — Log meals (breakfast, lunch, dinner, snacks) with calories, protein, carbs, and fat
- **Body Metrics** — Track weight and body fat percentage over time
- **Progress Charts** — Visualise exercise progress and body composition trends
- **Onboarding** — First-launch flow to configure personal goals (calories, protein, carbs, fat, water)
- **Authentication** — Email/password sign-up and login via Supabase Auth
- **Settings** — Customise weight unit (kg/lbs) and daily nutrition goals

## Tech Stack

| Layer | Technology |
|-------|-----------|
| UI | SwiftUI |
| Backend / Auth | Supabase (PostgreSQL + RLS) |
| Architecture | MVVM |
| Platform | iOS |

## Project Structure

```
GymGrind/
├── Models/          # Data models (WorkoutSession, ExerciseEntry, SetEntry, FoodEntry, BodyMetric, WorkoutTemplate)
├── ViewModels/      # Business logic (WorkoutViewModel, NutritionViewModel, AppSettings)
├── Views/
│   ├── Auth/        # Login & sign-up screens
│   ├── Dashboard/   # Home dashboard
│   ├── Workout/     # Active workout, exercise search, workout history
│   ├── Nutrition/   # Food log, add food
│   ├── Progress/    # Charts and progress tracking
│   ├── Settings/    # User preferences
│   ├── Onboarding/  # First-launch setup
│   └── Components/  # Shared UI components (PRBannerView, etc.)
└── Utilities/       # SupabaseClient, SupabaseService, Theme
```

## Setup

### Prerequisites

- Xcode 15+
- A [Supabase](https://supabase.com) project

### 1. Clone the repo

```bash
git clone git@github.com:jovbcorreia/GymGrind.git
cd GymGrind
```

### 2. Configure Supabase

In `GymGrind/Utilities/SupabaseClient.swift`, replace the placeholder values with your project credentials:

```swift
let supabaseURL = URL(string: "https://<your-project>.supabase.co")!
let supabaseKey = "<your-anon-key>"
```

### 3. Apply the database schema

In your Supabase project, open the **SQL Editor** and run the full contents of `supabase_schema.sql`. This creates all tables, enables Row Level Security, and sets up the auto-profile trigger.

### 4. Open in Xcode

```bash
open GymGrind.xcodeproj
```

Select a simulator or your device and press **Run**.

## Database Schema

| Table | Description |
|-------|-------------|
| `profiles` | User settings and daily goals (extends `auth.users`) |
| `workout_sessions` | Workout sessions with name, date, and duration |
| `exercise_entries` | Exercises within a session |
| `set_entries` | Individual sets with weight, reps, and PR flag |
| `food_entries` | Meal log entries with macros |
| `body_metrics` | Weight and body fat snapshots |
| `workout_templates` | Reusable exercise lists |

Row Level Security is enabled on all tables — each user can only access their own data.
