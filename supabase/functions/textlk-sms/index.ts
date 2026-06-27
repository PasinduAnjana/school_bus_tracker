// Supabase Auth Send SMS Hook — Text.lk
// Uses Standard Webhooks spec. Supabase sends:
//   { "user": { "phone": "+9471..." }, "sms": { "otp": "123456" } }
//
// Env vars:
//   TEXT_LK_API_KEY     — Bearer token from Text.lk dashboard
//   TEXT_LK_SENDER_ID   — Sender name (default: SchoolBus)
//   SEND_SMS_HOOK_SECRET — Full secret from Auth Hook config (v1,whsec_...)

import { Webhook } from "https://esm.sh/standardwebhooks@1.0.0";
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const TEXT_LK_API_KEY = Deno.env.get("TEXT_LK_API_KEY") ?? "";
const SENDER_ID = Deno.env.get("TEXT_LK_SENDER_ID") ?? "SchoolBus";
const HOOK_SECRET = Deno.env.get("SEND_SMS_HOOK_SECRET") ?? "";

serve(async (req) => {
  try {
    const payload = await req.text();
    const headers = Object.fromEntries(req.headers);

    const wh = new Webhook(HOOK_SECRET.replace("v1,whsec_", ""));
    const { user, sms } = wh.verify(payload, headers);

    const phone = user.phone.replace(/^\+/, "");
    const message = `Your OTP is: ${sms.otp}`;

    const smsResponse = await fetch(
      "https://app.text.lk/api/v3/sms/send",
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${TEXT_LK_API_KEY}`,
          "Content-Type": "application/json",
          Accept: "application/json",
        },
        body: JSON.stringify({
          recipient: phone,
          sender_id: SENDER_ID,
          type: "plain",
          message,
        }),
      },
    );

    if (!smsResponse.ok) {
      const errText = await smsResponse.text();
      console.error("Text.lk error:", smsResponse.status, errText);
      return new Response(
        JSON.stringify({ error: "Failed to send SMS" }),
        { status: 502, headers: { "Content-Type": "application/json" } },
      );
    }

    return new Response(JSON.stringify({}), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (err) {
    console.error("textlk-sms error:", err.message);
    return new Response(
      JSON.stringify({ error: err.message }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});
