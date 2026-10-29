/**
 * Shown the instant a tab is tapped while the next screen renders on the
 * server, so a tap always visibly lands.
 */
export default function Loading() {
  return (
    <main className="safe-top mx-auto w-full max-w-lg animate-pulse px-4 pb-32" aria-busy="true" aria-label="Loading">
      <header className="pb-5 pt-6">
        <div className="h-3 w-28 rounded-full bg-line-strong" />
        <div className="mt-3 h-8 w-56 rounded-lg bg-line-strong" />
      </header>
      <div className="paper h-44" />
      <div className="mb-3 mt-8 h-3 w-24 rounded-full bg-line-strong" />
      <div className="paper h-28" />
      <div className="mb-3 mt-8 h-3 w-32 rounded-full bg-line-strong" />
      <div className="paper h-28" />
    </main>
  );
}
