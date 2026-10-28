import { punchCard } from "@/lib/punch-card";
import { cn } from "@/lib/utils";

/** Coffee-shop punch card: one hole per finished book, ten per card. */
export function PunchCard({ totalRead, name }: { totalRead: number; name: string }) {
  const card = punchCard(totalRead);
  return (
    <section className="paper relative overflow-hidden p-5">
      <div className="flex items-start justify-between">
        <div>
          <p className="label">Reader&apos;s punch card · No. {card.cardNumber}</p>
          <p className="mt-1 font-serif text-xl">{name}</p>
        </div>
        <p className="rounded-full border border-stamp/40 px-2.5 py-0.5 font-type text-[11px] text-stamp">
          {card.punched === card.holes ? "Card full!" : `${card.toNextCard} to go`}
        </p>
      </div>
      <ol className="mt-5 grid grid-cols-5 gap-3" aria-label={`${card.punched} of ${card.holes} punched`}>
        {Array.from({ length: card.holes }, (_, i) => {
          const punched = i < card.punched;
          return (
            <li key={i} className="flex aspect-square items-center justify-center rounded-full border-2 border-dashed border-line-strong">
              {punched ? (
                <span
                  className="animate-punch size-[72%] rounded-full bg-paper-2 shadow-[inset_0_2px_4px_rgb(42_36_28/0.35)]"
                  style={{ animationDelay: `${i * 40}ms` }}
                />
              ) : (
                <span className={cn("font-type text-xs text-muted")}>{i + 1}</span>
              )}
            </li>
          );
        })}
      </ol>
      {card.completedCards > 0 && <p className="mt-4 text-center font-type text-[11px] text-muted">{card.completedCards} full card{card.completedCards > 1 ? "s" : ""} on file</p>}
    </section>
  );
}
