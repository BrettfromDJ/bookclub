import SwiftUI

/// Everywhere you can go from the home scroll.
enum Route: Hashable {
    case shelf
    case book(UUID)
    case receipt
    case club
    case friends
    case profile
    case explore
    case topEight
    case badges
    case reader(String)
}

/// The home screen: her "Plot Twist" Canva file, one continuous scroll made of
/// four artboards stacked top to bottom.
struct HomeView: View {
    @Environment(AppModel.self) private var model
    @State private var addingBook = false
    @State private var sharing = false

    var body: some View {
        GeometryReader { geo in
            // Skip the zero-width first layout pass so nothing is drawn at scale 0.
            if geo.size.width > 0 {
                ScrollView {
                    VStack(spacing: 0) {
                        if model.isDemo { DemoBanner() }
                        ReadingArtboard(addBook: { addingBook = true })
                        ClubArtboard()
                        MenuArtboard(share: { sharing = true })
                        LibraryArtboard()
                        Wordmark(size: 22)
                            .padding(.vertical, 28)
                            .frame(maxWidth: .infinity)
                            .background(Color.cream)
                    }
                    .environment(\.designScale, geo.size.width / Design.width)
                }
                .scrollIndicators(.hidden)
                .refreshable { await model.refresh() }
            }
        }
        .background {
            VStack(spacing: 0) {
                Color.cream.frame(height: 400)
                Color.cream
            }
            .ignoresSafeArea()
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $addingBook) { AddBookSheet(defaultStatus: .tbr) }
        .sheet(isPresented: $sharing) { ShareCardSheet() }
        .navigationDestination(for: Route.self) { route in
            switch route {
            case .shelf: ShelfView()
            case .book(let id): BookDetailView(userBookID: id)
            case .receipt: ReceiptView()
            case .club: ClubChatView()
            case .friends: FriendsView()
            case .profile: ProfileView()
            case .explore: ExploreView()
            case .topEight: TopEightEditor()
            case .badges: BadgeBookView()
            case .reader(let username): ReaderView(username: username)
            }
        }
    }
}

private struct DemoBanner: View {
    var body: some View {
        Text("demo mode · sample data, changes reset on relaunch")
            .font(.display(11, weight: .semiBold))
            .foregroundStyle(Color.brick)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .background(Color.butter)
    }
}

// MARK: - Artboard 1: current read, TBR, reading receipt

private struct ReadingArtboard: View {
    @Environment(AppModel.self) private var model
    @Environment(\.designScale) private var s
    var addBook: () -> Void

    var body: some View {
        Artboard(height: 1880) {
            StripedPaper(kind: .blue).place(0, 0, 1080, 1880)

            // Header card
            RoundedRectangle(cornerRadius: 51 * s).fill(Color.cream).place(0, -57, 1080, 616)
            RoundedRectangle(cornerRadius: 51 * s)
                .strokeBorder(Color.brick, style: StrokeStyle(lineWidth: 5 * s, dash: [16 * s, 10 * s]))
                .place(32, 18, 1026, 516)

            // Torn paper with the TBR fanned out on it
            Artwork(name: "paper-rippedPaper", contentMode: nil) {
                TornPaper(edges: [.trailing], roughness: 16 * s, seed: 5)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.18), radius: 6 * s, x: 3 * s, y: 6 * s)
            }
            .place(218, 656, 639, 869, rotation: 90)
            StickerView(.binderClip).place(322, 573, 430, 232)
            TBRFan()

            Button(action: addBook) {
                ArtboardPill(title: "add a book to your tbr", fill: .olive, text: .cream, fontSize: 33)
            }
            .buttonStyle(.squish)
            .place(324, 1295, 418, 98, rotation: 2.3)

            StickerView(.goldStar).place(60, 734, 96, 101)
            StickerView(.redBurst).place(115, 628, 127, 122)
            StickerView(.smiley).place(901, 734, 111, 111, rotation: -11)

            // Current read
            NavigationLink(value: model.currentlyReading.first.map { Route.book($0.id) } ?? Route.shelf) {
                ArtboardPill(title: "your current read", fill: .blush, text: .cream, fontSize: 51)
            }
            .buttonStyle(.squish)
            .place(601, 456, 581, 136, rotation: -6)
            CurrentReadCover().place(716, 119, 242, 359, rotation: 5)
            StickerView(.daisies).place(769, -30, 222, 167)
            StickerView(.arrow).place(959, 407, 85, 63, rotation: 19)

