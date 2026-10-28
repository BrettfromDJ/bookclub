import { GeistSans } from "geist/font/sans";
import type { Metadata, Viewport } from "next";
import { Courier_Prime, Fraunces } from "next/font/google";
import { Toaster } from "sonner";
import { TabBar } from "@/components/shell/tab-bar";
import { NativeBridge } from "@/components/shell/native-bridge";
import "./globals.css";

const serif = Fraunces({ subsets: ["latin"], variable: "--font-serif-face", display: "swap" });
const typewriter = Courier_Prime({ weight: ["400", "700"], subsets: ["latin"], variable: "--font-type-face", display: "swap" });

// Every screen is per-reader, so never prerender.
export const dynamic = "force-dynamic";

export const metadata: Metadata = {
  title: { default: "Book Club", template: "%s · Book Club" },
  description: "Your reading journal: TBR, punch card, badges, and a book club with friends.",
  applicationName: "Book Club",
  appleWebApp: { capable: true, title: "Book Club", statusBarStyle: "default" },
  formatDetection: { telephone: false },
};

export const viewport: Viewport = {
  themeColor: "#f7f2e7",
  width: "device-width",
  initialScale: 1,
  viewportFit: "cover",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en" className={`${GeistSans.variable} ${serif.variable} ${typewriter.variable}`}>
      <body className="min-h-dvh">
        {children}
        <TabBar />
        <NativeBridge />
        <Toaster position="top-center" toastOptions={{ style: { background: "var(--ink)", color: "var(--paper)", border: "none", borderRadius: 999 } }} />
      </body>
    </html>
  );
}
