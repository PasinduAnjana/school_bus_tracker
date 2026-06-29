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
- **Auth uses Supabase Auth phone OTP** — `signInWithOtp()` / `verifyOTP()` manage session automatically. RLS policies (`auth.role() = 'authenticated'`) work because the user has a real JWT after verification.
- **Custom SMS provider (Text.lk)** — a Supabase Auth Hook (Send SMS hook) forwards OTPs to Text.lk via the `textlk-sms` Edge Function.
- **Phone number format**: Supabase Auth strips the `+` prefix from returned phone numbers. The app normalises it before whitelist lookups.

## Structure

- `lib/main.dart` — entrypoint, initializes Supabase + dotenv + providers
- `lib/app.dart` — MaterialApp with role-based routing via `Consumer<AuthProvider>`
- `lib/config/` — `app_theme.dart` (yellow `#FFD700` palette), `supabase_config.dart` (reads from `.env`), `dev_bypass.dart`
- `lib/models/` — `user.dart`, `route_model.dart`, `student.dart`, `payment.dart`, `gps_location.dart`
- `lib/providers/` — `auth_provider.dart` (phone → OTP → role lookup), admin/driver/parent providers
- `lib/screens/` — login, OTP, admin shell (3 tabs), driver shell, parent shell
- `lib/widgets/` — `squishy_button.dart` (bounce animation), `frosted_card.dart` (glassmorphism), `otp_field.dart`
- `lib/design.md` — color palette, animation spec, SVG asset inventory
- `supabase/` — migrations, Edge Functions, config, setup script

## Migrating to a new Supabase project

Use the automated script, or follow the manual steps below.

### Automated (preferred)

```bash
# 1. Prerequisites
supabase login
# grab PROJECT_REF from your new project URL (https://supabase.com/dashboard/project/<ref>)

# 2. Run setup
PROJECT_REF=xxxxxx TEXT_LK_KEY=your-textlk-bearer-token bash supabase/setup.sh

# 3. Follow the 2 manual steps the script prints (Auth Hook + Phone provider)
```

### Manual steps

```bash
# 1. Link the project
supabase link --project-ref <your-project-ref>

# 2. Push database schema (migrations)
supabase db push

# 3. Deploy the Text.lk SMS hook function
supabase functions deploy textlk-sms --no-verify-jwt

# 4. Set required secrets
supabase secrets set \
  TEXT_LK_API_KEY="your-textlk-api-token" \
  TEXT_LK_SENDER_ID="SchoolBus"
```

### Dashboard configuration (manual, after CLI steps)

| Step | Location | Action |
|---|---|---|
| **Send SMS hook** | Authentication → Auth Hooks | Enable → HTTPS → URL: `https://<ref>.functions.supabase.co/textlk-sms` → Generate secret → `supabase secrets set SEND_SMS_HOOK_SECRET="..."` → Save |
| **Phone provider** | Authentication → Providers → Phone | Toggle ON |

### Environment variables (Flutter)

Copy `.env.example` to `.env` and fill in:

```
SUPABASE_URL=https://<ref>.supabase.co
SUPABASE_ANON_KEY=<anon-key-from-dashboard>
```

The anon key must be the **full key** from Project Settings → API (includes the `eyJ...` JWT header).

### Insert test users

```sql
INSERT INTO users_whitelist (phone_number, role) VALUES
  ('+94771234567', 'Admin'),
  ('+94771234568', 'Driver'),
  ('+94771234569', 'Parent');
```

Run this in the Supabase dashboard SQL Editor after migrations are pushed.

### Verify

```bash
flutter run
# Enter a phone number that exists in users_whitelist → receive SMS → enter 6-digit OTP
```

## Edge Functions

| Function | Path | Description |
|---|---|---|
| `textlk-sms` | `supabase/functions/textlk-sms/index.ts` | **Active** — Auth Hook that forwards OTPs to Text.lk API v3. Deployed with `--no-verify-jwt`. |
| `send-otp` | `supabase/functions/send-otp/index.ts` | **Legacy** — replaced by Supabase Auth phone OTP + hook. |
| `verify-otp` | `supabase/functions/verify-otp/index.ts` | **Legacy** — replaced by Supabase Auth phone OTP + hook. |

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
