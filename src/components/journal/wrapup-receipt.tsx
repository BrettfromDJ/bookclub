"use client";

import { RotateCcw, Star, X } from "lucide-react";
import Link from "next/link";
import { useEffect, useState } from "react";
import { Button } from "@/components/ui/button";
import { punchHaptic, tapHaptic } from "@/lib/native";
import { cn } from "@/lib/utils";
import type { Wrapup } from "@/lib/wrapup";

/**
 * Monthly wrap-up: a receipt of the month's reads feeds out of a chrome
 * printer in little receipt-printer jerks, tears free and settles, then can be
 * scrolled and read. Timings mirror `paper-feed` / `paper-drop` in globals.css.
 */
type Phase = "idle" | "print" | "drop" | "done";

// A beat with the printer sitting idle before it starts feeding.
const IDLE_MS = 450;
const DROP_MS = 600;
// When each feed jerk starts, as a fraction of the feed duration (matches paper-feed).
const FEED_STEPS = [0, 0.14, 0.28, 0.42, 0.56, 0.7, 0.84];

export function WrapupReceipt({ wrapup, username }: { wrapup: Wrapup; username: string }) {
  const [phase, setPhase] = useState<Phase>("idle");
  const [run, setRun] = useState(0);
  // Longer receipts take a little longer to print.
  const feedMs = Math.min(6000, 2400 + wrapup.books.length * 350);

  useEffect(() => {
    setPhase("idle");
    window.scrollTo(0, 0);
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
      setPhase("done");
      return;
    }
    const timers: number[] = [];
    const at = (ms: number, fn: () => void) => timers.push(window.setTimeout(fn, ms));
    at(IDLE_MS, () => setPhase("print"));
    for (const f of FEED_STEPS) at(IDLE_MS + f * feedMs, () => void tapHaptic());
    at(IDLE_MS + feedMs, () => {
      setPhase("drop");
      void punchHaptic();
    });
    at(IDLE_MS + feedMs + DROP_MS, () => setPhase("done"));
    return () => timers.forEach(clearTimeout);
  }, [feedMs, run]);

  const done = phase === "done";
  return (
    <div className={cn("polka-denim min-h-dvh", !done && "fixed inset-0 overflow-hidden")}>
      <Link href="/" aria-label="Close" className="safe-top fixed right-4 top-3 z-30 mt-1 flex size-9 items-center justify-center rounded-full bg-paper/85 text-ink-soft backdrop-blur">
        <X className="size-4" />
      </Link>

      <div className="safe-top mx-auto flex w-full max-w-md flex-col items-center px-5 pb-16">
        {/* Printer slot: the receipt feeds out from under the slit. */}
        <div className="relative z-20 mt-14 h-11 w-full">
          <div className="printer-slot absolute inset-0 rounded-[16px]" />
          <div className="absolute inset-x-6 top-1/2 h-2 -translate-y-1/2 rounded-full bg-[#1d1f22] shadow-[inset_0_2px_3px_rgb(0_0_0/0.8)]" />
        </div>

        {/* Clipped at the slit while printing so the paper appears to come out of it. */}
        <div className={cn("relative z-10 -mt-[22px] w-[calc(100%-36px)]", phase === "drop" || done ? "overflow-visible" : "overflow-hidden")}>
          <div
            key={run}
            className={cn(phase === "idle" && "-translate-y-full", phase === "print" && "animate-paper-feed", (phase === "drop" || done) && "animate-paper-drop")}
            style={{ "--feed-ms": `${feedMs}ms` } as React.CSSProperties}
          >
            <Receipt wrapup={wrapup} username={username} />
          </div>
        </div>

        {done && (
          <div className="animate-rise mt-14 flex w-full gap-3">
            <Button variant="secondary" size="lg" className="flex-1 bg-paper" onClick={() => setRun((r) => r + 1)}>
              <RotateCcw /> Print again
            </Button>
            <Button asChild variant="primary" size="lg" className="flex-1">
              <Link href="/">Done</Link>
            </Button>
          </div>
        )}
      </div>
    </div>
  );
}

