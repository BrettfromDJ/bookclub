"use client";

import { DndContext, KeyboardSensor, PointerSensor, TouchSensor, closestCenter, useSensor, useSensors, type DragEndEvent } from "@dnd-kit/core";
import { SortableContext, arrayMove, sortableKeyboardCoordinates, useSortable, verticalListSortingStrategy } from "@dnd-kit/sortable";
import { CSS } from "@dnd-kit/utilities";
import { ArrowUpToLine, BookCheck, ChevronDown, GalleryHorizontal, GripVertical, ListOrdered, Play, Plus, Trash2 } from "lucide-react";
import { useMemo, useState, useTransition } from "react";
import { toast } from "sonner";
import { addToShelf, moveTbr, removeFromShelf, setFormats, setStatus } from "@/app/actions";
import { BookSearch } from "@/components/books/book-search";
import { Cover } from "@/components/books/cover";
import { CoverCarousel } from "@/components/books/cover-carousel";
import { FormatIcons, FormatToggles } from "@/components/books/format-chips";
import { Button } from "@/components/ui/button";
import { punchHaptic, tapHaptic } from "@/lib/native";
import { positionAt, positionBetween } from "@/lib/ranking";
import { FORMATS, type Format, type UserBook } from "@/lib/types";
import { cn } from "@/lib/utils";

type Filter = "all" | Format;
type View = "shelf" | "arrange";

/**
 * One ranked to-be-read list. It opens to big swipeable covers with the
 * actions under the middle book; the "Arrange" tab is the drag-to-reorder list
 * where tapping a book opens it like an accordion.
 */
