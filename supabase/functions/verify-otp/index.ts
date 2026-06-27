// Supabase Edge Function: verify-otp
// Checks the code against otp_codes table and returns the user's role.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  try {
    const { phone_number, code } = await req.json();

    if (!phone_number || !code) {
      return new Response(
        JSON.stringify({ error: "phone_number and code are required" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Verify OTP
    const { data: otp, error: otpError } = await supabase
      .from("otp_codes")
      .select("*")
      .eq("phone_number", phone_number)
      .eq("code", code)
      .eq("used", false)
      .gte("expires_at", new Date().toISOString())
      .order("created_at", { ascending: false })
      .limit(1)
      .single();

    if (otpError || !otp) {
      return new Response(
        JSON.stringify({ error: "Invalid or expired code" }),
        { status: 401, headers: { "Content-Type": "application/json" } }
      );
    }

    // Mark OTP as used
    await supabase.from("otp_codes").update({ used: true }).eq("id", otp.id);

    // Fetch user info
    const { data: user } = await supabase
      .from("users_whitelist")
      .select("id, phone_number, role")
      .eq("phone_number", phone_number)
      .single();

    return new Response(
      JSON.stringify({ success: true, user }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: err.message }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
