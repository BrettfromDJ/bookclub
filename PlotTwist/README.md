# Plot Twist (native iOS app)

A SwiftUI app built from the "Plot Twist" Canva file. The home screen is the four artboards stacked into one continuous scroll:

1. **hot girls collect books…** Your current read, your TBR fanned out on torn paper, "add a book to your tbr", and the reading-receipt printer.
2. **plot twist: book club** The monthly pick, "join the chat", your 10-hole punch card, and "friends".
3. **profile / explore books / share your plot twist**
4. **your library:** Top 8 and the badges board.

It uses the same Supabase backend as the web app in this repo, so accounts, shelves, badges and privacy rules are shared.

## Open it in Xcode

You need a Mac with Xcode 16 or newer.

1. Double-click `PlotTwist/PlotTwist.xcodeproj`.
2. Wait for Xcode to finish fetching the Supabase package (bottom-left progress bar).
3. Pick an iPhone simulator at the top, then press **⌘R**.

With no keys set, the app opens in **demo mode** with sample data, so you can click around right away. Changes reset when you relaunch.

## Connect it to Supabase

1. Copy `Config/Secrets.example.xcconfig` to `Config/Secrets.xcconfig` (that file is git-ignored).
2. Fill in `SUPABASE_HOST` (just `abcd1234.supabase.co`, with no `https://`) and `SUPABASE_ANON_KEY`, from Supabase → Project Settings → API.
3. Run both migrations in `supabase/migrations/`. The second adds the book club chat table and in-app account deletion.
4. In Supabase → Auth → Email Templates → Magic Link, include the code: `Your code is {{ .Token }}`. The app signs people in with that 6-digit code.

## Run it on your phone / ship it

1. In Xcode, select the **PlotTwist** project → **Signing & Capabilities** → pick your Team. You can also set `DEVELOPMENT_TEAM` in `Secrets.xcconfig`.
2. The bundle ID is `co.designjoy.plottwist`, set in `Config/PlotTwist.xcconfig`. Change it before your first App Store upload, because it can't change afterwards.
3. Product → Archive → Distribute to upload to TestFlight.

## Canva artwork

Her actual Canva artwork is in `PlotTwist/Resources/Assets.xcassets`, exported from Canva as transparent PNGs:

- **Canva Stickers**: daisies, binder clip, stars, smiley, hearts, bow, paper plane, arrow, washi tape, speech bubble, the scalloped "10 more!" badge, punch-card holes, and the embroidered patches used for badges.
- **Canva Papers**: ripped watercolor paper, the layered torn note, torn notebook paper, and the receipt printer.
- **Canva Textures**: the blue and red/pink striped papers.
- **Canva Logos**: all three logo options with transparent backgrounds. The app uses `logo-chunky` as its wordmark.

The app icon is the "pt" monogram logo. To use a different one, replace `AppIcon.appiconset/AppIcon.png` with a 1024×1024 PNG.

If she updates a sticker, re-export it from Canva as a transparent PNG and drop it over the matching image (for example `sticker-daisies`). Every sticker also has a drawn version in `Theme/Stickers.swift`, used only if its image goes missing.

The assets were exported through a scratch copy in her Canva named "Plot Twist – app sticker export (scratch copy)", with each piece laid out on its own. The original design wasn't changed. You can delete the copy whenever you like.

**Licensing:** most of these are Canva stock elements (Free or Pro). Canva's content license limits using elements on their own, outside a design, so check it before publishing to the App Store. The safest options are her own drawings or elements she has rights to.

**Fonts:** Poppins and DM Serif Display, both free under the OFL, stand in for the Canva fonts. If you know the exact Canva fonts and they're licensed for apps, add the .ttf files to `Resources/Fonts`, list them in `Config/Info.plist` under `UIAppFonts`, and update `Theme/Theme.swift`.

## Where things live

| | |
| --- | --- |
| Home scroll (the Canva artboards) | `Screens/Home/HomeView.swift` |
| Colors, fonts, design-coordinate layout | `Theme/Theme.swift` |
| Stickers, patches, artwork helpers (plus drawn fallbacks) | `Theme/Stickers.swift`, `Theme/Shapes.swift` |
| Supabase reads and writes | `Data/SupabaseBackend.swift` |
| Demo-mode sample data | `Data/DemoBackend.swift` |
| Punch card, badges, receipt logic | `Model/Logic.swift` |
| Add book, shelves, receipt, chat, friends, profile, top 8, badges, share | `Screens/` |

Layout positions on the home screen are the exact pixel coordinates from the 1080-wide Canva artboards. `.place(x, y, width, height, rotation:)` scales them to the phone, so nudging something to match a design change is a one-number edit.
