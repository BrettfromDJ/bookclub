"use client";

import { Ban, Flag, MoreHorizontal, Share } from "lucide-react";
import { useState, useTransition } from "react";
import { toast } from "sonner";
import { block, follow, report, unfollow } from "@/app/actions";
import { Button } from "@/components/ui/button";
import type { FollowState } from "@/lib/data";
import { shareLink, tapHaptic } from "@/lib/native";

export function ProfileActions({ userId, initial }: { userId: string; initial: FollowState }) {
  const [state, setState] = useState(initial);
  const [menu, setMenu] = useState(false);
  const [, start] = useTransition();

  const toggle = () => {
    void tapHaptic();
    const next: FollowState = state === "none" ? "accepted" : "none";
    setState(next);
    start(async () => {
      const res = next === "none" ? await unfollow(userId) : await follow(userId);
      if (!res.ok) toast(res.error);
    });
  };

  return (
    <div className="relative mt-5 flex gap-2">
      <Button
        onClick={toggle}
        className="min-w-28"
        style={state === "none" ? { background: "var(--skin-accent)", color: "white" } : { background: "var(--skin-card)", color: "var(--skin-ink)" }}
      >
        {state === "none" ? "Follow" : state === "pending" ? "Requested" : "Following"}
      </Button>
      <Button size="icon" style={{ background: "var(--skin-card)", color: "var(--skin-ink)" }} onClick={() => void shareLink("Book Club profile", location.href)} aria-label="Share profile">
        <Share />
      </Button>
      <Button size="icon" style={{ background: "var(--skin-card)", color: "var(--skin-ink)" }} onClick={() => setMenu((m) => !m)} aria-label="More">
        <MoreHorizontal />
      </Button>
      {menu && (
        <div className="paper absolute right-0 top-12 z-20 w-44 overflow-hidden p-1 text-left text-[14px] text-ink">
          <button
            className="flex w-full items-center gap-2 rounded-xl px-3 py-2 hover:bg-paper-2"
            onClick={() => {
              setMenu(false);
              start(async () => void toast((await report("user", userId, "")).ok ? "Thanks — we'll review this profile." : "Couldn't send report."));
            }}
          >
            <Flag className="size-4" /> Report
          </button>
          <button
            className="flex w-full items-center gap-2 rounded-xl px-3 py-2 text-stamp hover:bg-paper-2"
            onClick={() => {
              setMenu(false);
              if (!confirm("Block this reader? They won't see your journal and you won't see theirs.")) return;
              start(async () => {
                const res = await block(userId);
                toast(res.ok ? "Blocked." : res.error);
              });
            }}
          >
            <Ban className="size-4" /> Block
          </button>
        </div>
      )}
    </div>
  );
}
