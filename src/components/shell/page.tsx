import { cn } from "@/lib/utils";

/** Standard screen: safe-area top, room for the tab bar, journal-style title. */
export function Page({ title, kicker, action, children, className }: { title?: string; kicker?: string; action?: React.ReactNode; children: React.ReactNode; className?: string }) {
  return (
    <main className={cn("safe-top mx-auto w-full max-w-lg px-4 pb-32", className)}>
      {title && (
        <header className="flex items-end justify-between gap-4 pb-5 pt-6">
          <div>
            {kicker && <p className="label">{kicker}</p>}
            <h1 className="font-serif text-[32px] leading-tight tracking-tight">{title}</h1>
          </div>
          {action}
        </header>
      )}
      {children}
    </main>
  );
}

export function SectionTitle({ children, action }: { children: React.ReactNode; action?: React.ReactNode }) {
  return (
    <div className="mb-3 mt-8 flex items-center justify-between">
      <h2 className="label">{children}</h2>
      {action}
    </div>
  );
}