            DesignText("hot girls collect books faster than we can read them", size: 89, serif: true, color: .honey,
                       alignment: .leading, tracking: -0.02)
                .place(82, 78, 635, 396)

            // Reading receipt printer
            NavigationLink(value: Route.receipt) { ReceiptPrinter() }
                .buttonStyle(.squish)
                .place(103, 1457, 864, 382)
            StickerView(.paperPlane).place(-134, 1401, 432, 264)
        }
    }
}

private struct CurrentReadCover: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        if let current = model.currentlyReading.first {
            NavigationLink(value: Route.book(current.id)) {
                BookCover(current.book)
                    .shadow(color: .black.opacity(0.25), radius: 4, x: 2, y: 4)
            }
            .buttonStyle(.squish)
        } else {
            NavigationLink(value: Route.shelf) {
                ZStack {
                    RoundedRectangle(cornerRadius: 4).fill(Color.butter)
                    RoundedRectangle(cornerRadius: 4).strokeBorder(Color.brick, style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                    Text("pick your next read")
                        .font(.serif(16))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.brick)
                        .padding(8)
                }
            }
            .buttonStyle(.squish)
        }
    }
}

/// The five TBR covers fanned across the torn paper, top pick in the middle.
private struct TBRFan: View {
    @Environment(AppModel.self) private var model

    // Canva positions: far left, left, center, right, far right.
    private static let slots: [(x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat)] = [
        (178, 932, 145, 217), (287, 898, 190, 286), (423, 846, 241, 363), (614, 898, 188, 286), (757, 932, 145, 217),
    ]
    /// Which TBR rank sits in each slot (back to front draw order).
    private static let drawOrder: [(slot: Int, rank: Int)] = [(0, 4), (4, 3), (1, 2), (3, 1), (2, 0)]

    var body: some View {
        let tbr = model.tbr
        if tbr.isEmpty {
            NavigationLink(value: Route.shelf) {
                Text("your tbr is empty.\nadd something juicy ↓")
                    .font(.serif(18))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.brick)
            }
            .place(178, 846, 724, 363)
        } else {
            ForEach(Self.drawOrder, id: \.slot) { item in
                if item.rank < tbr.count {
                    let slot = Self.slots[item.slot]
                    NavigationLink(value: Route.shelf) {
                        BookCover(tbr[item.rank].book)
                            .shadow(color: .black.opacity(0.28), radius: 5, x: 0, y: 5)
                    }
                    .buttonStyle(.squish)
                    .place(slot.x, slot.y, slot.w, slot.h)
                }
            }
        }
    }
}

private struct ReceiptPrinter: View {
    @Environment(\.designScale) private var s

    var body: some View {
        // Local design coordinates: 864 × 382.
        ZStack(alignment: .topLeading) {
            if let printer = UIImage(named: "paper-receiptPrinter") {
                // Her printer graphic: the top (slot + paper) and the zigzag bottom, like the Canva file.
                VStack(spacing: 0) {
                    // Fill to the full width, then crop to the top and bottom slices.
                    Image(uiImage: printer).resizable().scaledToFill()
                        .frame(width: 864 * s, height: 286 * s, alignment: .top).clipped()
                    Image(uiImage: printer).resizable().scaledToFill()
                        .frame(width: 864 * s, height: 96 * s, alignment: .bottom).clipped()
                }
                .place(0, 0, 864, 382)
            } else {
                drawnPrinter
            }
            DesignText("print your \(Month.name())", size: 31, serif: true, color: .marigold).place(160, 185, 544, 37)
            DesignText("reading receipt", size: 63, weight: .extraBold, color: .blush, tracking: -0.02).place(100, 208, 661, 75)
        }
        .frame(width: 864 * s, height: 382 * s, alignment: .topLeading)
    }

