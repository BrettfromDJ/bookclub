# Book Club

A reading journal with friends: a drag-and-drop TBR, a 10-hole punch card, monthly picks, a badge book, an app-wide monthly book club, and MySpace-style profiles with skins, a top 8 and a profile song.

**Stack:** Next.js 15 (App Router) on Vercel · Supabase (auth, Postgres, storage) · Tailwind 4 · Capacitor 8 for the iOS app.

## Run it

```bash
npm install
```

```bash
npm run dev
```

With no environment variables, the app runs in **demo mode** with sample data, so every screen can be previewed. Changes aren't saved in demo mode.

## Connect Supabase

1. Create a Supabase project and copy `.env.example` to `.env.local`, then fill in the URL, anon key and service-role key.
2. Run the migration in `supabase/migrations/` (SQL editor, or `npx supabase db push`).
3. **Auth → Email templates → Magic Link:** include the code as well as the link, e.g. `Your code is {{ .Token }}`. In the iOS app a tapped email link opens Safari, so people sign in by typing the 6-digit code.
4. **Auth → URL configuration:** add `https://<your-domain>/auth/callback` to the redirect URLs.
5. Make yourself an admin (this unlocks Settings → Book club admin for setting the monthly pick):
   ```sql
   update profiles set is_admin = true where username = '<you>';
   ```

## How the features map to code

| Feature | Where |
| --- | --- |
| TBR: one ranked list, format tags (physical / audio / Kindle), filters, drag to reorder, tap to expand | `src/components/books/tbr-list.tsx` |
| Punch card: 1 hole per book, 10 per card | `src/lib/punch-card.ts`, `src/components/journal/punch-card.tsx` |
| Monthly goal + reward badge | Journal screen; awarded in SQL `award_for_finished()` |
| Monthly pick (best book you read that month) | `src/components/journal/monthly-pick.tsx` |
| Badge book (genre, goal, milestone, club stamps) | `src/lib/badges.ts`, `src/app/badges/page.tsx` |
| Social: follow, private accounts with requests, feed, comments, report, block | `src/app/feed`, `src/components/social/*` |
| Monthly book club + partner branding + admin page | `src/app/club`, `src/app/admin` |
| Profile skins, top 8, Spotify/Apple Music song, library card | `src/app/u/[username]`, `src/lib/skins.ts`, `src/lib/song.ts` |
| Book search (Google Books, falling back to Open Library) | `src/lib/book-search.ts`, `/api/books/search` |

Badges and feed activity are created by database triggers when a book is marked finished, so they can't be faked from the client. Row-level security enforces privacy: a private journal's shelves, picks and activity are visible only to approved followers. The showcase (name, photo, skin, song, top 8, badges) is always visible.

## iOS app

The iOS app (`ios/`) is a native Capacitor shell that loads the deployed site and adds native haptics (the "punch"), the share sheet, the status bar and push notifications.

1. Deploy to Vercel, then set `CAP_SERVER_URL=https://<your-domain>` in your shell.
2. Run:
   ```bash
   npm run ios:sync
   ```
3. Open the project in Xcode (Mac required):
   ```bash
   npm run ios:open
   ```
4. In Xcode, set your team, the final bundle ID (currently the placeholder `co.designjoy.bookclub`), the app icon, and add the **Push Notifications** capability.

**Before submitting to the App Store**
- Rename the app and set the final bundle ID. The bundle ID can't change after the first upload.
- Replace the draft privacy policy at `/privacy` and fill in App Store privacy labels (email, photos, user content).
- Apple requires reporting, blocking and in-app account deletion for apps with user content. All three are built in (deletion needs `SUPABASE_SERVICE_ROLE_KEY`).
- Provide a demo account for App Review.

## Not built yet

- Sending push notifications: the device token is requested, but there's no table or sender yet.
- Book club discussion thread (only the admin-set pick for now).
- Editing finish dates and ratings; a "Read" shelf history view.
- Goodreads / StoryGraph CSV import.

## Scripts

`npm run dev` · `npm run build` · `npm test` · `npm run lint` · `npm run typecheck` · `npm run ios:sync` · `npm run ios:open`
