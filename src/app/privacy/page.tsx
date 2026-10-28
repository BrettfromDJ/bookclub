import { Page } from "@/components/shell/page";

export const metadata = { title: "Privacy" };

/** Placeholder policy — replace with reviewed text before App Store submission. */
export default function PrivacyPage() {
  return (
    <Page kicker="Draft" title="Privacy policy">
      <div className="paper space-y-4 p-5 text-[15px] leading-relaxed text-ink-soft">
        <p>Book Club stores your email address, profile details, profile photo, the books on your shelves, and the comments you post, so the app can work and your friends can follow along.</p>
        <p>Your profile name, photo, skin, song, top 8 and badges are visible to other readers. With a private journal, your shelves and activity are visible only to followers you approve.</p>
        <p>Book details come from Google Books and Open Library. Profile songs play through Spotify or Apple Music&apos;s embedded players, which follow their own privacy policies.</p>
        <p>You can delete your account and all of its data at any time from Settings.</p>
        <p className="font-type text-[12px] text-muted">TODO: replace with a reviewed policy and contact address before launch.</p>
      </div>
    </Page>
  );
}