    /// Fallback if the printer artwork is missing.
    @ViewBuilder private var drawnPrinter: some View {
        ReceiptShape(tooth: 14 * s)
            .fill(Color.white)
            .shadow(color: .black.opacity(0.12), radius: 3 * s, y: 3 * s)
            .place(70, 60, 724, 322)
        RoundedRectangle(cornerRadius: 26 * s)
            .fill(LinearGradient(colors: [Color(hex: 0xF7F7F5), Color(hex: 0xDCDCD8)], startPoint: .top, endPoint: .bottom))
            .shadow(color: .black.opacity(0.18), radius: 5 * s, y: 4 * s)
            .place(0, 0, 864, 84)
        Capsule().fill(Color(hex: 0x6E6E6A)).place(48, 54, 768, 14)
    }
}

// MARK: - Artboard 2: book club, punch card, friends

private struct ClubArtboard: View {
    @Environment(AppModel.self) private var model
    @Environment(\.designScale) private var s

    var body: some View {
        Artboard(height: 1930) {
            StripedPaper(kind: .blue).place(0, 0, 1080, 1930)

            // Layered note: pink grid sheet behind, cream ring-bound sheet in front
            Artwork(name: "paper-tornNote", contentMode: nil) { DrawnNote() }
                .place(108, 51, 864, 909)

            NavigationLink(value: Route.club) { ClubCover() }
                .buttonStyle(.squish)
                .place(382, 93, 317, 489, rotation: -4)
            StickerView(.navyHearts).place(124, 81, 188, 265)

            DesignText("plot twist", size: 92, color: .marigold, tracking: -0.078).place(57, 593, 966, 111)
            DesignText("\(Month.name()) book club", size: 56, serif: true, color: .rose).place(181, 684, 718, 67)
            NavigationLink(value: Route.club) {
                ArtboardPill(title: "join the chat", fill: .olive, text: .cream, fontSize: 52)
            }
            .buttonStyle(.squish)
            .place(348, 779, 418, 98, rotation: -3.3)

            // Red and pink striped band with torn notebook paper along its top edge
            StripedPaper(kind: .red).place(0, 1158, 1080, 772)
            Artwork(name: "paper-linedPaper", contentMode: .fill, alignment: .bottom) { DrawnLinedStrip() }
                .place(-75, 1007, 1264, 233, rotation: 180)
            Artwork(name: "paper-linedPaper", contentMode: .fill, alignment: .top) { EmptyView() }
                .place(-184, 1118, 1264, 166)

            NavigationLink(value: Route.shelf) { PunchCardView() }
                .buttonStyle(.squish)
                .place(103, 1115, 925, 604, rotation: -3)

            NavigationLink(value: Route.friends) {
                ArtboardPill(title: "friends", fill: .powder, text: .brick, fontSize: 63)
            }
            .buttonStyle(.squish)
            .place(210, 1763, 660, 98, rotation: -3.3)
            StickerView(.pinkHeart).place(729, 1721, 182, 162, rotation: 17)
        }
    }
}

private struct ClubCover: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        if let club = model.club {
            BookCover(club.book).shadow(color: .black.opacity(0.3), radius: 6, x: 3, y: 6)
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 4).fill(Color.butter)
                Text("this month's pick is coming soon")
                    .font(.serif(16))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.brick)
                    .padding(10)
            }
            .shadow(color: .black.opacity(0.2), radius: 4, y: 3)
        }
    }
}

/// "daryn mae's punch card": ten holes, one per finished book.
private struct PunchCardView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.designScale) private var s

    var body: some View {
        let card = model.punchCard
        // Local design coordinates: 925 × 604 (the group is rotated by the caller).
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 30 * s).fill(Color.cream)
                .shadow(color: .black.opacity(0.18), radius: 5 * s, y: 4 * s)
                .place(0, 55, 875, 499)
            RoundedRectangle(cornerRadius: 24 * s).strokeBorder(Color.brick, lineWidth: 5 * s).place(26, 74, 832, 459)

            DesignText("\(model.me?.possessive ?? "your") punch card", size: 42, serif: true, color: .rose).place(122, 134, 536, 49)
            DesignText(Date.now.formatted(.dateTime.month(.wide)), size: 80, serif: true, italic: true, color: .powder)
                .place(-181, 281, 580, 103, rotation: -90)

            ForEach(0..<PunchCard.holesPerCard, id: \.self) { i in
                let col = CGFloat(i % 5), row = CGFloat(i / 5)
                Hole(punched: i < card.punched)
                    .place(179 + col * 126, 229 + row * 130, 108, 108)
            }

            StickerView(.scallop).place(678, -16, 208, 208)
            DesignText(card.punched == PunchCard.holesPerCard ? "full\ncard!" : "\(card.toNextCard)\nmore!",
                       size: 58, color: .brick, tracking: -0.05)
                .place(678, 11, 208, 150, rotation: 9)
        }
        .frame(width: 925 * s, height: 604 * s, alignment: .topLeading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Punch card \(card.cardNumber): \(card.punched) of 10 books. \(card.toNextCard) more to fill it.")
    }
}

