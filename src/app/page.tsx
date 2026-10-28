import { ArrowRight } from "lucide-react";
import Link from "next/link";
import { redirect } from "next/navigation";
import { Cover } from "@/components/books/cover";
import { CurrentlyReading } from "@/components/journal/currently-reading";
import { MonthlyPick } from "@/components/journal/monthly-pick";
import { PunchCard } from "@/components/journal/punch-card";
import { Page, SectionTitle } from "@/components/shell/page";
import { DemoBanner } from "@/components/shell/demo-banner";
import { getClubMonth, getMonthlyPicks, getShelf, getViewer } from "@/lib/data";
import { monthStart } from "@/lib/month";

export default async function JournalPage() {
  const viewer = await getViewer();
  if (!viewer) redirect("/login");
  const { profile } = viewer;
  const month = monthStart();
  const [shelf, picks, club] = await Promise.all([getShelf(profile.id), getMonthlyPicks(profile.id), getClubMonth(month)]);

  const read = shelf.filter((b) => b.status === "read");
  const readThisMonth = read.filter((b) => b.finished_at && b.finished_at >= month);
  const goal = profile.monthly_goal;
  const hour = new Date().getHours();
  const greeting = hour < 12 ? "Good morning" : hour < 18 ? "Good afternoon" : "Good evening";

  return (
    <Page kicker={new Date().toLocaleDateString("en-US", { weekday: "long", month: "long", day: "numeric" })} title={`${greeting}, ${profile.display_name.split(" ")[0] || profile.username}`}>
      {viewer.demo && <DemoBanner />}
      <PunchCard totalRead={read.length} name={profile.display_name || profile.username} />

      <SectionTitle>Monthly goal</SectionTitle>
      <section className="paper p-5">
        <div className="flex items-baseline justify-between">
          <p className="font-serif text-3xl">
            {readThisMonth.length}
            <span className="text-lg text-muted"> / {goal} books</span>
          </p>
          <p className="font-type text-[12px] text-muted">{readThisMonth.length >= goal ? "Goal met — badge earned!" : `${goal - readThisMonth.length} more for your badge`}</p>
        </div>
        <div className="mt-3 flex gap-1.5">
          {Array.from({ length: goal }, (_, i) => (
            <span key={i} className={`h-2 flex-1 rounded-full ${i < readThisMonth.length ? "bg-stamp" : "bg-paper-2"}`} />
          ))}
        </div>
      </section>

      <SectionTitle>On the nightstand</SectionTitle>
      <CurrentlyReading initial={shelf.filter((b) => b.status === "reading")} />

      <SectionTitle>Your pick of the month</SectionTitle>
      <MonthlyPick month={month} current={picks.find((p) => p.month === month) ?? null} candidates={readThisMonth.map((b) => b.book)} />

      {club && (
        <>
          <SectionTitle
            action={
              <Link href="/club" className="flex items-center gap-1 text-[13px] text-muted">
                Club <ArrowRight className="size-3.5" />
              </Link>
            }
          >
            This month&apos;s book club
          </SectionTitle>
          <Link href="/club" className="paper flex items-center gap-4 p-4">
            <Cover book={club.book} className="w-16" />
            <div className="min-w-0">
              <p className="font-serif text-lg leading-snug">{club.book.title}</p>
              <p className="text-[13px] text-muted">{club.book.authors.join(", ")}</p>
              <p className="mt-1.5 line-clamp-2 text-[13px] text-ink-soft">{club.blurb}</p>
            </div>
          </Link>
        </>
      )}
    </Page>
  );
}
