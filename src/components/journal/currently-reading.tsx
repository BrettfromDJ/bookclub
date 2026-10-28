"use client";

import { BookCheck } from "lucide-react";
import { useState, useTransition } from "react";
import { toast } from "sonner";
import { setStatus } from "@/app/actions";
import { Cover } from "@/components/books/cover";
import { FormatIcons } from "@/components/books/format-chips";
import { Button } from "@/components/ui/button";
import { punchHaptic } from "@/lib/native";
import type { UserBook } from "@/lib/types";

export function CurrentlyReading({ initial }: { initial: UserBook[] }) {
  const [books, setBooks] = useState(initial);
  const [, start] = useTransition();
  if (!books.length) return <p className="paper px-5 py-6 text-[15px] text-ink-soft">Nothing on the nightstand. Start something from your TBR.</p>;
  return (
    <ul className="space-y-2.5">
      {books.map((b) => (
        <li key={b.id} className="paper flex items-center gap-3 p-3">
          <Cover book={b.book} className="w-14" />
          <div className="min-w-0 flex-1">
            <p className="line-clamp-2 font-serif text-[17px] leading-snug">{b.book.title}</p>
            <p className="mb-2 line-clamp-1 text-[13px] text-muted">{b.book.authors.join(", ")}</p>
            <FormatIcons formats={b.formats} />
          </div>
          <Button
            size="sm"
            variant="stamp"
            onClick={() => {
              setBooks((all) => all.filter((x) => x.id !== b.id));
              void punchHaptic(true);
              toast(`Punched! “${b.book.title}” is on your card.`);
              start(async () => {
                const res = await setStatus(b.id, "read");
                if (!res.ok) toast(res.error);
              });
            }}
          >
            <BookCheck /> Done
          </Button>
        </li>
      ))}
    </ul>
  );
}
