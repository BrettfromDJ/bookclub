import { ArrowRight, ReceiptText } from "lucide-react";
import Link from "next/link";
import { redirect } from "next/navigation";
import { Cover } from "@/components/books/cover";
import { CurrentlyReading } from "@/components/journal/currently-reading";
import { GoalShelf } from "@/components/journal/goal-shelf";
import { MonthlyPick } from "@/components/journal/monthly-pick";
import { PunchCard } from "@/components/journal/punch-card";
import { Page, SectionTitle } from "@/components/shell/page";
import { DemoBanner } from "@/components/shell/demo-banner";
import { getClubMonth, getMonthlyPicks, getShelf, getViewer } from "@/lib/data";
import { monthStart } from "@/lib/month";
import { previousMonth } from "@/lib/wrapup";

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
        <GoalShelf goal={goal} finished={readThisMonth.map((b) => b.book)} />
      </section>

      <SectionTitle
        action={
          <Link href={`/wrapup?month=${previousMonth(month).slice(0, 7)}`} className="flex items-center gap-1 text-[13px] text-muted">
            Last month <ArrowRight className="size-3.5" />
          </Link>
        }
      >
        Monthly wrap-up
      </SectionTitle>
      <Link href="/wrapup" className="paper flex items-center gap-4 p-4 active:scale-[0.99]">
        <span className="flex size-12 shrink-0 items-center justify-center rounded-full bg-paper-2">
          <ReceiptText className="size-6 text-ink-soft" strokeWidth={1.6} />
        </span>
        <span className="min-w-0 flex-1">
          <span className="block font-serif text-lg leading-snug">Print your {new Date().toLocaleDateString("en-US", { month: "long" })} receipt</span>
          <span className="block text-[13px] text-muted">
            {readThisMonth.length} {readThisMonth.length === 1 ? "book" : "books"} so far this month
          </span>
        </span>
        <ArrowRight className="size-4 text-muted" />
      </Link>

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
            <Cover book={club.book} className="w-24" />
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
