"use client";

import { BookCheck } from "lucide-react";
import { useState, useTransition } from "react";
import { toast } from "sonner";
import { setStatus } from "@/app/actions";
import { CoverCarousel } from "@/components/books/cover-carousel";
import { FormatIcons } from "@/components/books/format-chips";
import { Button } from "@/components/ui/button";
import { punchHaptic } from "@/lib/native";
import type { UserBook } from "@/lib/types";

export function CurrentlyReading({ initial }: { initial: UserBook[] }) {
  const [books, setBooks] = useState(initial);
  const [index, setIndex] = useState(0);
  const [, start] = useTransition();
  if (!books.length) return <p className="paper px-5 py-6 text-[15px] text-ink-soft">Nothing on the nightstand. Start something from your TBR.</p>;

  const current = books[Math.min(index, books.length - 1)];
  return (
    <section>
      <CoverCarousel items={books} index={index} onIndexChange={setIndex} />
      <div key={current.id} className="animate-rise text-center">
        <p className="line-clamp-2 font-serif text-[20px] leading-snug">{current.book.title}</p>
        <p className="mb-3 line-clamp-1 text-[13px] text-muted">{current.book.authors.join(", ")}</p>
        <div className="flex items-center justify-center gap-3">
          <FormatIcons formats={current.formats} />
          <Button
            size="sm"
            variant="stamp"
            onClick={() => {
              setBooks((all) => all.filter((x) => x.id !== current.id));
              setIndex((i) => Math.max(0, Math.min(i, books.length - 2)));
              void punchHaptic(true);
              toast(`Punched! “${current.book.title}” is on your card.`);
              start(async () => {
                const res = await setStatus(current.id, "read");
                if (!res.ok) toast(res.error);
              });
            }}
          >
            <BookCheck /> Finished it
          </Button>
        </div>
      </div>
    </section>
  );
}
