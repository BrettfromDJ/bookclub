import { ExternalLink } from "lucide-react";
import { redirect } from "next/navigation";
import { Cover } from "@/components/books/cover";
import { BadgeStamp } from "@/components/journal/badge-stamp";
import { Page, SectionTitle } from "@/components/shell/page";
import { ClubActions } from "@/components/social/club-actions";
import { getClubMonth, getShelf, getViewer } from "@/lib/data";
import { monthLabel, monthStart } from "@/lib/month";

export const metadata = { title: "Book Club" };

export default async function ClubPage() {
  const viewer = await getViewer();
  if (!viewer) redirect("/login");
  const month = monthStart();
  const [club, shelf] = await Promise.all([getClubMonth(month), getShelf(viewer.profile.id)]);

  if (!club) {
    return (
      <Page kicker={monthLabel(month)} title="Book Club">
        <p className="paper ruled px-5 py-8 font-serif text-lg text-ink-soft">This month&apos;s pick is being chosen. Check back soon.</p>
      </Page>
    );
  }

  const mine = shelf.find((b) => b.book.source === club.book.source && b.book.external_id === club.book.external_id);
  return (
    <Page kicker={`${monthLabel(month)} · read with everyone`} title="Book Club">
      <section className="paper relative overflow-hidden p-6 text-center">
        <Cover book={club.book} className="mx-auto w-44" />
        <h2 className="mt-5 font-serif text-[26px] leading-tight">{club.book.title}</h2>
        <p className="mt-1 text-[15px] text-muted">{club.book.authors.join(", ")}</p>
        {club.blurb && <p className="mx-auto mt-4 max-w-sm text-[15px] leading-relaxed text-ink-soft">{club.blurb}</p>}
        <div className="mt-6">
          <ClubActions book={club.book} status={mine?.status ?? null} userBookId={mine?.id ?? null} />
        </div>
      </section>

      {club.partner_name && (
        <>
          <SectionTitle>In partnership with</SectionTitle>
          <a href={club.partner_url ?? undefined} target="_blank" rel="noreferrer" className="paper flex items-center gap-4 p-4">
            {club.partner_logo_url && (
              // eslint-disable-next-line @next/next/no-img-element -- partner logo URL entered by an admin
              <img src={club.partner_logo_url} alt="" className="size-12 rounded-lg object-contain" />
            )}
            <span className="flex-1 font-serif text-lg">{club.partner_name}</span>
            {club.partner_url && <ExternalLink className="size-4 text-muted" />}
          </a>
        </>
      )}

      <SectionTitle>Finish it to earn</SectionTitle>
      <div className="paper flex items-center gap-4 p-4">
        <BadgeStamp code="club:finisher" earned={mine?.status === "read"} />
        <p className="text-[14px] text-ink-soft">The Club Member stamp for {monthLabel(month).split(" ")[0]} goes in your badge book when you finish this month&apos;s pick.</p>
      </div>
    </Page>
  );
}
