"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { Cover } from "@/components/books/cover";
import type { UserBook } from "@/lib/types";

/**
 * Big covers you swipe through. The middle book sits up front and the others
 * tilt away from it, like books stood up on a table.
 */
export function CoverCarousel({
  items,
  index,
  onIndexChange,
  badge,
  size = 150,
}: {
  items: UserBook[];
  index: number;
  onIndexChange: (index: number) => void;
  badge?: (item: UserBook, index: number) => React.ReactNode;
  /** Cover width in px; neighbours overlap it slightly. */
  size?: number;
}) {
  const slot = size - 6;
  const scroller = useRef<HTMLDivElement>(null);
  // Scroll position in "books" (0 = first book centred), for the tilt.
  const [offset, setOffset] = useState(index);
  const frame = useRef(0);

  const step = () => (scroller.current?.firstElementChild as HTMLElement | null)?.offsetWidth ?? 1;

  const scrollTo = useCallback((i: number, smooth = true) => {
    scroller.current?.scrollTo({ left: i * step(), behavior: smooth ? "smooth" : "instant" });
  }, []);

  // Keep the scroll in line when the parent changes the index (e.g. a book was removed).
  useEffect(() => {
    const el = scroller.current;
    if (el && Math.round(el.scrollLeft / step()) !== index) scrollTo(index, false);
  }, [index, items.length, scrollTo]);

  const onScroll = () => {
    cancelAnimationFrame(frame.current);
    frame.current = requestAnimationFrame(() => {
      const el = scroller.current;
      if (!el) return;
      const at = el.scrollLeft / step();
      setOffset(at);
      const nearest = Math.min(items.length - 1, Math.max(0, Math.round(at)));
      if (nearest !== index) onIndexChange(nearest);
    });
  };

  return (
    <div
      ref={scroller}
      onScroll={onScroll}
      className="-mx-4 flex snap-x snap-mandatory overflow-x-auto overscroll-x-contain py-6 [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
      style={{ paddingInline: `calc(50% - ${slot / 2}px)` }}
      role="listbox"
      aria-label="Books"
      tabIndex={0}
      onKeyDown={(e) => {
        if (e.key === "ArrowRight") scrollTo(Math.min(items.length - 1, index + 1));
        if (e.key === "ArrowLeft") scrollTo(Math.max(0, index - 1));
      }}
    >
      {items.map((item, i) => {
        const d = i - offset;
        const dist = Math.min(Math.abs(d), 2);
        return (
          <button
            key={item.id}
            type="button"
            role="option"
            aria-selected={i === index}
            aria-label={item.book.title}
            onClick={() => scrollTo(i)}
            className="relative shrink-0 snap-center"
            style={{ width: slot, zIndex: 10 - Math.round(dist * 3), perspective: size * 4.5 }}
          >
            <div
              className="relative -mx-[3px] will-change-transform"
              style={{
                width: size,
                transform: `translateZ(${-dist * size * 0.4}px) rotateY(${Math.max(-45, Math.min(45, -d * 32))}deg) scale(${1 - dist * 0.08})`,
                opacity: 1 - Math.max(0, Math.abs(d) - 1.5) * 0.6,
              }}
            >
              <Cover book={item.book} />
              {badge?.(item, i)}
            </div>
          </button>
        );
      })}
    </div>
  );
}
