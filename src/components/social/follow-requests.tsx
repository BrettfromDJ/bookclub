"use client";

import Link from "next/link";
import { useState, useTransition } from "react";
import { answerFollowRequest } from "@/app/actions";
import { Avatar } from "@/components/social/avatar";
import { Button } from "@/components/ui/button";
import type { Activity } from "@/lib/types";

export function FollowRequests({ initial }: { initial: { follower_id: string; profile: Activity["profile"] }[] }) {
  const [requests, setRequests] = useState(initial);
  const [, start] = useTransition();
  if (!requests.length) return null;
  const answer = (id: string, accept: boolean) => {
    setRequests((r) => r.filter((x) => x.follower_id !== id));
    start(async () => void (await answerFollowRequest(id, accept)));
  };
  return (
    <section className="paper mb-4 p-4">
      <p className="label mb-3">Follow requests</p>
      <ul className="space-y-3">
        {requests.map((r) => (
          <li key={r.follower_id} className="flex items-center gap-3">
            <Avatar url={r.profile.avatar_url} name={r.profile.display_name || r.profile.username} />
            <Link href={`/u/${r.profile.username}`} className="flex-1 font-semibold">
              {r.profile.display_name || r.profile.username}
            </Link>
            <Button size="sm" variant="primary" onClick={() => answer(r.follower_id, true)}>
              Accept
            </Button>
            <Button size="sm" variant="ghost" onClick={() => answer(r.follower_id, false)}>
              Decline
            </Button>
          </li>
        ))}
      </ul>
    </section>
  );
}
