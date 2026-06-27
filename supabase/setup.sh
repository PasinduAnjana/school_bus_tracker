#!/usr/bin/env bash
# setup.sh — one-command bootstrap for a new Supabase project
# Usage:  PROJECT_REF=xxxxxx TEXT_LK_KEY=xxx  bash supabase/setup.sh
#
# Prerequisites:  supabase CLI installed & logged in (`supabase login`)
#                  a Supabase project already created on dashboard.supabase.com

set -euo pipefail

PROJECT_REF="${PROJECT_REF:?Must set PROJECT_REF (from your Supabase dashboard URL)}"
TEXT_LK_KEY="${TEXT_LK_KEY:?Must set TEXT_LK_KEY (Bearer token from Text.lk dashboard)}"
TEXT_LK_SENDER="${TEXT_LK_SENDER:-SchoolBus}"

echo "==> 1. Linking project $PROJECT_REF …"
supabase link --project-ref "$PROJECT_REF"

echo ""
echo "==> 2. Pushing database migrations …"
supabase db push

echo ""
echo "==> 3. Deploying Edge Functions …"
supabase functions deploy textlk-sms --no-verify-jwt

echo ""
echo "==> 4. Setting secrets …"
supabase secrets set \
  TEXT_LK_API_KEY="$TEXT_LK_KEY" \
  TEXT_LK_SENDER_ID="$TEXT_LK_SENDER"

echo ""
echo "==> 5. Configuring Auth Hook (Send SMS) …"
FN_URL="https://${PROJECT_REF}.functions.supabase.co/textlk-sms"
echo ""
echo "       ┌─────────────────────────────────────────────────────────────┐"
echo "       │  MANUAL STEP — Supabase Dashboard                           │"
echo "       │                                                             │"
echo "       │  1. Go to Authentication → Auth Hooks                       │"
echo "       │  2. Enable "Send SMS hook" → HTTPS                          │"
echo "       │  3. URL:  $FN_URL  │"
echo "       │  4. Click "Generate secret", copy it                        │"
echo "       │  5. Run:  supabase secrets set SEND_SMS_HOOK_SECRET=\"...\"  │"
echo "       │  6. Paste the same secret in the Secret field               │"
echo "       │  7. Save                                                    │"
echo "       └─────────────────────────────────────────────────────────────┘"

echo ""
echo "==> 6. Enabling Phone auth provider …"
echo "       ┌─────────────────────────────────────────────────────────────┐"
echo "       │  MANUAL STEP — Supabase Dashboard                           │"
echo "       │                                                             │"
echo "       │  1. Go to Authentication → Providers → Phone                │"
echo "       │  2. Toggle ON                                               │"
echo "       └─────────────────────────────────────────────────────────────┘"

echo ""
echo "==> Done."
echo "    Next:  flutter run  (use dev bypass 0770000000 / 4592 first)"
