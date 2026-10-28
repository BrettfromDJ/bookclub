import { clothColor, spineSize } from "@/lib/book-style";
import type { Book } from "@/lib/types";

const PER_SHELF = 10;

/**
 * The monthly goal as a wooden shelf: each book finished this month stands on
 * it as a spine, and the spots still to fill are dotted outlines.
 */
export function GoalShelf({ goal, finished }: { goal: number; finished: Pick<Book, "id" | "title">[] }) {
  const slots = Math.max(goal, finished.length);
  const shelves = Array.from({ length: Math.ceil(slots / PER_SHELF) }, (_, s) => Array.from({ length: Math.min(PER_SHELF, slots - s * PER_SHELF) }, (_, i) => s * PER_SHELF + i));

  return (
    <div className="mt-4 space-y-5" aria-label={`${finished.length} of ${goal} books this month`}>
      {shelves.map((row, s) => (
        <div key={s}>
          <div className="flex h-24 items-end gap-[3px] px-3">
            {row.map((i) => {
              const book = finished[i];
              if (!book) {
                return <span key={i} className="h-[78%] w-[22px] rounded-t-[3px] border-2 border-b-0 border-dashed border-line-strong" />;
              }
              const { width, height } = spineSize(book.title);
              return (
                <span
                  key={book.id || i}
                  title={book.title}
                  className="animate-rise relative flex justify-center overflow-hidden rounded-t-[2px] py-2 shadow-[inset_-2px_0_3px_rgb(0_0_0/0.25),inset_2px_0_2px_rgb(255_255_255/0.12)]"
                  style={{ width, height: `${height}%`, backgroundColor: clothColor(book.title), animationDelay: `${i * 60}ms` }}
                >
                  <span className="absolute inset-x-0 top-[10%] h-px bg-[#e2c77f]/60" />
                  <span className="absolute inset-x-0 bottom-[10%] h-px bg-[#e2c77f]/60" />
                  <span className="whitespace-nowrap font-serif text-[9px] leading-none text-[#e2c77f] [writing-mode:vertical-rl] rotate-180">{book.title}</span>
                </span>
              );
            })}
          </div>
          {/* The plank */}
          <div className="h-3 rounded-[2px] bg-[#8a5a32] bg-[linear-gradient(to_bottom,rgb(255_255_255/0.18),transparent_40%,rgb(0_0_0/0.2)),repeating-linear-gradient(92deg,rgb(0_0_0/0.08)_0_2px,transparent_2px_9px,rgb(255_255_255/0.06)_9px_11px,transparent_11px_17px)] shadow-[0_6px_8px_-3px_rgb(42_36_28/0.45)]" />
        </div>
      ))}
    </div>
  );
}
