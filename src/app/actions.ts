"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { skinById } from "@/lib/skins";
import { songEmbed } from "@/lib/song";
import { today } from "@/lib/month";
import { getAdminSupabase, getServerSupabase } from "@/lib/supabase/server";
import type { BookCandidate, Format, ShelfStatus } from "@/lib/types";

export type Result<T = null> = { ok: true; data: T } | { ok: false; error: string };

const DEMO: Result<never> = { ok: false, error: "Demo mode — connect Supabase to save changes." };

async function session() {
  const supabase = await getServerSupabase();
  if (!supabase) return null;
  const { data } = await supabase.auth.getUser();
  if (!data.user) redirect("/login");
  return { supabase, userId: data.user.id };
}

const fail = (error: { message: string } | null): Result<never> | null => (error ? { ok: false, error: error.message } : null);

/** Saves a search result to the shared books table (or finds the existing row). */
async function ensureBook(supabase: NonNullable<Awaited<ReturnType<typeof session>>>["supabase"], b: BookCandidate) {
  await supabase.from("books").upsert(b, { onConflict: "source,external_id", ignoreDuplicates: true });
  const { data, error } = await supabase.from("books").select("id").eq("source", b.source).eq("external_id", b.external_id).single();
  if (error) throw new Error(error.message);
  return data.id as string;
}

// ---------------------------------------------------------------------------
// Shelves
// ---------------------------------------------------------------------------

export async function addToShelf(candidate: BookCandidate, formats: Format[], status: ShelfStatus = "tbr"): Promise<Result<{ id: string }>> {
  const s = await session();
  if (!s) return DEMO;
  const bookId = await ensureBook(s.supabase, candidate);
  // New TBR books go to the top.
  const { data: first } = await s.supabase.from("user_books").select("position").eq("user_id", s.userId).eq("status", "tbr").order("position").limit(1).maybeSingle();
  const { data, error } = await s.supabase
    .from("user_books")
    .insert({
      user_id: s.userId,
      book_id: bookId,
      status,
      formats,
      position: (first?.position ?? 1) - 1,
      started_at: status === "reading" ? today() : null,
      finished_at: status === "read" ? today() : null,
    })
    .select("id")
    .single();
  if (error?.code === "23505") return { ok: false, error: "That book is already on your shelves." };
  revalidatePath("/", "layout");
  return fail(error) ?? { ok: true, data: { id: data!.id } };
}

export async function moveTbr(userBookId: string, position: number): Promise<Result> {
  const s = await session();
  if (!s) return DEMO;
  const { error } = await s.supabase.from("user_books").update({ position }).eq("id", userBookId);
  return fail(error) ?? { ok: true, data: null };
}

export async function setFormats(userBookId: string, formats: Format[]): Promise<Result> {
  if (!formats.length) return { ok: false, error: "Pick at least one format." };
  const s = await session();
  if (!s) return DEMO;
  const { error } = await s.supabase.from("user_books").update({ formats }).eq("id", userBookId);
  revalidatePath("/tbr");
  return fail(error) ?? { ok: true, data: null };
}

export async function setStatus(userBookId: string, status: ShelfStatus): Promise<Result> {
  const s = await session();
  if (!s) return DEMO;
  const patch =
    status === "read" ? { status, finished_at: today() } : status === "reading" ? { status, started_at: today(), finished_at: null } : { status, finished_at: null };
  const { error } = await s.supabase.from("user_books").update(patch).eq("id", userBookId);
  revalidatePath("/", "layout");
  return fail(error) ?? { ok: true, data: null };
}

export async function removeFromShelf(userBookId: string): Promise<Result> {
  const s = await session();
  if (!s) return DEMO;
  const { error } = await s.supabase.from("user_books").delete().eq("id", userBookId);
  revalidatePath("/", "layout");
  return fail(error) ?? { ok: true, data: null };
}

export async function setMonthlyPick(bookId: string, month: string, note: string): Promise<Result> {
  const s = await session();
  if (!s) return DEMO;
  const { error } = await s.supabase.from("monthly_picks").upsert({ user_id: s.userId, month, book_id: bookId, note: note.slice(0, 500) });
  revalidatePath("/", "layout");
  return fail(error) ?? { ok: true, data: null };
}

// ---------------------------------------------------------------------------
// Profile
// ---------------------------------------------------------------------------

export type ProfilePatch = Partial<{
  username: string;
  display_name: string;
  bio: string;
  skin: string;
  song_url: string | null;
  monthly_goal: number;
  is_private: boolean;
  avatar_url: string | null;
}>;

export async function updateProfile(patch: ProfilePatch): Promise<Result> {
  if (patch.skin !== undefined && skinById(patch.skin).id !== patch.skin) return { ok: false, error: "Unknown skin." };
  if (patch.song_url && !songEmbed(patch.song_url)) return { ok: false, error: "Paste a Spotify or Apple Music song link." };
  if (patch.username !== undefined) patch.username = patch.username.toLowerCase();
  const s = await session();
  if (!s) return DEMO;
  const { error } = await s.supabase.from("profiles").update(patch).eq("id", s.userId);
  if (error?.code === "23505") return { ok: false, error: "That username is taken." };
  revalidatePath("/", "layout");
  return fail(error) ?? { ok: true, data: null };
}

