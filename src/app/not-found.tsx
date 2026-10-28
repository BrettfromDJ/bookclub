import Link from "next/link";
import { Page } from "@/components/shell/page";

export default function NotFound() {
  return (
    <Page kicker="404" title="Page not found">
      <p className="paper ruled px-5 py-6 font-serif text-lg text-ink-soft">
        This page seems to be checked out. <Link href="/" className="underline">Back to your journal</Link>.
      </p>
    </Page>
  );
}
