import type { CapacitorConfig } from "@capacitor/cli";

/**
 * The iOS app is a native shell around the deployed Next.js site.
 * Set CAP_SERVER_URL to the production URL before `npm run ios:sync`.
 * `mobile/` holds the offline page shown if the site can't be reached.
 */
const config: CapacitorConfig = {
  // Placeholder — pick the final bundle ID before the first App Store upload; it can't change after.
  appId: "co.designjoy.bookclub",
  appName: "Book Club",
  webDir: "mobile",
  server: process.env.CAP_SERVER_URL ? { url: process.env.CAP_SERVER_URL, errorPath: "offline.html" } : undefined,
  ios: { contentInset: "always", scheme: "Book Club" },
  plugins: {
    PushNotifications: { presentationOptions: ["badge", "sound", "alert"] },
  },
};

export default config;
