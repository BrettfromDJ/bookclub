"use client";

import { Loader2, Mail } from "lucide-react";
import { useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { isSupabaseConfigured } from "@/lib/supabase/config";
import { sendSignInCode, verifySignInCode } from "./actions";

/**
 * Passwordless sign-in. The email has both a link and a 6-digit code: the link
 * suits the website, while in the iOS app a tapped link opens Safari, so the
 * code is how people finish signing in without leaving the app. People can
 * type their username instead of their email; see ./actions.
 */
export default function LoginPage() {
  const configured = isSupabaseConfigured();
  const router = useRouter();
  const [identifier, setIdentifier] = useState("");
  const [sentTo, setSentTo] = useState("");
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
    setBusy(true);
    setError(null);
    const res = await sendSignInCode(identifier);
    setBusy(false);
    if (!res.ok) setError(res.error);
    else {
      setSentTo(res.data.sentTo);
      setStep("code");
    }
  };

  const verify = async (e: React.FormEvent) => {
    e.preventDefault();
    setBusy(true);
    setError(null);
    const res = await verifySignInCode(identifier, code);
    setBusy(false);
    if (!res.ok) setError(res.error);
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
        {!configured ? (
          <p className="mt-3 text-[15px] text-ink-soft">Accounts aren&apos;t configured yet. Add Supabase keys to enable sign-in — the rest of the app runs in demo mode until then.</p>
        ) : step === "email" ? (
          <form onSubmit={send} className="mt-6">
            <Input
              required
              autoFocus
              autoComplete="username"
              autoCapitalize="none"
              autoCorrect="off"
              spellCheck={false}
              value={identifier}
              onChange={(e) => setIdentifier(e.target.value)}
              placeholder="Email or username"
              aria-label="Email or username"
            />
            {error && <p className="mt-2 text-[13px] text-stamp">{error}</p>}
            <Button type="submit" variant="primary" size="lg" className="mt-4 w-full" disabled={busy}>
              {busy ? <Loader2 className="animate-spin" /> : <Mail />} Send me a sign-in code
            </Button>
            <p className="mt-4 text-center text-[12px] text-muted">No password needed.</p>
          </form>
        ) : (
          <form onSubmit={verify} className="mt-4">
            <p className="text-[15px] text-ink-soft">
              We sent a link and a 6-digit code to <b>{sentTo}</b>. Tap the link, or enter the code here.
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
              Use a different email or username
            </button>
          </form>
        )}
      </div>
    </main>
  );
}
