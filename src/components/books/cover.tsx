"use client";

import { useState } from "react";
import { cn } from "@/lib/utils";
import type { Book } from "@/lib/types";

/** Book cover with a cloth-bound fallback when there's no image or it fails to load. */
export function Cover({ book, className }: { book: Pick<Book, "title" | "authors" | "cover_url">; className?: string }) {
  const [failed, setFailed] = useState(false);
  return (
    <div className={cn("relative aspect-[2/3] shrink-0 overflow-hidden rounded-[4px_8px_8px_4px] bg-ribbon shadow-[2px_2px_6px_rgb(42_36_28/0.25)]", className)}>
      {book.cover_url && !failed ? (
        // eslint-disable-next-line @next/next/no-img-element -- remote covers from two hosts; sizes vary too much for next/image here
        <img src={book.cover_url} alt="" loading="lazy" onError={() => setFailed(true)} className="size-full object-cover" />
      ) : (
        <div className="flex size-full flex-col justify-between p-[8%] text-paper">
          <span className="line-clamp-4 font-serif text-[11px] leading-tight">{book.title}</span>
          <span className="line-clamp-1 text-[9px] opacity-70">{book.authors[0]}</span>
        </div>
      )}
      {/* Spine highlight */}
      <span className="pointer-events-none absolute inset-y-0 left-0 w-[6%] bg-gradient-to-r from-black/25 to-transparent" />
    </div>
  );
}
