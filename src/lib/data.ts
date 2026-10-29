import "server-only";
import { cache } from "react";
import { DEMO_BADGES, DEMO_CLUB, DEMO_FEED, DEMO_MONTHLY_PICKS, DEMO_PROFILE, DEMO_SHELF, DEMO_TOP_EIGHT } from "./demo";
import { monthStart } from "./month";
import { getServerSupabase } from "./supabase/server";
import type { Activity, Book, ClubMonth, EarnedBadge, Profile, UserBook } from "./types";

/**
 * Read side of the app. Each loader returns sample data when Supabase isn't
 * configured (demo mode) so screens can be designed before the backend exists.
 */

export type Viewer = { profile: Profile; demo: boolean } | null;

export const getViewer = cache(async (): Promise<Viewer> => {
  const supabase = await getServerSupabase();
  if (!supabase) return { profile: DEMO_PROFILE, demo: true };
  // Verified locally against the signing keys; no auth-server round trip.
  const { data: auth } = await supabase.auth.getClaims();
  if (!auth?.claims.sub) return null;
  const { data } = await supabase.from("profiles").select("*").eq("id", auth.claims.sub).single();
  return data ? { profile: data as Profile, demo: false } : null;
});

const BOOK = "book:books(*)";

export async function getShelf(userId: string): Promise<UserBook[]> {
  const supabase = await getServerSupabase();
  if (!supabase) return DEMO_SHELF;
  const { data } = await supabase.from("user_books").select(`*, ${BOOK}`).eq("user_id", userId).order("position");
  return (data ?? []) as UserBook[];
}

export async function getProfile(username: string): Promise<Profile | null> {
  const supabase = await getServerSupabase();
  if (!supabase) return username === DEMO_PROFILE.username ? DEMO_PROFILE : null;
  const { data } = await supabase.from("profiles").select("*").eq("username", username).maybeSingle();
  return (data as Profile) ?? null;
}

export async function getBadges(userId: string): Promise<EarnedBadge[]> {
  const supabase = await getServerSupabase();
  if (!supabase) return DEMO_BADGES;
  const { data } = await supabase.from("user_badges").select("badge_code, period, earned_at").eq("user_id", userId).order("earned_at");
  return (data ?? []) as EarnedBadge[];
}

export async function getTopEight(userId: string): Promise<(Book | null)[]> {
  const supabase = await getServerSupabase();
  if (!supabase) return DEMO_TOP_EIGHT;
  const { data } = await supabase.from("top_books").select(`slot, ${BOOK}`).eq("user_id", userId);
  const slots: (Book | null)[] = Array(8).fill(null);
  for (const row of (data ?? []) as unknown as { slot: number; book: Book }[]) slots[row.slot - 1] = row.book;
  return slots;
}

export async function getMonthlyPicks(userId: string): Promise<{ month: string; book: Book; note: string }[]> {
  const supabase = await getServerSupabase();
  if (!supabase) return DEMO_MONTHLY_PICKS;
  const { data } = await supabase.from("monthly_picks").select(`month, note, ${BOOK}`).eq("user_id", userId).order("month", { ascending: false });
  return (data ?? []) as unknown as { month: string; book: Book; note: string }[];
}

export async function getClubMonth(month = monthStart()): Promise<ClubMonth | null> {
  const supabase = await getServerSupabase();
  if (!supabase) return DEMO_CLUB;
  const { data } = await supabase.from("club_months").select(`*, ${BOOK}`).eq("month", month).maybeSingle();
  return (data as ClubMonth) ?? null;
}

export type FollowState = "none" | "pending" | "accepted";

export async function getFollowInfo(viewerId: string, userId: string) {
  const supabase = await getServerSupabase();
  if (!supabase) return { state: "none" as FollowState, followers: 12, following: 9 };
  const [mine, followers, following] = await Promise.all([
    supabase.from("follows").select("status").eq("follower_id", viewerId).eq("followee_id", userId).maybeSingle(),
    supabase.from("follows").select("*", { count: "exact", head: true }).eq("followee_id", userId).eq("status", "accepted"),
    supabase.from("follows").select("*", { count: "exact", head: true }).eq("follower_id", userId).eq("status", "accepted"),
  ]);
  return { state: ((mine.data?.status as FollowState) ?? "none") as FollowState, followers: followers.count ?? 0, following: following.count ?? 0 };
}

const PROFILE = "profile:profiles(username, display_name, avatar_url)";

/** Activity from people the viewer follows, plus their own. */
export async function getFeed(viewerId: string): Promise<Activity[]> {
  const supabase = await getServerSupabase();
  if (!supabase) return DEMO_FEED;
  const { data: follows } = await supabase.from("follows").select("followee_id").eq("follower_id", viewerId).eq("status", "accepted");
  const ids = [viewerId, ...(follows ?? []).map((f) => f.followee_id as string)];
  const { data } = await supabase
    .from("activities")
    .select(`*, ${BOOK}, ${PROFILE}, comments(*, ${PROFILE})`)
    .in("user_id", ids)
    .order("created_at", { ascending: false })
    .order("created_at", { referencedTable: "comments", ascending: true })
    .limit(50);
  return (data ?? []) as Activity[];
}

export async function getUserActivity(userId: string): Promise<Activity[]> {
  const supabase = await getServerSupabase();
  if (!supabase) return DEMO_FEED.slice(0, 1);
  const { data } = await supabase
    .from("activities")
    .select(`*, ${BOOK}, ${PROFILE}, comments(*, ${PROFILE})`)
    .eq("user_id", userId)
    .order("created_at", { ascending: false })
    .limit(20);
  return (data ?? []) as Activity[];
}

export async function getPendingFollowRequests(viewerId: string) {
  const supabase = await getServerSupabase();
  if (!supabase) return [];
  const { data } = await supabase
    .from("follows")
    .select("follower_id, profile:profiles!follows_follower_id_fkey(username, display_name, avatar_url)")
    .eq("followee_id", viewerId)
    .eq("status", "pending");
  return (data ?? []) as unknown as { follower_id: string; profile: Activity["profile"] }[];
}
