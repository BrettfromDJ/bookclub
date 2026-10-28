import { Crown, Lock, Settings } from "lucide-react";
import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { Cover } from "@/components/books/cover";
import { BadgeStamp } from "@/components/journal/badge-stamp";
import { LibraryCard } from "@/components/journal/library-card";
import { FeedItem } from "@/components/social/feed-item";
import { ProfileActions } from "@/components/social/profile-actions";
import { SongPlayer } from "@/components/social/song-player";
import { getBadges, getFollowInfo, getMonthlyPicks, getProfile, getShelf, getTopEight, getUserActivity, getViewer } from "@/lib/data";
import { monthLabel } from "@/lib/month";
import { skinById } from "@/lib/skins";
import { cn } from "@/lib/utils";

export async function generateMetadata({ params }: { params: Promise<{ username: string }> }) {
  const { username } = await params;
  return { title: `@${username}` };
}

export default async function ProfilePage({ params }: { params: Promise<{ username: string }> }) {
  const { username } = await params;
  const viewer = await getViewer();
  if (!viewer) redirect("/login");
  const profile = await getProfile(username);
  if (!profile) notFound();

  const isMe = profile.id === viewer.profile.id;
  const [follow, topEight, badges, shelf, picks, activity] = await Promise.all([
    getFollowInfo(viewer.profile.id, profile.id),
    getTopEight(profile.id),
    getBadges(profile.id),
    getShelf(profile.id),
    getMonthlyPicks(profile.id),
    getUserActivity(profile.id),
  ]);
  // Row-level security returns nothing for private profiles the viewer can't see.
  const locked = profile.is_private && !isMe && follow.state !== "accepted";
  const totalRead = shelf.filter((b) => b.status === "read").length;
  const skin = skinById(profile.skin);
  const heading = skin.heading === "serif" ? "font-serif" : skin.heading === "typewriter" ? "font-type" : "font-sans font-semibold";
  const uniqueBadges = [...new Set(badges.map((b) => b.badge_code))];

  return (
    <div
      className="min-h-dvh"
      style={{ ...skin.vars, background: `var(--skin-pattern), var(--skin-bg)`, backgroundColor: "var(--skin-bg)", color: "var(--skin-ink)" } as React.CSSProperties}
    >
      <main className="safe-top mx-auto w-full max-w-lg px-4 pb-32">
        <div className="flex justify-end pt-4">
          {isMe && (
            <Link href="/settings" className="flex size-10 items-center justify-center rounded-full" style={{ background: "var(--skin-card)" }} aria-label="Edit profile">
              <Settings className="size-5" />
            </Link>
          )}
        </div>

        <header className="flex flex-col items-center pt-2 text-center">
          <div className="size-28 overflow-hidden rounded-full border-4 shadow-lg" style={{ borderColor: "var(--skin-card)", background: "var(--skin-card)" }}>
            {profile.avatar_url ? (
              // eslint-disable-next-line @next/next/no-img-element -- user avatar
              <img src={profile.avatar_url} alt="" className="size-full object-cover" />
            ) : (
              <span className={cn("flex size-full items-center justify-center text-5xl", heading)}>{(profile.display_name || profile.username)[0]?.toUpperCase()}</span>
            )}
          </div>
          <h1 className={cn("mt-4 text-[30px] leading-tight", heading)}>{profile.display_name || profile.username}</h1>
          <p className="font-type text-[13px]" style={{ color: "var(--skin-muted)" }}>
            @{profile.username} {profile.is_private && <Lock className="inline size-3" />}
          </p>
          {profile.bio && <p className="mt-3 max-w-xs text-[15px] leading-relaxed">{profile.bio}</p>}
          <div className="mt-4 flex gap-6 font-type text-[12px]" style={{ color: "var(--skin-muted)" }}>
            <span>
              <b style={{ color: "var(--skin-ink)" }}>{totalRead}</b> read
            </span>
            <span>
              <b style={{ color: "var(--skin-ink)" }}>{follow.followers}</b> followers
            </span>
            <span>
              <b style={{ color: "var(--skin-ink)" }}>{follow.following}</b> following
            </span>
          </div>
          {!isMe && <ProfileActions userId={profile.id} initial={follow.state} />}
        </header>

        {profile.song_url && <SongPlayer url={profile.song_url} />}

        <SkinSection title={`${profile.display_name.split(" ")[0] || profile.username}'s Top 8`}>
          <div className="grid grid-cols-4 gap-3">
            {topEight.map((b, i) => (
              <div key={i} className="text-center">
                {b ? <Cover book={b} /> : <div className="aspect-[2/3] rounded-md border-2 border-dashed opacity-30" style={{ borderColor: "var(--skin-muted)" }} />}
                <p className="mt-1 line-clamp-1 text-[10px]" style={{ color: "var(--skin-muted)" }}>
                  {b ? b.title : `#${i + 1}`}
                </p>
              </div>
            ))}
          </div>
        </SkinSection>

        <SkinSection title="Badges" action={isMe ? <Link href="/badges" className="text-[12px] underline">Badge book</Link> : undefined}>
          {uniqueBadges.length ? (
            <div className="-mx-1 flex flex-wrap gap-x-1 gap-y-4">
              {uniqueBadges.map((code) => (
                <BadgeStamp key={code} code={code} count={badges.filter((b) => b.badge_code === code).length} />
              ))}
            </div>
          ) : (
            <p className="text-[14px]" style={{ color: "var(--skin-muted)" }}>No stamps yet.</p>
          )}
        </SkinSection>

        <div className="mt-6">
          <LibraryCard profile={profile} totalRead={totalRead} />
        </div>

        {locked ? (
          <SkinSection title="Reading journal">
            <p className="flex items-center gap-2 text-[14px]" style={{ color: "var(--skin-muted)" }}>
              <Lock className="size-4" /> This journal is private. Follow to see what they&apos;re reading.
            </p>
          </SkinSection>
        ) : (
          <>
            {picks.length > 0 && (
              <SkinSection title="Monthly picks">
                <div className="-mx-1 flex gap-3 overflow-x-auto px-1 pb-1">
                  {picks.map((p) => (
                    <div key={p.month} className="w-24 shrink-0">
                      <Cover book={p.book} />
                      <p className="mt-1.5 flex items-center gap-1 font-type text-[10px] uppercase" style={{ color: "var(--skin-muted)" }}>
                        <Crown className="size-3" /> {monthLabel(p.month).replace(/ \d+$/, "")}
                      </p>
                    </div>
                  ))}
                </div>
              </SkinSection>
            )}
            {activity.length > 0 && (
              <div className="mt-6 space-y-3">
                {activity.map((a) => (
                  <FeedItem key={a.id} activity={a} viewer={viewer.profile} />
                ))}
              </div>
            )}
          </>
        )}
      </main>
    </div>
  );
}

function SkinSection({ title, action, children }: { title: string; action?: React.ReactNode; children: React.ReactNode }) {
  return (
    <section className="mt-6 rounded-[20px] p-4 shadow-sm" style={{ background: "var(--skin-card)", color: "var(--skin-ink)" }}>
      <div className="mb-3 flex items-center justify-between">
        <h2 className="font-type text-[11px] uppercase tracking-[0.14em]" style={{ color: "var(--skin-accent)" }}>
          {title}
        </h2>
        {action}
      </div>
      {children}
    </section>
  );
}
