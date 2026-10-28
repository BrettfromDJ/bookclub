"use client";

import { useEffect, useRef, useState } from "react";
import { clothColor } from "@/lib/book-style";
import { cn } from "@/lib/utils";
import type { Book } from "@/lib/types";

/**
 * A book that looks physical: a crease along the spine, page edges showing on
 * the right and a shadow underneath. Without a cover image (or if it fails to
 * load) it falls back to a cloth binding with a gold title.
 */
export function Cover({ book, className }: { book: Pick<Book, "title" | "authors" | "cover_url">; className?: string }) {
  const [failed, setFailed] = useState(false);
  const img = useRef<HTMLImageElement>(null);

  // An image that errors before hydration never fires onError, so check it once mounted.
  useEffect(() => {
    const el = img.current;
    if (el && el.complete && el.naturalWidth === 0) setFailed(true);
  }, []);

  const showImage = book.cover_url && !failed;
  return (
    <div className={cn("@container relative aspect-[2/3] shrink-0 pr-[4%]", className)}>
      {/* Page block peeking out from behind the cover */}
      <span className="absolute bottom-[1.5%] right-0 top-[1.5%] w-[8%] rounded-r-[2px] bg-[repeating-linear-gradient(to_right,#f4ecd9_0_1px,#e2d6bd_1px_2px)] shadow-[1px_1px_2px_rgb(42_36_28/0.25)]" />
      <div className="relative size-full overflow-hidden rounded-[2px_4px_4px_2px] shadow-[0_1px_1px_rgb(42_36_28/0.2),3px_6px_10px_-2px_rgb(42_36_28/0.35)]">
        {showImage ? (
          // eslint-disable-next-line @next/next/no-img-element -- remote covers from two hosts; sizes vary too much for next/image here
          <img ref={img} src={book.cover_url!} alt="" loading="lazy" onError={() => setFailed(true)} className="size-full object-cover" />
        ) : (
          <div
            className="flex size-full flex-col items-center justify-between px-[12%] py-[14%] text-center text-[#e2c77f]"
            style={{
              backgroundColor: clothColor(book.title),
              backgroundImage:
                "repeating-linear-gradient(45deg, rgb(255 255 255 / 0.04) 0 1px, transparent 1px 3px), repeating-linear-gradient(-45deg, rgb(0 0 0 / 0.06) 0 1px, transparent 1px 3px)",
            }}
          >
            <span className="w-full border-y border-current/60 py-[6%] font-serif text-[max(8px,11cqw)] leading-tight">
              <span className="line-clamp-4">{book.title}</span>
            </span>
            <span className="line-clamp-1 font-type text-[max(6px,7cqw)] uppercase tracking-wider opacity-80">{book.authors[0]}</span>
          </div>
        )}
        {/* Spine crease and a soft sheen across the cover */}
        <span className="pointer-events-none absolute inset-y-0 left-0 w-[10%] bg-[linear-gradient(to_right,rgb(0_0_0/0.28),rgb(255_255_255/0.18)_45%,rgb(0_0_0/0.12)_60%,transparent)]" />
        <span className="pointer-events-none absolute inset-0 bg-[linear-gradient(105deg,transparent_40%,rgb(255_255_255/0.08)_55%,transparent_70%)]" />
      </div>
    </div>
  );
}
