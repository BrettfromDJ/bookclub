"use client";
import { Capacitor } from "@capacitor/core";

/**
 * Native touches for the iOS app. Every helper is a safe no-op on the web,
 * so components can call them unconditionally.
 */
export const isNative = () => Capacitor.isNativePlatform();

/** The satisfying "punch" when a book is finished or a card fills. */
export async function punchHaptic(strong = false) {
  if (!isNative()) return;
  const { Haptics, ImpactStyle, NotificationType } = await import("@capacitor/haptics");
  if (strong) await Haptics.notification({ type: NotificationType.Success });
  else await Haptics.impact({ style: ImpactStyle.Medium });
}

export async function tapHaptic() {
  if (!isNative()) return;
  const { Haptics, ImpactStyle } = await import("@capacitor/haptics");
  await Haptics.impact({ style: ImpactStyle.Light });
}

/** Native share sheet on iOS, Web Share or clipboard elsewhere. */
export async function shareLink(title: string, url: string) {
  if (isNative()) {
    const { Share } = await import("@capacitor/share");
    await Share.share({ title, url });
  } else if (navigator.share) {
    await navigator.share({ title, url }).catch(() => {});
  } else {
    await navigator.clipboard.writeText(url);
  }
}

/**
 * Asks for push permission (new followers, comments, the monthly club pick).
 * Returns the APNs token to store server-side; sending pushes isn't wired up yet.
 */
export async function registerForPush(): Promise<string | null> {
  if (!isNative()) return null;
  const { PushNotifications } = await import("@capacitor/push-notifications");
  const perm = await PushNotifications.requestPermissions();
  if (perm.receive !== "granted") return null;
  return new Promise((resolve) => {
    PushNotifications.addListener("registration", (t) => resolve(t.value));
    PushNotifications.addListener("registrationError", () => resolve(null));
    void PushNotifications.register();
  });
}
