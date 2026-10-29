import { ArrowRight, FlaskConical } from "lucide-react";
import Link from "next/link";
import { redirect } from "next/navigation";
import { Page, SectionTitle } from "@/components/shell/page";
import { getViewer } from "@/lib/data";
import { monthLabel, monthStart } from "@/lib/month";
import { previousMonth } from "@/lib/wrapup";

export const metadata = { title: "Test lab" };

/**
 * Tappable previews of screens and states that are hard to reach otherwise,
 * for checking designs from the home-screen app (which has no address bar).
 * Previews use sample data and never save anything.
 */
export default async function LabPage() {
  const viewer = await getViewer();
  if (!viewer) redirect("/login");
  const month = monthStart();
  const ym = (m: string) => m.slice(0, 7);

  const wrapups = [
    { label: "Sample month", detail: "5 books, rated, with a favorite", href: `/wrapup?sample=full&month=${ym(month)}` },
    { label: "Longest month name", detail: "September, 5 books", href: "/wrapup?sample=full&month=2026-09" },
    { label: "Big month", detail: "10 books, a long receipt", href: `/wrapup?sample=many&month=${ym(month)}` },
    { label: "Just one book", detail: "The shortest full receipt", href: `/wrapup?sample=one&month=${ym(month)}` },
    { label: "No ratings yet", detail: "5 books, all empty stars", href: `/wrapup?sample=unrated&month=${ym(month)}` },
    { label: "Nothing finished", detail: "An empty month", href: `/wrapup?sample=empty&month=${ym(month)}` },
  ];
  const real = [
    { label: `Your ${monthLabel(month)}`, detail: "Your real reading this month", href: "/wrapup" },
    { label: `Your ${monthLabel(previousMonth(month))}`, detail: "Your real reading last month", href: `/wrapup?month=${ym(previousMonth(month))}` },
  ];

  return (
    <Page kicker="Previews" title="Test lab">
      <p className="flex items-start gap-2 text-[14px] text-ink-soft">
        <FlaskConical className="mt-0.5 size-4 shrink-0" /> Tap any state to preview it. Samples use made-up books and nothing is saved.
      </p>

      <SectionTitle>Monthly wrap-up · samples</SectionTitle>
      <List items={wrapups} />

      <SectionTitle>Monthly wrap-up · your data</SectionTitle>
      <List items={real} />
    </Page>
  );
}

function List({ items }: { items: { label: string; detail: string; href: string }[] }) {
  return (
    <ul className="paper divide-y divide-line overflow-hidden">
      {items.map((item) => (
        <li key={item.href}>
          <Link href={`${item.href}${item.href.includes("?") ? "&" : "?"}from=lab`} className="flex items-center gap-3 px-4 py-3.5 active:bg-paper-2">
            <span className="min-w-0 flex-1">
              <span className="block text-[15px] font-medium">{item.label}</span>
              <span className="block text-[13px] text-muted">{item.detail}</span>
            </span>
            <ArrowRight className="size-4 text-muted" />
          </Link>
        </li>
      ))}
    </ul>
  );
}
