import { redirect } from "next/navigation";
import { BadgeStamp } from "@/components/journal/badge-stamp";
import { Page, SectionTitle } from "@/components/shell/page";
import { BADGES } from "@/lib/badges";
import { getBadges, getViewer } from "@/lib/data";

export const metadata = { title: "Badge Book" };

const SECTIONS = [
  { kind: "goal", title: "Monthly goals" },
  { kind: "club", title: "Book club" },
  { kind: "milestone", title: "Milestones" },
  { kind: "genre", title: "Genres" },
] as const;

export default async function BadgesPage() {
  const viewer = await getViewer();
  if (!viewer) redirect("/login");
  const earned = await getBadges(viewer.profile.id);
  const count = (code: string) => earned.filter((e) => e.badge_code === code).length;
  return (
    <Page kicker={`${new Set(earned.map((e) => e.badge_code)).size} of ${BADGES.length} collected`} title="Badge Book">
      {SECTIONS.map((s) => (
        <section key={s.kind}>
          <SectionTitle>{s.title}</SectionTitle>
          <div className="paper grid grid-cols-3 gap-y-5 px-3 py-5 sm:grid-cols-4">
            {BADGES.filter((b) => b.kind === s.kind).map((b) => (
              <BadgeStamp key={b.code} code={b.code} earned={count(b.code) > 0} count={count(b.code)} />
            ))}
          </div>
        </section>
      ))}
    </Page>
  );
}
