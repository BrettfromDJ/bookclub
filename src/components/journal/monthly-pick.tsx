"use client";

import * as Dialog from "@radix-ui/react-dialog";
import { Crown } from "lucide-react";
import { useState, useTransition } from "react";
import { toast } from "sonner";
import { setMonthlyPick } from "@/app/actions";
import { Cover } from "@/components/books/cover";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/input";
import { monthLabel } from "@/lib/month";
import type { Book } from "@/lib/types";

/** "Best book I read this month", chosen from this month's finished books. */
export function MonthlyPick({ month, current, candidates }: { month: string; current: { book: Book; note: string } | null; candidates: Book[] }) {
  const [pick, setPick] = useState(current);
  const [open, setOpen] = useState(false);
  const [chosen, setChosen] = useState<Book | null>(current?.book ?? null);
  const [note, setNote] = useState(current?.note ?? "");
  const [, start] = useTransition();

  return (
    <section className="paper relative overflow-hidden p-5">
      <p className="label flex items-center gap-1.5">
        <Crown className="size-3.5 text-gold" /> {monthLabel(month)} pick
      </p>
      {pick ? (
        <div className="mt-3 flex gap-4">
          <Cover book={pick.book} className="w-28" />
          <div className="min-w-0">
            <p className="font-serif text-xl leading-snug">{pick.book.title}</p>
            <p className="text-[13px] text-muted">{pick.book.authors.join(", ")}</p>
            {pick.note && <p className="mt-2 font-serif text-[15px] italic text-ink-soft">“{pick.note}”</p>}
            <button onClick={() => setOpen(true)} className="mt-2 text-[13px] text-muted underline underline-offset-2">
              Change
            </button>
          </div>
        </div>
      ) : (
        <div className="mt-2">
          <p className="text-[15px] text-ink-soft">{candidates.length ? "What was the best book you read this month?" : "Finish a book this month to crown your pick."}</p>
          {candidates.length > 0 && (
            <Button size="sm" variant="outline" className="mt-3" onClick={() => setOpen(true)}>
              Choose my pick
            </Button>
          )}
        </div>
      )}

      <Dialog.Root open={open} onOpenChange={setOpen}>
        <Dialog.Portal>
          <Dialog.Overlay className="fixed inset-0 z-50 bg-ink/30" />
          <Dialog.Content className="safe-bottom fixed inset-x-0 bottom-0 z-50 mx-auto max-w-lg rounded-t-3xl bg-paper p-5 animate-rise">
            <Dialog.Title className="font-serif text-2xl">Best of {monthLabel(month).split(" ")[0]}</Dialog.Title>
            <Dialog.Description className="mt-1 text-[14px] text-muted">Pick from the books you finished this month.</Dialog.Description>
            <div className="-mx-5 mt-4 flex gap-3 overflow-x-auto px-5 pb-2">
              {candidates.map((b) => (
                <button key={b.id} onClick={() => setChosen(b)} className={`w-20 shrink-0 rounded-lg p-1 transition ${chosen?.id === b.id ? "bg-gold/30 ring-2 ring-gold" : ""}`}>
                  <Cover book={b} />
                  <span className="mt-1 line-clamp-2 block text-[11px] leading-tight">{b.title}</span>
                </button>
              ))}
            </div>
            <Textarea className="mt-3" rows={2} maxLength={500} value={note} onChange={(e) => setNote(e.target.value)} placeholder="Why it won (optional)" />
            <Button
              variant="primary"
              size="lg"
              className="mt-4 w-full"
              disabled={!chosen}
              onClick={() => {
                if (!chosen) return;
                setPick({ book: chosen, note });
                setOpen(false);
                start(async () => {
                  const res = await setMonthlyPick(chosen.id, month, note);
                  if (!res.ok) toast(res.error);
                });
              }}
            >
              Crown it
            </Button>
          </Dialog.Content>
        </Dialog.Portal>
      </Dialog.Root>
    </section>
  );
}
