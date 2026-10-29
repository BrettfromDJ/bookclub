"use client";

import { ArrowRight } from "lucide-react";
import { useEffect, useState } from "react";
import { markCardPrinted } from "@/app/actions";
import { cardNumber } from "@/components/journal/library-card";
import { Button } from "@/components/ui/button";
import { punchHaptic, tapHaptic } from "@/lib/native";
import type { Profile } from "@/lib/types";
import { cn } from "@/lib/utils";

/**
 * First sign-in welcome: the reader's library card feeds out of a printer slot
 * in little receipt-printer jerks, drops free, gets clipped into a badge sleeve
 * and stickered. Plays once per account (see `card_printed_at`).
 *
 * Timings mirror the keyframes in globals.css (`card-feed`, `card-drop`, …).
 */
type Phase = "slot" | "print" | "drop" | "dress" | "done";

const SLOT_MS = 600;
const FEED_MS = 2800;
const DROP_MS = 750;
const DRESS_MS = 1300;
// When each feed jerk starts, as a fraction of FEED_MS (matches card-feed).
const FEED_STEPS = [0, 0.14, 0.28, 0.42, 0.56, 0.7, 0.84];

export function WelcomeCard({ profile, preview = false }: { profile: Profile; preview?: boolean }) {
  const [phase, setPhase] = useState<Phase>("slot");
  const [open, setOpen] = useState(true);
  const name = profile.display_name || profile.username;
  const cardNo = cardNumber(profile);
  const since = new Date(profile.created_at).toLocaleDateString("en-US", { month: "long", year: "numeric" });

  useEffect(() => {
    // Saved up front so leaving halfway doesn't replay it next time.
    if (!preview) void markCardPrinted();
    const reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    if (reduced) {
      setPhase("done");
      return;
    }
    const timers: number[] = [];
    const at = (ms: number, fn: () => void) => timers.push(window.setTimeout(fn, ms));
    at(SLOT_MS, () => setPhase("print"));
    for (const f of FEED_STEPS) at(SLOT_MS + f * FEED_MS, () => void tapHaptic());
    at(SLOT_MS + FEED_MS, () => setPhase("drop"));
    at(SLOT_MS + FEED_MS + DROP_MS * 0.45, () => void punchHaptic(true));
    at(SLOT_MS + FEED_MS + DROP_MS, () => setPhase("dress"));
    at(SLOT_MS + FEED_MS + DROP_MS + DRESS_MS, () => setPhase("done"));
    return () => timers.forEach(clearTimeout);
  }, [preview]);

  useEffect(() => {
    if (!open) return;
    const prev = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    return () => {
      document.body.style.overflow = prev;
    };
  }, [open]);

  if (!open) return null;
  const past = (p: Phase) => ORDER.indexOf(phase) >= ORDER.indexOf(p);

  return (
    <div className={cn("polka-denim fixed inset-0 z-50 flex flex-col items-center justify-center overflow-hidden px-6", phase === "done" && "safe-bottom")} role="dialog" aria-label="Your library card">
      <button type="button" onClick={() => setOpen(false)} className="safe-top absolute right-4 top-3 rounded-full bg-paper/80 px-3 py-1 font-type text-[12px] text-ink-soft backdrop-blur" hidden={phase === "done"}>
        Skip
      </button>

      {/* Printer slot: the card feeds out from under the slit. */}
      <div className={cn("relative z-20 h-9 w-[min(372px,calc(100vw-24px))]", past("dress") ? "animate-slot-out" : "animate-slot-in")}>
        <div className="printer-slot absolute inset-0 rounded-[14px]" />
        <div className="absolute inset-x-5 top-1/2 h-[7px] -translate-y-1/2 rounded-full bg-[#1d1f22] shadow-[inset_0_2px_3px_rgb(0_0_0/0.8)]" />
      </div>

      {/* Card area; clipped at the slit while printing, free once dropped. */}
      <div className={cn("relative z-10 -mt-[18px] w-[min(340px,calc(100vw-48px))]", past("drop") ? "overflow-visible" : "overflow-hidden")}>
        <div className={cn("relative", phase === "slot" && "-translate-y-full", phase === "print" && "animate-card-feed", past("drop") && "animate-card-drop")}>
          <BadgeClip show={past("dress")} />
          <div className={cn("rounded-[18px] p-[7px] transition-[background,box-shadow] duration-500", past("dress") ? "badge-sleeve" : "bg-transparent")}>
            <MemberCard name={name} username={profile.username} since={since} cardNo={cardNo} />
            {past("dress") && <div className="sheen pointer-events-none absolute inset-0 overflow-hidden rounded-[18px]" />}
          </div>
          {past("dress") && <Stickers />}
        </div>
      </div>

      {/* Caption: status while printing, welcome when done. Fixed height so the card doesn't move. */}
      <div className="relative z-10 mt-28 flex h-44 w-full max-w-sm flex-col items-center text-center">
        {phase === "done" ? (
          <div className="paper animate-rise w-full px-5 pb-5 pt-4">
            <h2 className="font-serif text-[26px] leading-tight">Welcome to the club, {name.split(" ")[0]}.</h2>
            <p className="mt-1 font-type text-[12px] text-muted">Card no. {cardNo} · issued today</p>
            <Button variant="primary" size="lg" className="mt-4 w-full" onClick={() => setOpen(false)}>
              Open my journal <ArrowRight />
            </Button>
          </div>
        ) : (
          past("print") && (
            <p className="rounded-full bg-paper/85 px-4 py-1.5 font-type text-[12px] uppercase tracking-[0.18em] text-ink-soft backdrop-blur">
              {past("drop") ? "Laminating" : "Printing your card"}
              <span className="printing-dots" />
            </p>
          )
        )}
      </div>
    </div>
  );
}

