import { punchCard } from "@/lib/punch-card";

const CARD = "rounded-[6px] border border-[#e6d9b8] bg-[#fbf4e0] bg-[image:var(--grain)] shadow-[0_1px_1px_rgb(42_36_28/0.12),0_10px_24px_-10px_rgb(42_36_28/0.35)]";

/**
 * Coffee-shop punch card printed on cream card stock: one hole per finished
 * book, ten per card. It sits a little crooked, with a tear-off stub, and full
 * cards stack up underneath.
 */
export function PunchCard({ totalRead, name }: { totalRead: number; name: string }) {
  const card = punchCard(totalRead);
  const stacked = Math.min(card.completedCards - (card.punched === card.holes ? 1 : 0), 2);
  return (
    <div className="relative mx-1 mb-3 mt-2">
      {Array.from({ length: Math.max(0, stacked) }, (_, i) => (
        <div key={i} aria-hidden className={`${CARD} absolute inset-0`} style={{ transform: `rotate(${i === 0 ? 2.2 : -3.4}deg) translate(${i === 0 ? 6 : -4}px, ${6 + i * 4}px)` }} />
      ))}

      <section className={`${CARD} relative flex -rotate-[1.5deg] overflow-hidden`}>
        {/* Tear-off stub, separated by a perforated line */}
        <div className="relative flex w-14 shrink-0 flex-col items-center justify-center border-r-2 border-dotted border-[#cdbb92] py-4">
          <p className="font-type text-[10px] uppercase tracking-[0.2em] text-stamp/80 [writing-mode:vertical-rl] rotate-180">Card No.</p>
          <p className="mt-1 font-serif text-2xl text-stamp">{card.cardNumber}</p>
        </div>

        <div className="relative min-w-0 flex-1 p-4 pl-5">
          <p className="font-type text-[10px] uppercase tracking-[0.22em] text-stamp/80">Reader&apos;s punch card</p>
          <p className="mt-0.5 truncate font-serif text-xl text-ink">{name}</p>

          <ol className="mt-4 grid grid-cols-5 gap-2.5" aria-label={`${card.punched} of ${card.holes} punched`}>
            {Array.from({ length: card.holes }, (_, i) => {
              const punched = i < card.punched;
              return (
                <li key={i} className="relative flex aspect-square items-center justify-center rounded-full border-[1.5px] border-stamp/60">
                  {punched ? (
                    // A real hole: the page behind shows through, with the cut edge in shadow.
                    <span
                      className="animate-punch size-[78%] rounded-full bg-paper bg-[image:var(--grain)] shadow-[inset_0_2px_3px_rgb(42_36_28/0.45),0_1px_0_rgb(255_255_255/0.7)]"
                      style={{ animationDelay: `${i * 40}ms` }}
                    />
                  ) : (
                    <span className="font-type text-[13px] text-stamp/70">{i + 1}</span>
                  )}
                </li>
              );
            })}
          </ol>

          <p
            className="animate-stamp pointer-events-none absolute right-3 top-3 rounded-[4px] border-2 border-stamp/80 px-2 py-0.5 font-type text-[11px] font-bold uppercase tracking-widest text-stamp/80 mix-blend-multiply"
            style={{ outline: "1px solid rgb(181 67 47 / 0.5)", outlineOffset: "2px" }}
          >
            {card.punched === card.holes ? "Card full" : `${card.toNextCard} to go`}
          </p>

          {card.completedCards > 0 && (
            <p className="mt-3 font-type text-[10px] uppercase tracking-[0.18em] text-muted">
              {card.completedCards} full card{card.completedCards > 1 ? "s" : ""} on file
            </p>
          )}
        </div>
      </section>
    </div>
  );
}