export async function setTopBook(slot: number, candidate: BookCandidate | null): Promise<Result> {
  const s = await session();
  if (!s) return DEMO;
  if (!candidate) {
    const { error } = await s.supabase.from("top_books").delete().eq("user_id", s.userId).eq("slot", slot);
    revalidatePath("/", "layout");
    return fail(error) ?? { ok: true, data: null };
  }
  const bookId = await ensureBook(s.supabase, candidate);
  const { error } = await s.supabase.from("top_books").upsert({ user_id: s.userId, slot, book_id: bookId });
  revalidatePath("/", "layout");
  return fail(error) ?? { ok: true, data: null };
}

// ---------------------------------------------------------------------------
// Social
// ---------------------------------------------------------------------------

export async function follow(userId: string): Promise<Result> {
  const s = await session();
  if (!s) return DEMO;
  const { error } = await s.supabase.from("follows").insert({ follower_id: s.userId, followee_id: userId });
  revalidatePath("/", "layout");
  return fail(error) ?? { ok: true, data: null };
}

export async function unfollow(userId: string): Promise<Result> {
  const s = await session();
  if (!s) return DEMO;
  const { error } = await s.supabase.from("follows").delete().eq("follower_id", s.userId).eq("followee_id", userId);
  revalidatePath("/", "layout");
  return fail(error) ?? { ok: true, data: null };
}

export async function answerFollowRequest(followerId: string, accept: boolean): Promise<Result> {
  const s = await session();
  if (!s) return DEMO;
  const q = s.supabase.from("follows");
  const { error } = accept
    ? await q.update({ status: "accepted" }).eq("follower_id", followerId).eq("followee_id", s.userId)
    : await q.delete().eq("follower_id", followerId).eq("followee_id", s.userId);
  revalidatePath("/", "layout");
  return fail(error) ?? { ok: true, data: null };
}

export async function addComment(activityId: string, body: string): Promise<Result> {
  const text = body.trim();
  if (!text) return { ok: false, error: "Write something first." };
  const s = await session();
  if (!s) return DEMO;
  const { error } = await s.supabase.from("comments").insert({ activity_id: activityId, user_id: s.userId, body: text.slice(0, 1000) });
  revalidatePath("/feed");
  return fail(error) ?? { ok: true, data: null };
}

export async function deleteComment(commentId: string): Promise<Result> {
  const s = await session();
  if (!s) return DEMO;
  const { error } = await s.supabase.from("comments").delete().eq("id", commentId);
  revalidatePath("/feed");
  return fail(error) ?? { ok: true, data: null };
}

export async function report(targetKind: "user" | "comment" | "activity", targetId: string, reason: string): Promise<Result> {
  const s = await session();
  if (!s) return DEMO;
  const { error } = await s.supabase.from("reports").insert({ reporter_id: s.userId, target_kind: targetKind, target_id: targetId, reason: reason.slice(0, 500) });
  return fail(error) ?? { ok: true, data: null };
}

export async function block(userId: string): Promise<Result> {
  // userId is interpolated into a filter below, so it must be a plain UUID.
  if (!/^[0-9a-f-]{36}$/i.test(userId)) return { ok: false, error: "Unknown user." };
  const s = await session();
  if (!s) return DEMO;
  const { error } = await s.supabase.from("blocks").insert({ blocker_id: s.userId, blocked_id: userId });
  // Blocking also removes any follow in either direction.
  await s.supabase.from("follows").delete().or(`and(follower_id.eq.${s.userId},followee_id.eq.${userId}),and(follower_id.eq.${userId},followee_id.eq.${s.userId})`);
  revalidatePath("/", "layout");
  return fail(error) ?? { ok: true, data: null };
}

// ---------------------------------------------------------------------------
// Book club admin
// ---------------------------------------------------------------------------

export async function setClubMonth(input: {
  month: string;
  book: BookCandidate;
  blurb: string;
  partner_name?: string;
  partner_url?: string;
  partner_logo_url?: string;
}): Promise<Result> {
  const s = await session();
  if (!s) return DEMO;
  const bookId = await ensureBook(s.supabase, input.book);
  const { error } = await s.supabase.from("club_months").upsert({
    month: input.month,
    book_id: bookId,
    blurb: input.blurb,
    partner_name: input.partner_name || null,
    partner_url: input.partner_url || null,
    partner_logo_url: input.partner_logo_url || null,
  });
  revalidatePath("/", "layout");
  return fail(error) ?? { ok: true, data: null };
}

// ---------------------------------------------------------------------------
// Account
// ---------------------------------------------------------------------------

export async function signOut() {
  const supabase = await getServerSupabase();
  await supabase?.auth.signOut();
  redirect("/login");
}

/** In-app account deletion is required by App Store guideline 5.1.1(v). */
export async function deleteAccount(): Promise<Result> {
  const s = await session();
  if (!s) return DEMO;
  const admin = getAdminSupabase();
  if (!admin) return { ok: false, error: "Account deletion isn't configured (SUPABASE_SERVICE_ROLE_KEY)." };
  await admin.storage.from("avatars").remove([`${s.userId}/avatar`]);
  const { error } = await admin.auth.admin.deleteUser(s.userId);
  if (error) return { ok: false, error: error.message };
  await s.supabase.auth.signOut();
  redirect("/login");
}
