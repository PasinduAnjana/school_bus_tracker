// Supabase Edge Function: send-otp
// Triggered from the login screen.
// 1. Looks up the phone in users_whitelist.
// 2. Generates a 4-digit OTP.
// 3. Stores it in otp_codes table.
// 4. Sends SMS via Text.lk API.
// 5. Returns the code (for dev bypass) or success flag.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const TEXT_LK_API_KEY = Deno.env.get("TEXT_LK_API_KEY") || "";
const TEXT_LK_SENDER_ID = Deno.env.get("TEXT_LK_SENDER_ID") || "SMS";
// In dev mode, a magic phone number bypasses real SMS.
const DEV_BYPASS_PHONE = Deno.env.get("DEV_BYPASS_PHONE") || "0770000000";
const DEV_BYPASS_CODE = "4592";

serve(async (req) => {
  try {
    const { phone_number } = await req.json();

    if (!phone_number) {
      return new Response(
        JSON.stringify({ error: "phone_number is required" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // Create Supabase admin client (bypasses RLS)
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Check user exists in whitelist
    const { data: user, error: userError } = await supabase
      .from("users_whitelist")
      .select("id, phone_number, role")
      .eq("phone_number", phone_number)
      .single();

    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: "Phone number not whitelisted" }),
        { status: 404, headers: { "Content-Type": "application/json" } }
      );
    }

    // Generate OTP
    const code = phone_number === DEV_BYPASS_PHONE
      ? DEV_BYPASS_CODE
      : String(Math.floor(1000 + Math.random() * 9000));

    // Store OTP
    const { error: otpError } = await supabase
      .from("otp_codes")
      .insert({
        phone_number,
        code,
        expires_at: new Date(Date.now() + 5 * 60 * 1000).toISOString(),
      });

    if (otpError) {
      throw otpError;
    }

    // Send SMS via Text.lk (skip for dev bypass)
    if (code !== DEV_BYPASS_CODE) {
      const smsPayload = {
        api_key: TEXT_LK_API_KEY,
        sender_id: TEXT_LK_SENDER_ID,
        message: `Your School Bus Tracker code: ${code}`,
        numbers: [phone_number],
      };

      const smsResponse = await fetch(
        "https://textlk.com/api/v1/send",
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(smsPayload),
        }
      );

      if (!smsResponse.ok) {
        console.error("Text.lk error:", await smsResponse.text());
      }
    }

    return new Response(
      JSON.stringify({ success: true, code }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: err.message }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
