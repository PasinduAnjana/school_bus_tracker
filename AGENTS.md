# school_bus_tracker — AGENTS.md

Dart SDK `^3.12.2`, Flutter. Multi-platform (Android, iOS, Linux, macOS, Web, Windows). Material 3 light theme, gold (#FFD700) primary.

## Commands

| Action | Command |
|---|---|
| Get deps | `flutter pub get` |
| Run | `flutter run` |
| Test (all) | `flutter test` |
| Analyze | `flutter analyze` |
| Format | `dart format lib/ test/` |

## Project structure

```
lib/
  main.dart                     entrypoint — dotenv, Supabase init, MultiProvider
  app.dart                      Consumer<AuthProvider> → role-based shell or login
  config/                       SupabaseConfig (reads .env), AppTheme (M3 gold)
  models/                       user, gps_location, halt, payment, route_model, student
  providers/                    auth, admin, driver, monitor (all ChangeNotifier)
  screens/                      login, otp, profile, admin/ (5 tabs), driver/, parent/
  services/                     supabase_client (singleton), location, notification, background
  utils/                        phone_utils (formatE164)
  widgets/                      frosted_card, live_map_view, map_pin, otp_field, squishy_button
  design.md                     design spec doc (may be stale — admin nav has 5 tabs now)
assets/   animations/login.json (Lottie), images/login.svg (unused)
```

## Database (Supabase + pg_cron)

| Table | Key columns |
|---|---|
| `users_whitelist` | id, phone_number (UNIQUE), role (Admin/Driver/Parent) — **no name column** |
| `routes` | id, name, driver_id → users_whitelist |
| `students` | id, name, parent_id → users_whitelist, route_id → routes |
| `payments` | id, student_id → students, month, paid — UNIQUE(student_id, month) |
| `live_locations` | id, route_id, driver_id, latitude, longitude, trip_active, recorded_at |
| `halts` | id, route_id, name, arrival_time, latitude, longitude, stop_order |
| `trip_halts` | id, live_location_id, halt_id, completed_at — UNIQUE(live,halt) |
| `otp_codes` (legacy) | unused — auth uses Supabase Auth phone OTP |

RLS: SELECT = `auth.role() = 'authenticated'` on all tables. Admin write ops gated by `public.is_admin()` (checks JWT phone against whitelist). `live_locations` INSERT/UPDATE uses phone-based whitelist lookup (not `auth.uid()`).

**pg_cron** (migration 011): `cleanup_stale_trips()` runs every minute, sets `trip_active=false` on `live_locations` where `recorded_at` > 5 min old.

**Realtime publication:** `live_locations` + `halts` — used by `MonitorProvider.subscribe()`.

## Key gotchas

- **Supabase anon key** — copy exactly from dashboard (includes `eyJ...` JWT prefix). Never prepend anything. `.env.example` shows format.
- **Auth** — Supabase Auth phone OTP (`signInWithOtp` / `verifyOTP`). Session auto-managed. RLS uses `auth.role() = 'authenticated'` (user has real JWT after verification).
- **Phone format** — Supabase Auth strips `+` prefix. `formatE164()` in `lib/utils/phone_utils.dart` normalises Sri Lankan numbers to `+94`. Used before every whitelist lookup.
- **users_whitelist has no `name` column** — only `phone_number` + `role`. Names exist on `students` and `routes` tables only. Do not query `users_whitelist.name`.
- **Background service** — `flutter_background_service` v5.1.0. Isolate runs `Completer<void>().future` loop, pings GPS + Supabase REST (raw HTTP PATCH) every 20s. Android foreground service with `location` type. No `DartPluginRegistrant` needed — auto-registers.
- **Notifications** — `flutter_local_notifications` v22. Android channels: `trip_status`, `bus_tracker_foreground`.
- **Dev bypass** — Phone `0770000000`, code `4592` (documented in `setup.sh` for testing without SMS).
- **seed.sql** — sample INSERTs **commented out** by default. Uncomment before `supabase db reset`.
- **Test** — 1 file (`test/widget_test.dart`), basic smoke test. **Assertions are stale** (checks for "LOGIN" and a subtitle that don't match the current login screen). No integration test infra.
- **Web** — `web/index.html` includes `flutter-passkeys` bundle.js (v2.4.0) from CDN. No passkey Dart code in `lib/`.
- **Unused deps** — `flutter_svg` (`^2.0.10+1`) and `flutter_animate` (`^4.5.0`) are in `pubspec.yaml` but not imported in any Dart source.
- **Linting** — `analysis_options.yaml` uses `package:flutter_lints/flutter.yaml` (flutter_lints v6.0.0 in dev deps).

## Provider architecture

| Provider | Role |
|---|---|
| `AuthProvider` | Supabase session restore → `signInWithOtp` / `verifyOTP` → fetch user from `users_whitelist` |
| `AdminProvider` | CRUD for students, routes, halts, payments, whitelist users. `togglePayment()` does optimistic UI update with rollback. |
| `DriverProvider` | GPS ping loop (20s), start/stop trip, background service orchestration, halt check-in via `trip_halts` |
| `MonitorProvider` | Load active trips (with joins to routes + whitelist), Realtime subscription, halt completion tracking |

## Migrating to a new Supabase project

```bash
supabase login
PROJECT_REF=xxxxxx TEXT_LK_KEY=your-textlk-bearer-token bash supabase/setup.sh
# Follow the 2 manual steps printed (Auth Hook + Phone provider)

# Manual alternative:
supabase link --project-ref <ref>
supabase db push
supabase functions deploy textlk-sms --no-verify-jwt
supabase secrets set TEXT_LK_API_KEY="..." TEXT_LK_SENDER_ID="SchoolBus"
```

### Dashboard (post-CLI)

| Step | Location | Action |
|---|---|---|
| Send SMS hook | Authentication → Auth Hooks | Enable → HTTPS → URL `https://<ref>.functions.supabase.co/textlk-sms` → Generate secret → `supabase secrets set SEND_SMS_HOOK_SECRET="..."` → Save |
| Phone provider | Authentication → Providers → Phone | Toggle ON |

## Edge Functions (Supabase)

| Function | Path | Status | Notes |
|---|---|---|---|
| `textlk-sms` | `supabase/functions/textlk-sms/index.ts` | **Active** | Auth Hook. Forwards OTPs to Text.lk API v3. Verifies Standard Webhooks signature. Deployed `--no-verify-jwt`. |
| `send-otp` | `supabase/functions/send-otp/` | Legacy | Replaced by Supabase Auth phone OTP + hook |
| `verify-otp` | `supabase/functions/verify-otp/` | Legacy | Replaced by Supabase Auth phone OTP + hook |

## Secrets (`supabase secrets set`)

`TEXT_LK_API_KEY`, `TEXT_LK_SENDER_ID` (max 11 chars), `SEND_SMS_HOOK_SECRET` (generated in dashboard).
