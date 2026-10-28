"use client";

import { BookOpen, Headphones, Tablet } from "lucide-react";
import { FORMATS, type Format } from "@/lib/types";
import { cn } from "@/lib/utils";

export const FORMAT_ICON = { physical: BookOpen, audio: Headphones, kindle: Tablet } as const;

/** Small icons showing which formats a book is in. */
export function FormatIcons({ formats }: { formats: Format[] }) {
  return (
    <span className="flex gap-1">
      {formats.map((f) => {
        const Icon = FORMAT_ICON[f];
        return (
          <span key={f} className="flex size-6 items-center justify-center rounded-full bg-paper-2 text-ink-soft" title={f}>
            <Icon className="size-3.5" />
          </span>
        );
      })}
    </span>
  );
}

/** Toggleable format tags. A book always keeps at least one. */
export function FormatToggles({ value, onChange }: { value: Format[]; onChange: (formats: Format[]) => void }) {
  return (
    <div className="flex flex-wrap gap-2">
      {FORMATS.map(({ id, label }) => {
        const on = value.includes(id);
        const Icon = FORMAT_ICON[id];
        return (
          <button
            key={id}
            type="button"
            aria-pressed={on}
            onClick={() => {
              const next = on ? value.filter((f) => f !== id) : [...value, id];
              if (next.length) onChange(next);
            }}
            className={cn(
              "flex h-8 items-center gap-1.5 rounded-full border px-3 text-[13px] transition active:scale-95",
              on ? "border-ink bg-ink text-paper" : "border-line-strong text-ink-soft",
            )}
          >
            <Icon className="size-3.5" />
            {label}
          </button>
        );
      })}
    </div>
  );
}