export function TbrList({ initial }: { initial: UserBook[] }) {
  const [books, setBooks] = useState(() => initial.filter((b) => b.status === "tbr").sort((a, b) => a.position - b.position));
  const [filter, setFilter] = useState<Filter>("all");
  const [view, setView] = useState<View>("shelf");
  const [index, setIndex] = useState(0);
  const [openId, setOpenId] = useState<string | null>(null);
  const [searching, setSearching] = useState(false);
  const [, startTransition] = useTransition();

  const visible = useMemo(() => (filter === "all" ? books : books.filter((b) => b.formats.includes(filter))), [books, filter]);

  const sensors = useSensors(
    useSensor(PointerSensor, { activationConstraint: { distance: 6 } }),
    // Short press-and-hold on touch so the list still scrolls normally.
    useSensor(TouchSensor, { activationConstraint: { delay: 160, tolerance: 6 } }),
    useSensor(KeyboardSensor, { coordinateGetter: sortableKeyboardCoordinates }),
  );

  const run = (action: () => Promise<{ ok: boolean; error?: string }>) =>
    startTransition(async () => {
      const res = await action();
      if (!res.ok && res.error) toast(res.error);
    });

  const onDragEnd = ({ active, over }: DragEndEvent) => {
    if (!over || active.id === over.id) return;
    const from = visible.findIndex((b) => b.id === active.id);
    const to = visible.findIndex((b) => b.id === over.id);
    const reordered = arrayMove(visible, from, to);
    const position = positionAt(reordered.filter((b) => b.id !== active.id), to);
    void tapHaptic();
    setBooks((all) => all.map((b) => (b.id === active.id ? { ...b, position } : b)).sort((a, b) => a.position - b.position));
    run(() => moveTbr(String(active.id), position));
  };

  const update = (id: string, patch: Partial<UserBook>) => setBooks((all) => all.map((b) => (b.id === id ? { ...b, ...patch } : b)));
  const drop = (id: string) => setBooks((all) => all.filter((b) => b.id !== id));

  const handlers = (b: UserBook) => ({
    onFormats: (formats: Format[]) => {
      update(b.id, { formats });
      run(() => setFormats(b.id, formats));
    },
    onStart: () => {
      drop(b.id);
      toast(`Started “${b.book.title}”`);
      run(() => setStatus(b.id, "reading"));
    },
    onFinish: () => {
      drop(b.id);
      void punchHaptic(true);
      toast(`Punched! “${b.book.title}” is on your card.`);
      run(() => setStatus(b.id, "read"));
    },
    onRemove: () => {
      drop(b.id);
      run(() => removeFromShelf(b.id));
    },
    onReadNext: () => {
      const position = positionBetween(undefined, books[0]?.position);
      void tapHaptic();
      setBooks((all) => all.map((x) => (x.id === b.id ? { ...x, position } : x)).sort((x, y) => x.position - y.position));
      setIndex(0);
      toast(`“${b.book.title}” is up next.`);
      run(() => moveTbr(b.id, position));
    },
  });

  const current = visible[Math.min(index, Math.max(0, visible.length - 1))];

  return (
    <>
      <div className="-mx-4 mb-1 flex items-center gap-2 px-4">
        <div className="flex min-w-0 flex-1 gap-2 overflow-x-auto pb-1">
          {(["all", ...FORMATS.map((f) => f.id)] as Filter[]).map((f) => (
            <button
              key={f}
              onClick={() => {
                setFilter(f);
                setIndex(0);
              }}
              className={cn("h-8 shrink-0 rounded-full border px-3.5 text-[13px] capitalize transition", filter === f ? "border-ink bg-ink text-paper" : "border-line-strong text-ink-soft")}
            >
              {f === "all" ? `All · ${books.length}` : `${f} · ${books.filter((b) => b.formats.includes(f)).length}`}
            </button>
          ))}
        </div>
        <Button
          size="icon-sm"
          variant="outline"
          className="mb-1"
          onClick={() => setView(view === "shelf" ? "arrange" : "shelf")}
          aria-label={view === "shelf" ? "Arrange as a list" : "Show covers"}
        >
          {view === "shelf" ? <ListOrdered /> : <GalleryHorizontal />}
        </Button>
      </div>

      {view === "shelf" && current && (
        <section>
          <CoverCarousel
            items={visible}
            index={index}
            onIndexChange={setIndex}
            size={244}
            badge={(_, i) => (
              // Red bookmark ribbon with the book's place in line
              <span className="absolute -top-1.5 right-[16%] flex h-14 w-8 items-start justify-center bg-stamp pt-2 font-type text-[13px] font-bold text-white shadow-md [clip-path:polygon(0_0,100%_0,100%_100%,50%_78%,0_100%)]">
                {i + 1}
              </span>
            )}
          />
          <TbrDetail key={current.id} item={current} rank={index + 1} total={visible.length} first={books[0]?.id === current.id} onAdd={() => setSearching(true)} {...handlers(current)} />
        </section>
      )}

      {view === "arrange" && (
        <DndContext sensors={sensors} collisionDetection={closestCenter} onDragEnd={onDragEnd}>
          <SortableContext items={visible.map((b) => b.id)} strategy={verticalListSortingStrategy}>
            <ol className="space-y-2.5">
              {visible.map((b, i) => (
                <TbrRow
                  key={b.id}
                  item={b}
                  rank={i + 1}
                  open={openId === b.id}
                  onToggle={() => setOpenId((id) => (id === b.id ? null : b.id))}
                  {...handlers(b)}
                />
              ))}
            </ol>
          </SortableContext>
        </DndContext>
      )}

      {visible.length === 0 && <p className="paper ruled px-5 py-8 text-center font-serif text-lg text-ink-soft">Nothing here yet. Add the next book you can&apos;t wait to read.</p>}

      {(view === "arrange" || !current) && (
        <Button variant="primary" size="lg" className="fixed bottom-24 right-4 z-30 shadow-lg" onClick={() => setSearching(true)}>
          <Plus /> Add book
        </Button>
      )}

      <BookSearch
        open={searching}
        onOpenChange={setSearching}
        onPick={(candidate) => {
          setSearching(false);
          const formats: Format[] = filter === "all" ? ["physical"] : [filter];
          const temp: UserBook = {
            id: `temp-${candidate.external_id}`,
            user_id: "",
            book_id: "",
            status: "tbr",
            formats,
            position: (books[0]?.position ?? 1) - 1,
            started_at: null,
            finished_at: null,
            rating: null,
            book: { ...candidate, id: "" },
          };
          setBooks((all) => [temp, ...all]);
          startTransition(async () => {
            const res = await addToShelf(candidate, formats);
            if (res.ok) update(temp.id, { id: res.data.id });
            else if (res.error) toast(res.error);
          });
        }}
      />
    </>
  );
}

