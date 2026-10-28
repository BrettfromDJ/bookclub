"use server";

import { headers } from "next/headers";
import type { Result } from "@/app/actions";
import { getAdminSupabase, getServerSupabase } from "@/lib/supabase/server";

/**
 * Sign-in accepts an email or a username. A username is resolved to its email
 * here on the server, and the client only ever sees a masked version, so a
 * username can't be used to look up someone's address.
 */
async function resolveEmail(identifier: string): Promise<Result<{ email: string; isUsername: boolean }>> {
  const id = identifier.trim().replace(/^@/, "");
  if (id.includes("@")) return { ok: true, data: { email: id.toLowerCase(), isUsername: false } };

  const admin = getAdminSupabase();
  if (!admin) return { ok: false, error: "Sign in with your email for now." };
  const { data: profile } = await admin.from("profiles").select("id").eq("username", id.toLowerCase()).maybeSingle();
  if (!profile) return { ok: false, error: "No account with that username. Try your email instead." };
  const { data, error } = await admin.auth.admin.getUserById(profile.id);
  if (error || !data.user?.email) return { ok: false, error: "Couldn't find an email for that account. Try your email instead." };
  return { ok: true, data: { email: data.user.email, isUsername: true } };
}

/** "darynmae@gmail.com" → "d•••••e@gmail.com" */
function maskEmail(email: string) {
  const [name, domain] = email.split("@");
  const hidden = name.length <= 2 ? `${name[0]}•` : `${name[0]}${"•".repeat(Math.min(name.length - 2, 6))}${name.at(-1)}`;
  return `${hidden}@${domain}`;
}

export async function sendSignInCode(identifier: string): Promise<Result<{ sentTo: string }>> {
  const supabase = await getServerSupabase();
  if (!supabase) return { ok: false, error: "Accounts aren't configured yet." };
  const resolved = await resolveEmail(identifier);
  if (!resolved.ok) return resolved;
  const { email, isUsername } = resolved.data;

  const h = await headers();
  const origin = h.get("origin") ?? `https://${h.get("x-forwarded-host") ?? h.get("host")}`;
  const { error } = await supabase.auth.signInWithOtp({
    email,
    // A username belongs to an existing account; only an email can create one.
    options: { emailRedirectTo: `${origin}/auth/callback`, shouldCreateUser: !isUsername },
  });
  if (error) return { ok: false, error: error.message };
  return { ok: true, data: { sentTo: isUsername ? maskEmail(email) : email } };
}

export async function verifySignInCode(identifier: string, code: string): Promise<Result> {
  const supabase = await getServerSupabase();
  if (!supabase) return { ok: false, error: "Accounts aren't configured yet." };
  const resolved = await resolveEmail(identifier);
  if (!resolved.ok) return resolved;
  const { error } = await supabase.auth.verifyOtp({ email: resolved.data.email, token: code, type: "email" });
  if (error) return { ok: false, error: error.message };
  return { ok: true, data: null };
}
