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

## Swapping in the real Canva artwork

The stickers and textures (daisies, binder clip, patches, stars, washi tape…) are drawn in code to match the design. To use the exact Canva art instead:

1. In Canva, select a sticker → Download as a **transparent PNG**.
2. Drag it into `PlotTwist/Resources/Assets.xcassets` and name it `sticker-<name>`, using one of the names in `Theme/Stickers.swift`, for example `sticker-daisies`, `sticker-binderClip` or `sticker-paperPlane`.
3. Run again. The image replaces the drawn version automatically.

Check Canva's content license before shipping Canva stock elements inside an app. Using them as standalone app UI assets isn't always allowed. Artwork your sister drew herself is fine.

**App icon:** `Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png` is a placeholder based on the "pt" monogram logo option. Replace it with a 1024×1024 PNG export of whichever logo you pick.

**Fonts:** Poppins and DM Serif Display, both free under the OFL, stand in for the Canva fonts. If you know the exact Canva fonts and they're licensed for apps, add the .ttf files to `Resources/Fonts`, list them in `Config/Info.plist` under `UIAppFonts`, and update `Theme/Theme.swift`.

## Where things live

| | |
| --- | --- |
| Home scroll (the Canva artboards) | `Screens/Home/HomeView.swift` |
| Colors, fonts, design-coordinate layout | `Theme/Theme.swift` |
| Hand-drawn shapes and stickers | `Theme/Shapes.swift`, `Theme/Stickers.swift` |
| Supabase reads and writes | `Data/SupabaseBackend.swift` |
| Demo-mode sample data | `Data/DemoBackend.swift` |
| Punch card, badges, receipt logic | `Model/Logic.swift` |
| Add book, shelves, receipt, chat, friends, profile, top 8, badges, share | `Screens/` |

Layout positions on the home screen are the exact pixel coordinates from the 1080-wide Canva artboards. `.place(x, y, width, height, rotation:)` scales them to the phone, so nudging something to match a design change is a one-number edit.
