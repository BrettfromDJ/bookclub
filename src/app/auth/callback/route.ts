import type { EmailOtpType } from "@supabase/supabase-js";
import { NextResponse } from "next/server";
import { getServerSupabase } from "@/lib/supabase/server";

/** Finishes a magic-link sign-in (PKCE `?code=` or `?token_hash=&type=`). */
export async function GET(req: Request) {
  const url = new URL(req.url);
  const code = url.searchParams.get("code");
  const tokenHash = url.searchParams.get("token_hash");
  const type = url.searchParams.get("type") as EmailOtpType | null;
  const supabase = await getServerSupabase();

  let error = url.searchParams.get("error_description");
  if (!error && supabase) {
    if (code) error = (await supabase.auth.exchangeCodeForSession(code)).error?.message ?? null;
    else if (tokenHash && type) error = (await supabase.auth.verifyOtp({ token_hash: tokenHash, type })).error?.message ?? null;
    else error = "That sign-in link is incomplete. Request a new one.";
  }
  return NextResponse.redirect(new URL(error ? `/login?error=${encodeURIComponent(error)}` : "/", url.origin));
}
