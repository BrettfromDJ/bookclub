import { redirect } from "next/navigation";
import { Page } from "@/components/shell/page";
import { FeedItem } from "@/components/social/feed-item";
import { FollowRequests } from "@/components/social/follow-requests";
import { getFeed, getPendingFollowRequests, getViewer } from "@/lib/data";

export const metadata = { title: "Friends" };

export default async function FeedPage() {
  const viewer = await getViewer();
  if (!viewer) redirect("/login");
  const [feed, requests] = await Promise.all([getFeed(viewer.profile.id), getPendingFollowRequests(viewer.profile.id)]);
  return (
    <Page kicker="What your friends are reading" title="Friends">
      <FollowRequests initial={requests} />
      <div className="space-y-3">
        {feed.map((a) => (
          <FeedItem key={a.id} activity={a} viewer={viewer.profile} />
        ))}
        {feed.length === 0 && <p className="paper ruled px-5 py-8 font-serif text-lg text-ink-soft">Follow a few readers to fill your feed.</p>}
      </div>
    </Page>
  );
}