private struct Hole: View {
    var punched: Bool
    var body: some View {
        ZStack {
            StickerView(.roundFrame)
            if punched {
                // The hole shows the striped paper underneath, with a heart punch.
                Circle().fill(Color(hex: 0xB8321C)).padding(4)
                Image(systemName: "heart.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(Color.blush)
                    .padding(11)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.4, bounce: 0.5), value: punched)
    }
}

// MARK: - Artboard 3: profile, explore, share

private struct MenuArtboard: View {
    @Environment(\.designScale) private var s
    var share: () -> Void

    var body: some View {
        Artboard(height: 1180) {
            Color.honey.place(0, 0, 1080, 1180)
            StripedPaper(kind: .red).place(0, 0, 1080, 463)

            NavigationLink(value: Route.profile) {
                ArtboardPill(title: "profile", fill: .marigold, text: .brick, fontSize: 63)
            }
            .buttonStyle(.squish)
            .place(208, 79, 660, 98, rotation: 3.2)
            NavigationLink(value: Route.explore) {
                ArtboardPill(title: "explore books", fill: .butter, text: .brick, fontSize: 63)
            }
            .buttonStyle(.squish)
            .place(206, 237, 660, 98, rotation: -3.4)

            Artwork(name: Sticker.starTape.assetName, contentMode: .fill, alignment: .top) { StickerView(.starTape) }
                .place(-195, 451, 1491, 323)
            Button(action: share) { StickerView(.speechHeart) }
                .buttonStyle(.squish)
                .place(334, 612, 432, 307)
            StickerView(.pinkStar).place(96, 20, 216, 216)
            StickerView(.bow).place(732, 274, 167, 139, rotation: 8)

            Button(action: share) {
                // Her lettering is set very tight (line height 0.67), so each line gets its own short row.
                VStack(spacing: 0) {
                    ForEach(["share your", "plot twist"], id: \.self) { line in
                        Text(line)
                            .font(.display(115 * s))
                            .tracking(-0.078 * 115 * s)
                            .foregroundStyle(Color.powder)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(width: 666 * s, height: 77 * s)
                    }
                }
                .accessibilityElement(children: .combine)
            }
            .buttonStyle(.squish)
            .place(218, 900, 666, 216)
        }
    }
}

// MARK: - Artboard 4: library, top 8, badges

private struct LibraryArtboard: View {
    @Environment(AppModel.self) private var model
    @Environment(\.designScale) private var s

    var body: some View {
        Artboard(height: 2160) {
            StripedPaper(kind: .blue).place(0, 0, 1080, 2160)

            DesignText("\(model.me?.possessive ?? "my") library", size: 177, color: .brick, tracking: -0.078)
                .place(94, 43, 869, 335)

            // Top 8
            Frame().place(64, 479, 951, 792)
            ForEach(0..<8, id: \.self) { i in
                let x: CGFloat = 160 + CGFloat(i % 4) * 196.3
                let y: CGFloat = i < 4 ? 605 : 890
                Ellipse().fill(Color.black.opacity(0.28)).blur(radius: 6 * s).place(x - 20, y + 228, 215, 40)
                NavigationLink(value: Route.topEight) {
                    if let book = model.topEight[safe: i] ?? nil {
                        BookCover(book)
                    } else {
                        EmptySlot(number: i + 1)
                    }
                }
                .buttonStyle(.squish)
                .place(x, y, 175, 263)
            }
            NavigationLink(value: Route.topEight) {
                ArtboardPill(title: "top 8", fill: .marigold, text: .brick, fontSize: 92)
            }
            .buttonStyle(.squish)
            .place(523, 437, 446, 121, rotation: 3.2)

            // Badges
            NavigationLink(value: Route.badges) {
                ZStack(alignment: .topLeading) {
                    Frame().place(0, 0, 951, 792)
                    PatchBoard().place(0, 0, 951, 792)
                }
                .frame(width: 951 * s, height: 792 * s, alignment: .topLeading)
            }
            .buttonStyle(.squish)
            .place(64, 1316, 951, 792)
            NavigationLink(value: Route.badges) {
                ArtboardPill(title: "badges", fill: .blush, text: .brick, fontSize: 92)
            }
            .buttonStyle(.squish)
            .place(39, 1307, 446, 121, rotation: -5.6)
        }
    }
}

/// Cream frame with an inner brick border (top 8 and badges boards).
private struct Frame: View {
    @Environment(\.designScale) private var s
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 51 * s).fill(Color.cream)
                .shadow(color: .black.opacity(0.12), radius: 4 * s, y: 3 * s)
            RoundedRectangle(cornerRadius: 40 * s).strokeBorder(Color.brick, lineWidth: 4 * s).padding(31 * s)
        }
    }
}

