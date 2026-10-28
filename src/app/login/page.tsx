"use client";

import { Loader2, Mail } from "lucide-react";
import { useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { getBrowserSupabase } from "@/lib/supabase/client";

/**
 * Passwordless sign-in. The email has both a link and a 6-digit code: the link
 * suits the website, while in the iOS app a tapped link opens Safari, so the
 * code is how people finish signing in without leaving the app.
 */
export default function LoginPage() {
  const supabase = getBrowserSupabase();
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [code, setCode] = useState("");
  const [step, setStep] = useState<"email" | "code">("email");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const e = new URLSearchParams(location.search).get("error");
    if (e) setError(e);
  }, []);

  const send = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!supabase) return;
    setBusy(true);
    setError(null);
    const { error } = await supabase.auth.signInWithOtp({ email, options: { emailRedirectTo: `${location.origin}/auth/callback` } });
    setBusy(false);
    if (error) setError(error.message);
    else setStep("code");
  };

  const verify = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!supabase) return;
    setBusy(true);
    setError(null);
    const { error } = await supabase.auth.verifyOtp({ email, token: code, type: "email" });
    setBusy(false);
    if (error) setError(error.message);
    else {
      router.replace("/");
      router.refresh();
    }
  };

  return (
    <main className="safe-top flex min-h-dvh flex-col items-center justify-center px-6">
      <div className="paper w-full max-w-sm p-7 animate-rise">
        <p className="label">Book Club Public Library</p>
        <h1 className="mt-2 font-serif text-[32px] leading-tight">{step === "email" ? "Get your library card" : "Check your email"}</h1>
        {!supabase ? (
          <p className="mt-3 text-[15px] text-ink-soft">Accounts aren&apos;t configured yet. Add Supabase keys to enable sign-in — the rest of the app runs in demo mode until then.</p>
        ) : step === "email" ? (
          <form onSubmit={send} className="mt-6">
            <Input type="email" required autoFocus autoComplete="email" value={email} onChange={(e) => setEmail(e.target.value)} placeholder="you@example.com" aria-label="Email" />
            {error && <p className="mt-2 text-[13px] text-stamp">{error}</p>}
            <Button type="submit" variant="primary" size="lg" className="mt-4 w-full" disabled={busy}>
              {busy ? <Loader2 className="animate-spin" /> : <Mail />} Email me a sign-in link
            </Button>
            <p className="mt-4 text-center text-[12px] text-muted">No password needed.</p>
          </form>
        ) : (
          <form onSubmit={verify} className="mt-4">
            <p className="text-[15px] text-ink-soft">
              We sent a link and a 6-digit code to <b>{email}</b>. Tap the link, or enter the code here.
            </p>
            <Input
              className="mt-5 text-center font-type text-xl tracking-[0.4em]"
              inputMode="numeric"
              autoComplete="one-time-code"
              value={code}
              onChange={(e) => setCode(e.target.value.replace(/\D/g, "").slice(0, 6))}
              placeholder="000000"
              aria-label="Sign-in code"
            />
            {error && <p className="mt-2 text-[13px] text-stamp">{error}</p>}
            <Button type="submit" variant="primary" size="lg" className="mt-4 w-full" disabled={busy || code.length < 6}>
              {busy && <Loader2 className="animate-spin" />} Sign in
            </Button>
            <button type="button" onClick={() => setStep("email")} className="mt-4 block w-full text-center text-[13px] text-muted">
              Use a different email
            </button>
          </form>
        )}
      </div>
    </main>
  );
}