const ORDER: Phase[] = ["slot", "print", "drop", "dress", "done"];

function MemberCard({ name, username, since, cardNo }: { name: string; username: string; since: string; cardNo: string }) {
  return (
    <div className="relative overflow-hidden rounded-[12px] bg-[#fbfaf6] px-4 pb-4 pt-3.5 text-[#1f1f1f] shadow-[0_1px_0_rgb(0_0_0/0.04)]" style={{ backgroundImage: "var(--grain)" }}>
      <p className="text-center font-serif text-[clamp(20px,6.3vw,27px)] whitespace-nowrap font-black uppercase leading-none tracking-[-0.01em]">Book Lovers Club</p>
      <div className="mt-3 flex gap-3.5">
        <div className="w-[34%] shrink-0">
          <div className="flex aspect-[4/5] items-center justify-center rounded-[3px] bg-[#e7dfcc] font-serif text-[46px] font-black text-[#6f5d43] shadow-[inset_0_0_0_1px_rgb(0_0_0/0.08)]">
            {name.trim().charAt(0).toUpperCase() || "?"}
          </div>
          <Barcode value={cardNo} />
        </div>
        <dl className="min-w-0 flex-1 space-y-[7px] font-type text-[10.5px] uppercase leading-[1.25]">
          <div className="flex gap-2">
            <Field k="Name" v={name} className="min-w-0 flex-1" />
            <Field k="Member since" v={since} className="shrink-0" />
          </div>
          <Field k="Favorite genre" v="To be discovered" />
          <Field k="Currently reading" v="Something wonderful, soon" />
          <Field k="Handle" v={`@${username}`} />
          <Field k="Mood" v="Always one more chapter" />
        </dl>
      </div>
    </div>
  );
}

function Field({ k, v, className }: { k: string; v: string; className?: string }) {
  return (
    <div className={className}>
      <dt className="text-[#555]">{k}:</dt>
      <dd className="truncate">{v}</dd>
    </div>
  );
}

/** Decorative barcode whose bar widths come from the card number. */
function Barcode({ value }: { value: string }) {
  const digits = value.replace(/\D/g, "").repeat(3).split("").map(Number);
  return (
    <div className="mt-2 flex h-7 items-stretch gap-[1.5px] overflow-hidden" aria-hidden>
      {digits.map((d, i) => (
        <span key={i} className="bg-[#1f1f1f]" style={{ width: (d % 3) + 1 }} />
      ))}
    </div>
  );
}

/** Metal badge clip on a clear strap, snapping onto the top of the sleeve. */
function BadgeClip({ show }: { show: boolean }) {
  if (!show) return null;
  return (
    <svg viewBox="0 0 60 104" className="animate-clip-in absolute -top-[68px] left-1/2 z-20 w-[50px] -translate-x-1/2 drop-shadow-[0_4px_6px_rgb(0_0_0/0.25)]" aria-hidden>
      <defs>
        <linearGradient id="clip-metal" x1="0" x2="1">
          <stop offset="0" stopColor="#8d9399" />
          <stop offset="0.35" stopColor="#f4f6f8" />
          <stop offset="0.6" stopColor="#b9bec4" />
          <stop offset="1" stopColor="#7c8288" />
        </linearGradient>
      </defs>
      <rect x="11" y="0" width="38" height="66" rx="5" fill="url(#clip-metal)" stroke="#6e747a" strokeWidth="1" />
      <rect x="23" y="8" width="14" height="9" rx="4.5" fill="#3c4146" />
      <rect x="22" y="26" width="16" height="11" rx="5.5" fill="#5d6368" opacity="0.6" />
      <circle cx="30" cy="51" r="8" fill="url(#clip-metal)" stroke="#6e747a" />
      <circle cx="30" cy="51" r="3.5" fill="#c9ced3" stroke="#7c8288" />
      <rect x="12" y="58" width="36" height="46" rx="6" fill="rgb(255 255 255 / 0.55)" stroke="rgb(255 255 255 / 0.9)" />
    </svg>
  );
}