function TbrRow({
  item,
  rank,
  open,
  onToggle,
  onFormats,
  onStart,
  onFinish,
  onRemove,
}: {
  item: UserBook;
  rank: number;
  open: boolean;
  onToggle: () => void;
  onFormats: (f: Format[]) => void;
  onStart: () => void;
  onFinish: () => void;
  onRemove: () => void;
}) {
  const { attributes, listeners, setNodeRef, setActivatorNodeRef, transform, transition, isDragging } = useSortable({ id: item.id });
  return (
    <li
      ref={setNodeRef}
      style={{ transform: CSS.Transform.toString(transform), transition }}
      className={cn("paper overflow-hidden transition-shadow", isDragging && "z-10 scale-[1.02] shadow-2xl")}
    >
      <div className="flex items-center gap-3 p-3">
        <button
          ref={setActivatorNodeRef}
          {...attributes}
          {...listeners}
          className="flex h-12 w-6 shrink-0 cursor-grab touch-none items-center justify-center text-muted active:cursor-grabbing"
          aria-label={`Reorder ${item.book.title}`}
        >
          <GripVertical className="size-4" />
        </button>
        <button onClick={onToggle} className="flex min-w-0 flex-1 items-center gap-3 text-left" aria-expanded={open}>
          <span className="w-5 shrink-0 text-center font-type text-[12px] text-muted">{rank}</span>
          <Cover book={item.book} className="w-11" />
          <span className="min-w-0 flex-1">
            <span className="line-clamp-2 font-serif text-[16px] leading-snug">{item.book.title}</span>
            <span className="mt-0.5 line-clamp-1 text-[13px] text-muted">{item.book.authors.join(", ")}</span>
          </span>
          <FormatIcons formats={item.formats} />
          <ChevronDown className={cn("size-4 shrink-0 text-muted transition-transform", open && "rotate-180")} />
        </button>
      </div>
      <div className={cn("grid transition-[grid-template-rows] duration-300 ease-[var(--ease-out)]", open ? "grid-rows-[1fr]" : "grid-rows-[0fr]")}>
        <div className="overflow-hidden">
          <div className="space-y-3 border-t border-dashed border-line-strong px-4 pb-4 pt-3">
            <p className="label">I have it on</p>
            <FormatToggles value={item.formats} onChange={onFormats} />
            <div className="flex flex-wrap gap-2 pt-1">
              <Button size="sm" variant="outline" onClick={onStart}>
                <Play /> Start reading
              </Button>
              <Button size="sm" variant="stamp" onClick={onFinish}>
                <BookCheck /> Finished it
              </Button>
              <Button size="sm" variant="ghost" onClick={onRemove} className="ml-auto">
                <Trash2 /> Remove
              </Button>
            </div>
          </div>
        </div>
      </div>
    </li>
  );
}

function TbrDetail({
  item,
  rank,
  total,
  first,
  onFormats,
  onStart,
  onFinish,
  onRemove,
  onReadNext,
  onAdd,
}: {
  item: UserBook;
  rank: number;
  total: number;
  first: boolean;
  onFormats: (f: Format[]) => void;
  onStart: () => void;
  onFinish: () => void;
  onRemove: () => void;
  onReadNext: () => void;
  onAdd: () => void;
}) {
  return (
    <div className="animate-rise text-center">
      <p className="line-clamp-2 font-serif text-[28px] leading-tight">{item.book.title}</p>
      <p className="mt-1 line-clamp-1 text-[14px] text-muted">
        {item.book.authors.join(", ")} · <span className="font-type text-[12px]">{rank} of {total}</span>
      </p>

      {/* Round actions, like a toolbar under the book */}
      <div className="mt-5 flex items-start justify-center gap-4">
        <RoundAction label="Start" onClick={onStart}>
          <Play />
        </RoundAction>
        <RoundAction label="Finished" onClick={onFinish} stamp>
          <BookCheck />
        </RoundAction>
        {!first && (
          <RoundAction label="Read next" onClick={onReadNext}>
            <ArrowUpToLine />
          </RoundAction>
        )}
        <RoundAction label="Remove" onClick={onRemove}>
          <Trash2 />
        </RoundAction>
        <RoundAction label="Add" onClick={onAdd}>
          <Plus />
        </RoundAction>
      </div>

      <div className="mt-5 flex justify-center">
        <FormatToggles value={item.formats} onChange={onFormats} />
      </div>
    </div>
  );
}

function RoundAction({ label, onClick, stamp, children }: { label: string; onClick: () => void; stamp?: boolean; children: React.ReactNode }) {
  return (
    <button onClick={onClick} className="group flex w-14 flex-col items-center gap-1.5 text-[11px] text-ink-soft">
      <span
        className={cn(
          "flex size-12 items-center justify-center rounded-full shadow-[0_1px_2px_rgb(42_36_28/0.12),0_6px_14px_-6px_rgb(42_36_28/0.3)] transition group-active:scale-90 [&_svg]:size-5",
          stamp ? "bg-stamp text-white" : "bg-card text-ink",
        )}
      >
        {children}
      </span>
      {label}
    </button>
  );
}