function Receipt({ wrapup, username }: { wrapup: Wrapup; username: string }) {
  const [y, m] = wrapup.month.split("-").map(Number);
  const date = new Date(y, m - 1, 1);
  const monthName = date.toLocaleDateString("en-US", { month: "long" });
  const count = wrapup.books.length;
  return (
    <div className="receipt @container relative px-5 pb-6 pt-5 text-[#1c1c1c]">
      <Rule />
      {/* Sized to the month's name so even "September Reads" fits on one line. */}
      <h1
        className="mt-4 whitespace-nowrap text-center font-serif font-semibold leading-none tracking-[-0.045em]"
        style={{ fontSize: `min(54px, calc((100cqw - 40px) / ${((monthName.length + 6) * 0.5).toFixed(2)}))` }}
      >
        {monthName} Reads
      </h1>
      <Rule className="mt-5" />
      <dl className="grid grid-cols-2 gap-x-3 gap-y-1 py-2.5 font-type text-[11.5px] uppercase leading-snug">
        <dd>
          {monthName} {y}
        </dd>
        <dd>Books read: {count}</dd>
        <dd>Average rating: {wrapup.averageRating ?? "—"}</dd>
        <dd>Pages read: {wrapup.pagesRead?.toLocaleString("en-US") ?? "—"}</dd>
      </dl>
      <Rule />
      <p className="py-2.5 font-type text-[12px] leading-snug">
        Favorite Book: {wrapup.favorite ? `${wrapup.favorite.title} by ${wrapup.favorite.authors[0] ?? "Unknown"}` : "—"}
      </p>
      <Rule />

      <ul className="space-y-4 py-5">
        {wrapup.books.map(({ book, rating }) => (
          <li key={book.id} className="flex gap-4">
            <div className="aspect-[2/3] w-[86px] shrink-0 overflow-hidden bg-[#d9d6cf] shadow-[0_1px_2px_rgb(0_0_0/0.2)]">
              {book.cover_url && (
                // eslint-disable-next-line @next/next/no-img-element -- remote covers from several hosts
                <img src={book.cover_url} alt="" onError={(e) => (e.currentTarget.style.display = "none")} className="size-full object-cover grayscale-[8%]" />
              )}
            </div>
            <div className="min-w-0 flex-1 pt-1">
              <p className="flex gap-1.5">
                <span className="shrink-0 font-serif text-[17px] font-semibold leading-tight tracking-[-0.04em]">Title:</span>
                <span className="font-type text-[12.5px] leading-snug">
                  {book.title} by {book.authors[0] ?? "Unknown"}
                </span>
              </p>
              <p className="mt-2 font-serif text-[17px] font-semibold leading-tight tracking-[-0.04em]">My Rating:</p>
              <Stars rating={rating} />
            </div>
          </li>
        ))}
        {count === 0 && <li className="py-6 text-center font-type text-[12px] uppercase leading-relaxed text-[#555]">No books finished yet.<br />The printer is standing by.</li>}
      </ul>

      <Rule />
      <p className="flex justify-between py-2.5 font-type text-[12px] font-bold uppercase">
        <span>Total</span>
        <span>{String(count).padStart(2, "0")}</span>
      </p>
      <Rule />
      <p className="pt-4 text-center font-type text-[11px] uppercase tracking-[0.12em]">@{username}</p>
      <p className="pt-1 text-center font-type text-[10px] uppercase tracking-[0.2em] text-[#666]">Thank you for reading · plottwist.pro</p>
    </div>
  );
}

function Stars({ rating }: { rating: number | null }) {
  return (
    <p className="mt-1.5 flex gap-1 pl-1" aria-label={rating ? `${rating} out of 5 stars` : "Not rated"}>
      {Array.from({ length: 5 }, (_, i) => (
        <Star key={i} className={cn("size-[22px]", rating && i < rating ? "fill-[#d8251d] text-[#d8251d]" : "text-[#c9c6bf]")} strokeWidth={rating && i < rating ? 0 : 1.5} />
      ))}
    </p>
  );
}

/** Dotted rule, like the dashes a receipt printer uses between sections. */
function Rule({ className }: { className?: string }) {
  return <div className={cn("h-0 border-t-[2px] border-dotted border-[#3a3a3a]", className)} aria-hidden />;
}
