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

- **Supabase anon key must be copied exactly from the dashboard** — it already includes a JWT header prefix (`eyJ...`). `.env.example` shows the full format. Never prepend anything.
- **Auth uses Supabase Auth phone OTP** — `signInWithOtp()` / `verifyOTP()` manage session automatically. RLS policies (`auth.role() = 'authenticated'`) work because the user has a real JWT after verification.
- **Custom SMS provider (Text.lk)** — a Supabase Auth Hook forwards OTPs to Text.lk via the `textlk-sms` Edge Function (source: `supabase/functions/textlk-sms/index.ts`).
- **Phone number format**: Supabase Auth strips the `+` prefix from returned phone numbers. The app normalises it before whitelist lookups. The utility `lib/utils/phone_utils.dart` (`formatE164`) converts Sri Lankan numbers to `+94` format (strips non-digits, prepends `+94`).
- **Dev bypass**: setup.sh mentions `0770000000` / code `4592` for testing without SMS. The old `dev_bypass.dart` has been removed — bypass is handled directly in phone formatting logic.
- **seed.sql** (`supabase/seed.sql`) — sample data INSERTs are **commented out** by default. Uncomment before running `supabase db reset` or paste into dashboard SQL Editor.
- **Only 1 test** exists (`test/widget_test.dart`) — a basic widget smoke test. No integration test infrastructure.

## Structure

- `lib/main.dart` — entrypoint, initializes `flutter_dotenv`, `SupabaseService.init()`, then `MultiProvider` (AuthProvider, AdminProvider, DriverProvider, MonitorProvider)
- `lib/app.dart` — MaterialApp with role-based routing: `AuthStatus.authenticated` routes to AdminShell / DriverShell / ParentShell by `UserRole`; else LoginScreen
- `lib/services/supabase_client.dart` — `SupabaseService` singleton wrapping `Supabase.initialize()`
- `lib/utils/phone_utils.dart` — `formatE164()` Sri Lanka phone normalization
- `lib/config/` — `app_theme.dart` (yellow `#FFD700` palette, Material 3), `supabase_config.dart` (reads from `.env` via `flutter_dotenv`)
- `lib/models/` — `user.dart`, `route_model.dart`, `student.dart`, `payment.dart`, `gps_location.dart`, `halt.dart`
- `lib/providers/` — `auth_provider.dart` (phone → OTP → role lookup), `admin_provider.dart`, `driver_provider.dart`, `monitor_provider.dart` (live trip/halt monitoring)
- `lib/screens/` — `login_screen.dart`, `otp_screen.dart`, `admin/` (shell with **5 tabs**: Students, Drivers, Payments, Routes, Monitor), `driver/`, `parent/`
- `lib/widgets/` — `squishy_button.dart`, `frosted_card.dart`, `otp_field.dart`, `map_pin.dart`
- `lib/design.md` — visual design spec (colors, animations, glassmorphism, SVG asset list)
- `supabase/` — migrations (7 files: schema, RLS, halts, trip_halts); Edge Functions (`textlk-sms` active, `send-otp`/`verify-otp` legacy); `setup.sh`; `seed.sql`; `config.toml`
- `.env` is registered as a Flutter asset in `pubspec.yaml` (line 70)

## Migrating to a new Supabase project

### Automated (preferred)

```bash
supabase login
PROJECT_REF=xxxxxx TEXT_LK_KEY=your-textlk-bearer-token bash supabase/setup.sh
# Follow the 2 manual steps the script prints (Auth Hook + Phone provider)
```

### Manual steps

```bash
supabase link --project-ref <ref>
supabase db push
supabase functions deploy textlk-sms --no-verify-jwt
supabase secrets set TEXT_LK_API_KEY="..." TEXT_LK_SENDER_ID="SchoolBus"
```

### Dashboard configuration (manual, after CLI)

| Step | Location | Action |
|---|---|---|
| **Send SMS hook** | Authentication → Auth Hooks | Enable → HTTPS → URL: `https://<ref>.functions.supabase.co/textlk-sms` → Generate secret → `supabase secrets set SEND_SMS_HOOK_SECRET="..."` → Save |
| **Phone provider** | Authentication → Providers → Phone | Toggle ON |

## Edge Functions

| Function | Path | Description |
|---|---|---|
| `textlk-sms` | `supabase/functions/textlk-sms/index.ts` | **Active** — Auth Hook that forwards OTPs to Text.lk API v3. Deployed with `--no-verify-jwt`. |
| `send-otp` | `supabase/functions/send-otp/index.ts` | **Legacy** — replaced by Supabase Auth phone OTP + hook |
| `verify-otp` | `supabase/functions/verify-otp/index.ts` | **Legacy** — replaced by Supabase Auth phone OTP + hook |

## Secrets (set via `supabase secrets set`)

| Secret | Required | Source |
|---|---|---|
| `TEXT_LK_API_KEY` | Yes | Text.lk dashboard → API token |
| `TEXT_LK_SENDER_ID` | Yes | Alphanumeric sender name (max 11 chars) |
| `SEND_SMS_HOOK_SECRET` | Yes | Supabase dashboard Auth Hook → "Generate secret" |

## Platforms

All six: Android, iOS, Linux, macOS, Web, Windows.

## No CI/CD

Not configured. Add workflows under `.github/workflows/` when needed.