private struct EmptySlot: View {
    var number: Int
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4).fill(Color.butter.opacity(0.6))
            RoundedRectangle(cornerRadius: 4).strokeBorder(Color.brick.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
            Image(systemName: "plus").font(.system(size: 14, weight: .bold)).foregroundStyle(Color.brick.opacity(0.6))
        }
        .accessibilityLabel("Empty top 8 slot \(number)")
    }
}

/// Earned badges pinned to the board as embroidered patches.
private struct PatchBoard: View {
    @Environment(AppModel.self) private var model
    @Environment(\.designScale) private var s

    // Spots on the board (local design coordinates), loosely following her layout.
    private static let spots: [(x: CGFloat, y: CGFloat, size: CGFloat, rot: Double)] = [
        (481, 60, 230, -6), (680, 170, 220, 8), (380, 280, 210, -3), (120, 330, 230, 10), (640, 400, 190, -12), (170, 560, 170, 4), (430, 520, 200, 6),
    ]

    var body: some View {
        let codes = Array(NSOrderedSet(array: model.badges.map(\.badgeCode)).compactMap { $0 as? String })
        let infos = codes.compactMap(Badges.info)
        ZStack(alignment: .topLeading) {
            if infos.isEmpty {
                DesignText("finish a book to earn your first patch", size: 52, serif: true, color: .rose)
                    .place(140, 260, 671, 300)
            } else {
                ForEach(Array(infos.prefix(Self.spots.count).enumerated()), id: \.element.code) { i, info in
                    let spot = Self.spots[i]
                    BadgePatch(badge: info)
                        .place(spot.x, spot.y, spot.size, spot.size, rotation: spot.rot)
                }
                if infos.count > Self.spots.count {
                    DesignText("+\(infos.count - Self.spots.count) more", size: 44, color: .brick).place(640, 650, 260, 70)
                }
            }
        }
        .frame(width: 951 * s, height: 792 * s, alignment: .topLeading)
    }
}

extension Array {
    subscript(safe index: Int) -> Element? { indices.contains(index) ? self[index] : nil }
}

/// Fallback for the layered note if its artwork is missing.
private struct DrawnNote: View {
    var body: some View {
        ZStack {
            TornPaper(edges: [.bottom, .trailing], roughness: 4, seed: 31)
                .fill(Color(hex: 0xF5BFCB))
                .rotationEffect(.degrees(4))
                .padding([.leading, .top], 16)
            TornPaper(edges: [.bottom], roughness: 5, seed: 32)
                .fill(LinearGradient(colors: [Color(hex: 0xFBF7EC), Color(hex: 0xF1EBDC)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
                .padding([.trailing, .bottom], 14)
        }
    }
}

/// Fallback for the torn notebook strip if its artwork is missing.
private struct DrawnLinedStrip: View {
    var body: some View {
        ZStack {
            TornPaper(edges: [.top, .bottom], roughness: 5, seed: 33).fill(Color(hex: 0xFBF8F0))
            RuledLines(spacing: 10).mask(TornPaper(edges: [.top, .bottom], roughness: 5, seed: 33))
        }
        .shadow(color: .black.opacity(0.12), radius: 1.5, y: 1)
    }
}
