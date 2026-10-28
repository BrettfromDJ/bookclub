export function DemoBanner() {
  return (
    <p className="mb-4 rounded-2xl border border-dashed border-stamp/40 bg-stamp-soft px-4 py-2.5 text-[13px] text-stamp">
      Demo mode: showing sample data. Add Supabase keys to <code className="font-type">.env.local</code> to save for real.
    </p>
  );
}
