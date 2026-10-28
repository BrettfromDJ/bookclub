import { Award, BookMarked, Flame, Ghost, Heart, Rocket, Search, Sparkles, Star, Sword, Target, Feather, Brain, Hourglass, Landmark, Smile, Layers, BookOpen, Sprout, Trophy } from "lucide-react";
import { badgeByCode } from "@/lib/badges";
import { cn } from "@/lib/utils";

const ICONS: Record<string, typeof Award> = {
  "genre:fantasy": Sword,
  "genre:scifi": Rocket,
  "genre:mystery": Search,
  "genre:thriller": Flame,
  "genre:romance": Heart,
  "genre:horror": Ghost,
  "genre:historical": Hourglass,
  "genre:literary": BookOpen,
  "genre:classics": Landmark,
  "genre:ya": Sparkles,
  "genre:nonfiction": Brain,
  "genre:biography": Feather,
  "genre:selfhelp": Sprout,
  "genre:poetry": Feather,
  "genre:graphic": Layers,
  "goal:monthly": Target,
  "club:finisher": BookMarked,
  "milestone:1": Star,
  "milestone:10": Award,
  "milestone:25": Smile,
  "milestone:50": Trophy,
  "milestone:100": Trophy,
};

const COLORS: Record<string, string> = { genre: "text-ribbon border-ribbon", goal: "text-stamp border-stamp", club: "text-gold border-gold", milestone: "text-ink border-ink" };

/** Round ink stamp. Unearned stamps show as a faint outline. */
export function BadgeStamp({ code, earned = true, count, size = "md", animate }: { code: string; earned?: boolean; count?: number; size?: "sm" | "md"; animate?: boolean }) {
  const badge = badgeByCode(code);
  if (!badge) return null;
  const Icon = ICONS[code] ?? Award;
  return (
    <figure className="flex flex-col items-center gap-1.5 text-center">
      <div
        className={cn(
          "relative flex items-center justify-center rounded-full border-[2.5px] border-double",
          size === "sm" ? "size-12" : "size-[72px]",
          earned ? cn(COLORS[badge.kind], "bg-card rotate-[-6deg]", animate && "animate-stamp") : "border-line-strong text-line-strong",
        )}
        title={badge.description}
      >
        <span className={cn("absolute inset-1 rounded-full border border-dashed", earned ? "border-current/40" : "border-line")} />
        <Icon className={size === "sm" ? "size-5" : "size-7"} strokeWidth={1.6} />
        {count && count > 1 && <span className="absolute -right-1 -top-1 rounded-full bg-stamp px-1.5 font-type text-[10px] text-white">×{count}</span>}
      </div>
      {size === "md" && <figcaption className={cn("w-20 text-[11px] leading-tight", earned ? "text-ink-soft" : "text-muted/70")}>{badge.name}</figcaption>}
    </figure>
  );
}
