"use client";

import { Flag, MessageCircle, Send } from "lucide-react";
import Link from "next/link";
import { useState, useTransition } from "react";
import { toast } from "sonner";
import { addComment, report } from "@/app/actions";
import { Cover } from "@/components/books/cover";
import { BadgeStamp } from "@/components/journal/badge-stamp";
import { Avatar } from "@/components/social/avatar";
import { badgeByCode } from "@/lib/badges";
import type { Activity, Comment, Profile } from "@/lib/types";

const VERB = { started: "started reading", finished: "finished", monthly_pick: "crowned their monthly pick", badge: "earned a badge" } as const;

function ago(iso: string) {
  const s = (Date.now() - new Date(iso).getTime()) / 1000;
  if (s < 3600) return `${Math.max(1, Math.round(s / 60))}m`;
  if (s < 86400) return `${Math.round(s / 3600)}h`;
  return `${Math.round(s / 86400)}d`;
}

export function FeedItem({ activity, viewer }: { activity: Activity; viewer: Pick<Profile, "id" | "username" | "display_name" | "avatar_url"> }) {
  const [comments, setComments] = useState<Comment[]>(activity.comments);
  const [showInput, setShowInput] = useState(false);
  const [body, setBody] = useState("");
  const [, start] = useTransition();
  const who = activity.profile;

  const submit = (e: React.FormEvent) => {
    e.preventDefault();
    const text = body.trim();
    if (!text) return;
    setComments((c) => [...c, { id: `temp-${Date.now()}`, user_id: viewer.id, body: text, created_at: new Date().toISOString(), profile: viewer }]);
    setBody("");
    start(async () => {
      const res = await addComment(activity.id, text);
      if (!res.ok) toast(res.error);
    });
  };

  return (
    <article className="paper p-4">
      <header className="flex items-center gap-3">
        <Link href={`/u/${who.username}`}>
          <Avatar url={who.avatar_url} name={who.display_name || who.username} />
        </Link>
        <p className="min-w-0 flex-1 text-[14px] leading-snug">
          <Link href={`/u/${who.username}`} className="font-semibold">
            {who.display_name || who.username}
          </Link>{" "}
          <span className="text-ink-soft">{VERB[activity.kind]}</span>
        </p>
        <time className="font-type text-[11px] text-muted">{ago(activity.created_at)}</time>
      </header>

      {activity.book && (
        <div className="mt-3 flex gap-3 rounded-2xl bg-paper-2/60 p-3">
          <Cover book={activity.book} className="w-12" />
          <div className="min-w-0">
            <p className="font-serif text-[17px] leading-snug">{activity.book.title}</p>
            <p className="text-[13px] text-muted">{activity.book.authors.join(", ")}</p>
          </div>
        </div>
      )}
      {activity.badge_code && (
        <div className="mt-3 flex items-center gap-4 rounded-2xl bg-paper-2/60 p-3">
          <BadgeStamp code={activity.badge_code} size="sm" />
          <div>
            <p className="font-serif text-[17px]">{badgeByCode(activity.badge_code)?.name}</p>
            <p className="text-[13px] text-muted">{badgeByCode(activity.badge_code)?.description}</p>
          </div>
        </div>
      )}

      {comments.length > 0 && (
        <ul className="mt-3 space-y-2">
          {comments.map((c) => (
            <li key={c.id} className="group flex gap-2 text-[14px]">
              <Avatar url={c.profile.avatar_url} name={c.profile.display_name || c.profile.username} className="size-7 text-xs" />
              <p className="min-w-0 flex-1 rounded-2xl bg-paper-2/60 px-3 py-1.5">
                <Link href={`/u/${c.profile.username}`} className="font-semibold">
                  {c.profile.display_name || c.profile.username}
                </Link>{" "}
                {c.body}
              </p>
              {c.user_id !== viewer.id && (
                <button
                  aria-label="Report comment"
                  className="self-center p-1 text-muted opacity-60 hover:opacity-100"
                  onClick={() => start(async () => void toast((await report("comment", c.id, "")).ok ? "Thanks — we'll review it." : "Couldn't send report."))}
                >
                  <Flag className="size-3.5" />
                </button>
              )}
            </li>
          ))}
        </ul>
      )}

      {showInput ? (
        <form onSubmit={submit} className="mt-3 flex items-center gap-2">
          <input
            autoFocus
            value={body}
            maxLength={1000}
            onChange={(e) => setBody(e.target.value)}
            placeholder="Say something nice…"
            className="h-10 flex-1 rounded-full border border-line-strong bg-card px-4 text-[14px] outline-none focus:border-ink/40"
          />
          <button type="submit" className="flex size-10 items-center justify-center rounded-full bg-ink text-paper disabled:opacity-40" disabled={!body.trim()} aria-label="Send">
            <Send className="size-4" />
          </button>
        </form>
      ) : (
        <button onClick={() => setShowInput(true)} className="mt-3 flex items-center gap-1.5 text-[13px] text-muted">
          <MessageCircle className="size-4" /> Comment
        </button>
      )}
    </article>
  );
}