/** Scrapbook stickers that pop onto the card, like the inspiration board. */
function Stickers() {
  const gold = [
    { x: "82%", y: "86%", s: 26, d: 520 },
    { x: "94%", y: "70%", s: 18, d: 600 },
    { x: "71%", y: "102%", s: 20, d: 680 },
    { x: "90%", y: "104%", s: 30, d: 760 },
    { x: "-3%", y: "40%", s: 16, d: 840 },
  ];
  return (
    <div className="pointer-events-none absolute inset-0 z-30" aria-hidden>
      <svg viewBox="0 0 100 100" className="sticker absolute -left-[34px] -top-[44px] w-[70px] [--r:-14deg]" style={{ animationDelay: "60ms" }}>
        <path d={STAR} fill="#79a05a" stroke="#5e8445" strokeWidth="2" strokeLinejoin="round" />
        <path d={STAR} fill="none" stroke="#d6e8b8" strokeWidth="1.6" strokeDasharray="3 3" transform="translate(50 52) scale(0.84) translate(-50 -52)" />
      </svg>
      <svg viewBox="0 0 100 90" className="sticker absolute -right-[30px] -top-[52px] w-[78px] [--r:10deg]" style={{ animationDelay: "200ms" }}>
        <defs>
          <radialGradient id="heart-lime" cx="0.35" cy="0.3" r="0.8">
            <stop offset="0" stopColor="#f3ffc4" />
            <stop offset="0.55" stopColor="#c6e86a" />
            <stop offset="1" stopColor="#93bd34" />
          </radialGradient>
          <radialGradient id="heart-pink" cx="0.35" cy="0.3" r="0.8">
            <stop offset="0" stopColor="#ffd6ff" />
            <stop offset="0.55" stopColor="#e083e6" />
            <stop offset="1" stopColor="#b34fc0" />
          </radialGradient>
        </defs>
        <path d={HEART} fill="url(#heart-lime)" transform="translate(30 4) scale(0.68)" />
        <path d={HEART} fill="url(#heart-pink)" transform="translate(4 38) scale(0.44)" />
        <ellipse cx="50" cy="20" rx="9" ry="5" fill="white" opacity="0.7" transform="rotate(-25 50 20)" />
        <ellipse cx="17" cy="47" rx="5" ry="3" fill="white" opacity="0.7" transform="rotate(-25 17 47)" />
      </svg>
      <svg viewBox="0 0 100 100" className="sticker absolute -bottom-[26px] -left-[26px] w-[78px] [--r:-8deg]" style={{ animationDelay: "340ms" }}>
        <defs>
          <linearGradient id="petal" x1="0" y1="1" x2="0" y2="0">
            <stop offset="0" stopColor="#fff2f6" />
            <stop offset="1" stopColor="#f39ab8" />
          </linearGradient>
        </defs>
        {[0, 60, 120, 180, 240, 300].map((r) => (
          <path key={r} d="M50 50 C 40 34, 42 12, 50 4 C 58 12, 60 34, 50 50 Z" fill="url(#petal)" stroke="#e77fa3" strokeWidth="0.8" transform={`rotate(${r + 15} 50 50)`} />
        ))}
        {[0, 72, 144, 216, 288].map((r) => (
          <g key={r} transform={`rotate(${r} 50 50)`}>
            <line x1="50" y1="50" x2="50" y2="30" stroke="#8a9b4a" strokeWidth="1" />
            <ellipse cx="50" cy="29" rx="1.6" ry="3" fill="#b5532f" />
          </g>
        ))}
        <circle cx="50" cy="50" r="4" fill="#d8e59a" />
      </svg>
      {gold.map((g, i) => (
        <svg key={i} viewBox="0 0 100 100" className="sticker absolute [--r:12deg]" style={{ left: g.x, top: g.y, width: g.s, animationDelay: `${g.d}ms` }}>
          <defs>
            <linearGradient id={`gold-${i}`} x1="0" y1="0" x2="1" y2="1">
              <stop offset="0" stopColor="#fff1b8" />
              <stop offset="0.5" stopColor="#d9b25a" />
              <stop offset="1" stopColor="#a8823a" />
            </linearGradient>
          </defs>
          <path d={STAR} fill={`url(#gold-${i})`} />
        </svg>
      ))}
    </div>
  );
}

const STAR = "M50 6 L61.8 36.2 L94 38.2 L69 58.8 L77.2 90 L50 72.6 L22.8 90 L31 58.8 L6 38.2 L38.2 36.2 Z";
const HEART = "M50 88 C 20 66, 2 48, 2 28 C 2 12, 14 2, 28 2 C 38 2, 46 8, 50 16 C 54 8, 62 2, 72 2 C 86 2, 98 12, 98 28 C 98 48, 80 66, 50 88 Z";
