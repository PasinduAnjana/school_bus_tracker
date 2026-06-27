# school_bus_tracker — AGENTS.md

## Project

Flutter app (Dart, multi-platform). Three roles (Admin, Driver, Parent) determined by phone number in the `users_whitelist` table.

## Commands

| Action | Command |
|---|---|
| Get deps | `flutter pub get` |
| Run | `flutter run` |
| Test (all) | `flutter test` |
| Analyze | `flutter analyze` |
| Format | `dart format lib/ test/` |

## Key gotchas

- **Supabase anon key must be copied exactly from the dashboard** — it includes a JWT header prefix (e.g., `eyJ...`). The `.env.example` placeholder shows the full key format. Never prepend anything.
- **Auth uses Supabase Auth phone OTP** — `signInWithOtp()` / `verifyOTP()` manage session automatically. Original RLS policies (`auth.role() = 'authenticated'`) work because the user has a real JWT after verification.
- **Custom SMS provider (Text.lk)** — Configure a webhook in Supabase dashboard (Auth → Settings → SMS → Custom) that integrates with Text.lk. Without this, Supabase uses its default SMS provider.
- **Dev bypass phone** — `0770000000` + code `4592` skips all backend calls and auto-assigns Admin role. Useful for UI development.

## Structure

- `lib/main.dart` — entrypoint, initializes Supabase + dotenv + providers
- `lib/app.dart` — MaterialApp with role-based routing via `Consumer<AuthProvider>`
- `lib/config/` — `app_theme.dart` (yellow `#FFD700` palette), `supabase_config.dart` (reads from `.env`), `dev_bypass.dart`
- `lib/models/` — `user.dart`, `route_model.dart`, `student.dart`, `payment.dart`, `gps_location.dart`
- `lib/providers/` — `auth_provider.dart` (phone → OTP → role lookup), admin/driver/parent providers (stubs)
- `lib/screens/` — login, OTP, admin shell (3 tabs), driver shell, parent shell with map placeholder
- `lib/widgets/` — `squishy_button.dart` (bounce animation), `frosted_card.dart` (glassmorphism), `otp_field.dart`
- `lib/design.md` — color palette, animation spec, SVG asset inventory (assets TBD)
- `supabase/migrations/001_schema.sql` — 6 tables + RLS + real-time on `live_locations`
- `supabase/functions/` — `send-otp` and `verify-otp` Edge Functions (legacy, not currently used — replaced by Supabase Auth phone OTP with custom SMS webhook)

## Platforms

All six: Android, iOS, Linux, macOS, Web, Windows.

## No CI/CD

Not configured. Add workflows under `.github/workflows/` when needed.
