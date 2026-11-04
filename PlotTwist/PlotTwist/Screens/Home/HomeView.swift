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
    case clubAdmin
    /// Your shelves, opened on the Reading tab.
    case reading
}

/// The home screen: her "Plot Twist" Canva file, one continuous scroll made of
/// four artboards stacked top to bottom. Each artboard animates onto the page as
/// it scrolls in (see Theme/Motion.swift).
struct HomeView: View {
    @Environment(AppModel.self) private var model
    @State private var addingBook = false
    @State private var sharing = false

    var body: some View {
        GeometryReader { geo in
            // Skip the zero-width first layout pass so nothing is drawn at scale 0.
            if geo.size.width > 0 {
                ScrollView {
                    // Lazy: only the artboards near the screen are built, which keeps launch and scrolling fast.
                    LazyVStack(spacing: 0) {
                        if model.isDemo { DemoBanner() }
                        ReadingArtboard(addBook: { addingBook = true })
                        ClubArtboard()
                        MenuArtboard(share: { sharing = true })
                        LibraryArtboard()
                        Wordmark(size: 22)
                            .idle(.wobble(3), period: 1.6)
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
        .background(Color.cream.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $addingBook) { AddBookSheet(defaultStatus: .tbr) }
        .sheet(isPresented: $sharing) { ShareCardSheet() }
        .navigationDestination(for: Route.self) { route in
            switch route {
            case .shelf: ShelfView()
            case .reading: ShelfView(start: .reading)
            case .book(let id): BookDetailView(userBookID: id)
            case .receipt: ReceiptView()
            case .club: ClubChatView()
            case .friends: FriendsView()
            case .profile: ProfileView()
            case .explore: ExploreView()
            case .topEight: TopEightEditor()
            case .badges: BadgeBookView()
            case .reader(let username): ReaderView(username: username)
            case .clubAdmin: ClubPickEditor()
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

    /// One book: open it. Several: open the Reading shelf. None: pick from the TBR.
    private var currentReadRoute: Route {
        let reading = model.currentlyReading
        if reading.count == 1, let only = reading.first { return .book(only.id) }
        return reading.isEmpty ? .shelf : .reading
    }

    var body: some View {
        Artboard(height: 1880) {
            StripedPaper(kind: .blue, top: 0).place(0, 0, 1080, 1880)

            // Header card: the dashed border draws itself around the headline.
            RoundedRectangle(cornerRadius: 51 * s).fill(Color.cream).decor().place(0, -57, 1080, 616)
            DrawnDashedBorder(cornerRadius: 51, lineWidth: 5).decor().place(32, 18, 1026, 516)

            // Ripped paper unfolds, the clip drops onto it, then the TBR fans out.
            Artwork(name: "paper-rippedPaper", contentMode: nil) {
                TornPaper(edges: [.trailing], roughness: 16 * s, seed: 5).fill(Color.white)
            }
            .entrance(.paper, delay: 0.15)
            .place(218, 656, 639, 869, rotation: 90)
            StickerView(.binderClip)
                .decor()
                .entrance(.drop, delay: 0.45)
                .place(322, 573, 430, 232)
            TBRCarousel().place(0, 780, 1080, 500)

            Button(action: addBook) {
                ArtboardPill(title: "add a book to your tbr", fill: .olive, text: .cream, fontSize: 33)
            }
            .buttonStyle(.squish)
            .idle(.pulse(1.05), period: 0.9)
            .entrance(.pop(spin: 8), delay: 0.9)
            .place(324, 1295, 418, 98, rotation: 2.3)

            StickerView(.goldStar).decor().idle(.spin, period: 9).entrance(.pop(spin: -180), delay: 0.5).place(60, 734, 96, 101)
            StickerView(.redBurst).decor().idle(.pulse(1.15), period: 0.8).entrance(.pop(spin: 90), delay: 0.55).place(115, 628, 127, 122)
            StickerView(.smiley).decor().idle(.wobble(12), period: 1.1).entrance(.pop(spin: 200), delay: 0.65).place(901, 734, 111, 111, rotation: -11)

            // Current read(s): one book looks exactly like her design; several become a fanned stack.
            NavigationLink(value: currentReadRoute) {
                ArtboardPill(title: model.currentlyReading.count > 1 ? "your current reads" : "your current read",
                             fill: .blush, text: .cream, fontSize: 46)
            }
            .buttonStyle(.squish)
            .idle(.wobble(1.5), period: 1.8)
            .entrance(.fly(x: 220, y: 0), delay: 0.5)
            .place(601, 456, 581, 136, rotation: -6)
            CurrentReadsDeck()
                .idle(.bob(5), period: 2.2)
                .entrance(.drop, delay: 0.2)
                .place(716, 119, 242, 359, rotation: 5)
            StickerView(.daisies)
                .decor()
                .idle(.wobble(7), period: 1.7)
                .entrance(.pop(spin: -120), delay: 0.45)
                .place(769, -30, 222, 167)
            StickerView(.arrow)
                .decor()
                .idle(.nudge(x: -7, y: -5), period: 0.6)
                .entrance(.pop(), delay: 0.8)
                .place(959, 407, 85, 63, rotation: 19)

            HeadlineLines().decor().place(82, 78, 635, 396)

            // Reading receipt printer
            NavigationLink(value: Route.receipt) { ReceiptPrinter() }
                .buttonStyle(.squish)
                .entrance(.rise, delay: 0.3)
                .place(103, 1457, 864, 382)
            StickerView(.paperPlane)
                .decor()
                .idle(.bob(8), period: 1.4)
                .entrance(.fly(x: -260, y: 140), delay: 0.6)
                .place(-134, 1401, 432, 264)
        }
    }
}

/// "hot girls collect books faster than we can read them", set on her four
/// lines with her 1.09 line height; each line slides up in turn.
private struct HeadlineLines: View {
    @Environment(\.designScale) private var s
    private let lines = ["hot girls collect", "books faster", "than we can", "read them"]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(lines.enumerated()), id: \.offset) { i, line in
                Text(line)
                    .font(.serif(89 * s))
                    .foregroundStyle(Color.honey)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(height: 89 * 1.09 * s, alignment: .leading)
                    .entrance(.rise, delay: 0.1 + Double(i) * 0.09)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

/// Her dashed brick border, drawn on like a pen tracing round the card.
private struct DrawnDashedBorder: View {
    @Environment(\.designScale) private var s
    @Environment(\.revealed) private var revealed
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var cornerRadius: CGFloat
    var lineWidth: CGFloat

    var body: some View {
        let shown = revealed || reduceMotion
        RoundedRectangle(cornerRadius: cornerRadius * s)
            .inset(by: lineWidth * s / 2)
            .trim(from: 0, to: shown ? 1 : 0)
            .stroke(Color.brick, style: StrokeStyle(lineWidth: lineWidth * s, dash: [16 * s, 10 * s]))
            .animation(reduceMotion ? nil : .easeInOut(duration: 1.1).delay(shown ? 0.1 : 0), value: shown)
    }
}

/// Your current read in the header. Reading several at once? They become a
/// fanned stack: swipe it (or tap a peeking cover) to bring the next one to the
/// front, tap the front cover to open it. It also flips through on its own.
private struct CurrentReadsDeck: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Which book is in front. Grows forever; wrapped with modulo.
    @State private var front = 0
    @State private var drag: CGFloat = 0
    @State private var pausedUntil = Date.distantPast

    /// Covers drawn behind the front one.
    private let peeking = 2

    var body: some View {
        let reading = model.currentlyReading
        if reading.isEmpty {
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
        } else {
            GeometryReader { geo in
                let w = geo.size.width
                ZStack {
                    // Back to front, so the front cover is drawn last.
                    ForEach(Array(reading.enumerated()), id: \.element.id) { index, row in
                        let d = stackDepth(of: index, count: reading.count)
                        if d <= peeking {
                            card(row, depth: d, width: w)
                                .zIndex(Double(peeking - d))
                        }
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .overlay(alignment: .topLeading) {
                    if reading.count > 1 { countBadge(reading.count, width: w) }
                }
            }
            .contentShape(Rectangle())
            .simultaneousGesture(swipe(count: reading.count))
            .sensoryFeedback(.selection, trigger: front)
            .task(id: reading.count) { await autoAdvance(count: reading.count) }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(reading.count > 1 ? "Your \(reading.count) current reads" : "Your current read")
            .accessibilityAdjustableAction { direction in
                if direction == .increment { advance(by: 1) } else { advance(by: -1) }
            }
        }
    }

    /// 0 for the front cover, 1 just behind it, and so on.
    private func stackDepth(of index: Int, count: Int) -> Int {
        var d = (index - front) % count
        if d < 0 { d += count }
        return d
    }

    @ViewBuilder
    private func card(_ row: UserBook, depth: Int, width w: CGFloat) -> some View {
        let isFront = depth == 0
        Group {
            if isFront {
                NavigationLink(value: Route.book(row.id)) { BookCover(row.book) }
            } else {
                Button { advance(by: depth) } label: { BookCover(row.book) }
            }
        }
        .buttonStyle(.squish)
        .shadow(color: .black.opacity(isFront ? 0.25 : 0.15), radius: 4, x: 2, y: 4)
        // Peeking covers fan out up and to the right, like a hand of cards.
        .scaleEffect(1 - CGFloat(depth) * 0.08)
        .rotationEffect(.degrees(Double(depth) * 8 + (isFront ? Double(drag / max(w, 1)) * 18 : 0)))
        .offset(x: CGFloat(depth) * w * 0.16 + (isFront ? drag : 0), y: -CGFloat(depth) * w * 0.07)
        .brightness(isFront ? 0 : -0.04 * Double(depth))
        .animation(.spring(response: 0.45, dampingFraction: 0.72), value: front)
    }

    private func countBadge(_ count: Int, width w: CGFloat) -> some View {
        ZStack {
            StickerView(.scallop)
            VStack(spacing: -2) {
                Text("\(count)").font(.display(w * 0.13))
                Text("reads").font(.display(w * 0.075))
            }
            .foregroundStyle(Color.brick)
        }
        .frame(width: w * 0.42, height: w * 0.42)
        .rotationEffect(.degrees(-12))
        .offset(x: -w * 0.2, y: -w * 0.12)
        .idle(.wobble(6), period: 1.1)
        .decor()
    }

    private func swipe(count: Int) -> some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                guard count > 1, abs(value.translation.width) > abs(value.translation.height) else { return }
                drag = value.translation.width
                pausedUntil = .now.addingTimeInterval(6)
            }
            .onEnded { value in
                guard count > 1 else { return }
                let flung = abs(value.predictedEndTranslation.width) > 60
                withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                    if flung { front += 1 }
                    drag = 0
                }
            }
    }

    private func advance(by steps: Int) {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) { front += steps }
        pausedUntil = .now.addingTimeInterval(6)
    }

    /// Flips to the next book every few seconds, pausing after you touch the stack.
    private func autoAdvance(count: Int) async {
        guard count > 1, !reduceMotion else { return }
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(4.5))
            guard !Task.isCancelled else { return }
            if Date.now >= pausedUntil, drag == 0 {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) { front += 1 }
            }
        }
    }
}

/// The TBR show reel: five covers fanned across the torn paper, the current one
/// in the middle. It rotates through the whole TBR on its own, and you can swipe
/// it either way. Tap the middle cover to open it, a side cover to bring it forward.
/// (Local design coordinates: the reel spans 1080 × 500, starting at y 780.)
private struct TBRCarousel: View {
    @Environment(AppModel.self) private var model
    @Environment(\.designScale) private var s
    @Environment(\.revealed) private var revealed
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Which TBR book is in the middle. Grows forever; wrapped with modulo.
    @State private var focus = 0
    @State private var drag: CGFloat = 0
    @State private var pausedUntil = Date.distantPast

    private static let originY: CGFloat = 780
    // Her five Canva slots, from far left (-2) to far right (+2): center x, top y, width, height.
    private static let centers: [CGFloat] = [250.5, 382, 543.5, 708, 829.5]
    private static let tops: [CGFloat] = [932, 898, 846, 898, 932]
    private static let widths: [CGFloat] = [145, 190, 241, 188, 145]
    private static let heights: [CGFloat] = [217, 286, 363, 286, 217]
    /// Drag distance (design px) that moves the reel by one book.
    private static let step: CGFloat = 150

    var body: some View {
        let tbr = model.tbr
        ZStack(alignment: .topLeading) {
            if tbr.isEmpty {
                NavigationLink(value: Route.shelf) {
                    Text("your tbr is empty.\nadd something juicy ↓")
                        .font(.serif(18))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.brick)
                }
                .entrance(.rise, delay: 0.6)
                .place(178, 846 - Self.originY, 724, 363)
            } else {
                ForEach(Array(tbr.enumerated()), id: \.element.id) { index, row in
                    // Only the books on (or about to slide onto) the paper are drawn.
                    if abs(slotPosition(index: index, count: tbr.count)) <= 3.2 {
                        cover(row, index: index, count: tbr.count)
                    }
                }
            }
        }
        .frame(width: Design.width * s, height: 500 * s, alignment: .topLeading)
        .contentShape(Rectangle())
        .simultaneousGesture(swipe(count: tbr.count))
        .sensoryFeedback(.selection, trigger: focus)
        .task(id: tbr.count) { await autoAdvance(count: tbr.count) }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Your TBR")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: move(by: 1)
            case .decrement: move(by: -1)
            @unknown default: break
            }
        }
    }

    /// Position of book `index` relative to the middle, including any drag in progress.
    private func slotPosition(index: Int, count: Int) -> CGFloat {
        guard count > 0 else { return 0 }
        var rel = (index - focus) % count
        if rel < 0 { rel += count }
        // Wrap so books sit on whichever side is closer.
        if rel > count / 2 { rel -= count }
        return CGFloat(rel) + drag / Self.step
    }

    /// Interpolates her slot geometry for a fractional position; beyond ±2 books fade out.
    private func geometry(at pos: CGFloat) -> (cx: CGFloat, top: CGFloat, w: CGFloat, h: CGFloat, opacity: Double) {
        let clamped = min(max(pos, -2), 2)
        let lower = Int(floor(clamped)) + 2, upper = min(lower + 1, 4)
        let t = clamped - floor(clamped)
        func lerp(_ a: [CGFloat]) -> CGFloat { a[lower] + (a[upper] - a[lower]) * t }
        let overflow = abs(pos) - 2
        let cx = lerp(Self.centers) + (overflow > 0 ? (pos > 0 ? 1 : -1) * overflow * 120 : 0)
        return (cx, lerp(Self.tops), lerp(Self.widths), lerp(Self.heights), overflow > 0 ? max(0, 1 - Double(overflow)) : 1)
    }

    @ViewBuilder
    private func cover(_ row: UserBook, index: Int, count: Int) -> some View {
        let pos = slotPosition(index: index, count: count)
        let g = geometry(at: pos)
        let shown = revealed || reduceMotion
        let isCenter = abs(pos) < 0.5
        Group {
            if isCenter {
                NavigationLink(value: Route.book(row.id)) { BookCover(row.book) }
            } else {
                Button { move(by: Int(pos.rounded())) } label: { BookCover(row.book) }
            }
        }
        .buttonStyle(.squish)
        .shadow(color: .black.opacity(0.28), radius: 5, x: 0, y: 5)
        .frame(width: g.w * s, height: g.h * s)
        .rotation3DEffect(.degrees(Double(-pos) * 10), axis: (0, 1, 0), perspective: 0.6)
        // Entrance: everything starts stacked in the middle, then fans out.
        .offset(x: shown ? 0 : (543.5 - g.cx) * s, y: shown ? 0 : 30 * s)
        .scaleEffect(shown ? 1 : 0.85)
        .opacity(shown ? g.opacity : 0)
        .position(x: g.cx * s, y: (g.top - Self.originY + g.h / 2) * s)
        .zIndex(10 - Double(abs(pos)))
        .allowsHitTesting(g.opacity > 0.5)
        .animation(reduceMotion ? nil : .spring(response: 0.6, dampingFraction: 0.62).delay(shown ? 0.55 + Double(abs(pos)) * 0.07 : 0), value: shown)
    }

    private func swipe(count: Int) -> some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                guard count > 1, abs(value.translation.width) > abs(value.translation.height) else { return }
                drag = value.translation.width / s
                pausedUntil = .now.addingTimeInterval(6)
            }
            .onEnded { value in
                guard count > 1 else { return }
                // Fast flicks move further.
                let projected = value.predictedEndTranslation.width / s
                let steps = Int((-projected / Self.step).rounded())
                withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                    focus += max(-3, min(3, steps))
                    drag = 0
                }
                pausedUntil = .now.addingTimeInterval(6)
            }
    }

    private func move(by steps: Int) {
        guard steps != 0 else { return }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) { focus += steps }
        pausedUntil = .now.addingTimeInterval(6)
    }

    /// Rotates the reel every few seconds, pausing after you touch it.
    private func autoAdvance(count: Int) async {
        guard count > 1, !reduceMotion else { return }
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(3.2))
            guard !Task.isCancelled else { return }
            if Date.now >= pausedUntil, drag == 0 {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) { focus += 1 }
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
                // The zigzag end slides out last, as if it's just been printed.
                Image(uiImage: printer).resizable().scaledToFill()
                    .frame(width: 864 * s, height: 96 * s, alignment: .bottom).clipped()
                    .contentShape(Rectangle())
                    .entrance(.drop, delay: 0.7)
                    .place(0, 286, 864, 96)
                Image(uiImage: printer).resizable().scaledToFill()
                    .frame(width: 864 * s, height: 286 * s, alignment: .top).clipped()
                    .contentShape(Rectangle())
                    .place(0, 0, 864, 286)
            } else {
                drawnPrinter
            }
            DesignText("print your \(Month.name())", size: 31, serif: true, color: .marigold)
                .entrance(.rise, delay: 0.8)
                .place(160, 185, 544, 37)
            BouncyText(text: "reading receipt", size: 63, color: .blush, delay: 0.9)
                .place(100, 208, 661, 75)
        }
        .frame(width: 864 * s, height: 382 * s, alignment: .topLeading)
        // The whole printer is one big button, and nothing outside it.
        .contentShape(Rectangle())
    }

    /// Fallback if the printer artwork is missing.
    @ViewBuilder private var drawnPrinter: some View {
        ReceiptShape(tooth: 14 * s)
            .fill(Color.white)
            .place(70, 60, 724, 322)
        RoundedRectangle(cornerRadius: 26 * s)
            .fill(LinearGradient(colors: [Color(hex: 0xF7F7F5), Color(hex: 0xDCDCD8)], startPoint: .top, endPoint: .bottom))
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
            // Continues the blue stripes from the artboard above.
            StripedPaper(kind: .blue, top: 1880).place(0, 0, 1080, 1930)

            // Layered note: pink grid sheet behind, cream ring-bound sheet in front
            Artwork(name: "paper-tornNote", contentMode: nil) { DrawnNote() }
                .entrance(.paper, delay: 0.05)
                .place(108, 51, 864, 909)

            NavigationLink(value: Route.club) { ClubCover() }
                .buttonStyle(.squish)
                .idle(.wobble(2), period: 2.4)
                .entrance(.drop, delay: 0.35)
                .place(382, 93, 317, 489, rotation: -4)
            StickerView(.navyHearts)
                .decor()
                .idle(.bob(6), period: 1.3)
                .entrance(.pop(spin: -40), delay: 0.55)
                .place(124, 81, 188, 265)

            BouncyText(text: "plot twist", size: 92, color: .marigold, delay: 0.5).decor().place(57, 593, 966, 111)
            DesignText("\(Month.name()) book club", size: 56, serif: true, color: .rose)
                .decor()
                .entrance(.rise, delay: 0.85)
                .place(181, 684, 718, 67)
            NavigationLink(value: Route.club) {
                ArtboardPill(title: "join the chat", fill: .olive, text: .cream, fontSize: 52)
            }
            .buttonStyle(.squish)
            .idle(.pulse(1.05), period: 0.9)
            .entrance(.pop(spin: -10), delay: 1.0)
            .place(348, 779, 418, 98, rotation: -3.3)

            // Red and pink stripes behind the punch card and "friends" (continued into the
            // next artboard), with a thin strip of torn notebook paper along the top edge.
            StripedPaper(kind: .red, top: 0).decor().place(0, 1158, 1080, 772)
            Artwork(name: "paper-linedPaper", contentMode: .fill, alignment: .bottom) { DrawnLinedStrip() }
                .entrance(.slide, delay: 0.1)
                .place(-75, 1007, 1264, 233, rotation: 180)
            Artwork(name: "paper-linedPaper", contentMode: .fill, alignment: .top) { EmptyView() }
                .entrance(.slide, delay: 0.2)
                .place(-184, 1118, 1264, 166)

            NavigationLink(value: Route.shelf) { PunchCardView() }
                .buttonStyle(.squish)
                .entrance(.paper, delay: 0.3)
                .place(103, 1115, 925, 604, rotation: -3)

            NavigationLink(value: Route.friends) {
                ArtboardPill(title: "friends", fill: .powder, text: .brick, fontSize: 63)
            }
            .buttonStyle(.squish)
            .idle(.wobble(1.5), period: 1.5)
            .entrance(.fly(x: -240, y: 0), delay: 0.6)
            .place(210, 1763, 660, 98, rotation: -3.3)
            StickerView(.pinkHeart)
                .decor()
                .idle(.pulse(1.14), period: 0.45)
                .entrance(.pop(spin: 45), delay: 0.8)
                .place(729, 1721, 182, 162, rotation: 17)
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
        }
    }
}

/// "daryn mae's punch card": ten holes, one per finished book. The holes punch
/// themselves one by one (with a tap of haptics) when the card comes into view.
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
                Hole(punched: i < card.punched, delay: 0.7 + Double(i) * 0.12)
                    .place(179 + col * 126, 229 + row * 130, 108, 108)
            }

            StickerView(.scallop)
                .idle(.spin, period: 14)
                .entrance(.pop(spin: -270), delay: 0.5)
                .place(678, -16, 208, 208)
            DesignText(card.punched == PunchCard.holesPerCard ? "full\ncard!" : "\(card.toNextCard)\nmore!",
                       size: 68, color: .brick, tracking: -0.02, lineHeight: 0.85)
                .idle(.wobble(5), period: 0.9)
                .entrance(.pop(spin: 30), delay: 0.65)
                .place(678, 11, 208, 160, rotation: 9)
        }
        .frame(width: 925 * s, height: 604 * s, alignment: .topLeading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Punch card \(card.cardNumber): \(card.punched) of 10 books. \(card.toNextCard) more to fill it.")
    }
}

private struct Hole: View {
    @Environment(\.revealed) private var revealed
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var punched: Bool
    var delay: Double
    @State private var showing = false

    var body: some View {
        ZStack {
            StickerView(.roundFrame)
            if showing {
                // A heart punched through to the striped paper underneath.
                Circle().fill(Color(hex: 0xB8321C)).padding(4)
                    .transition(.scale(scale: 0.2).combined(with: .opacity))
                Image(systemName: "heart.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(Color.blush)
                    .padding(11)
                    .transition(.scale(scale: 2.2).combined(with: .opacity))
            }
        }
        .sensoryFeedback(.impact(weight: .light, intensity: 0.7), trigger: showing) { _, now in now }
        .task(id: revealed && punched) {
            guard revealed, punched else { showing = false; return }
            if reduceMotion { showing = true; return }
            try? await Task.sleep(for: .seconds(delay))
            withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) { showing = true }
        }
    }
}

// MARK: - Artboard 3: profile, explore, share

private struct MenuArtboard: View {
    @Environment(\.designScale) private var s
    var share: () -> Void

    var body: some View {
        Artboard(height: 1180) {
            Color.honey.place(0, 0, 1080, 1180)
            // Red stripes behind "profile" and "explore books", continuing from the band above.
            StripedPaper(kind: .red, top: 772).decor().place(0, 0, 1080, 463)

            NavigationLink(value: Route.profile) {
                ArtboardPill(title: "profile", fill: .marigold, text: .brick, fontSize: 63)
            }
            .buttonStyle(.squish)
            .idle(.wobble(1.5), period: 1.7)
            .entrance(.fly(x: 260, y: 0), delay: 0.1)
            .place(208, 79, 660, 98, rotation: 3.2)
            NavigationLink(value: Route.explore) {
                ArtboardPill(title: "explore books", fill: .butter, text: .brick, fontSize: 63)
            }
            .buttonStyle(.squish)
            .idle(.wobble(1.5), period: 1.9)
            .entrance(.fly(x: -260, y: 0), delay: 0.2)
            .place(206, 237, 660, 98, rotation: -3.4)

            Artwork(name: Sticker.starTape.assetName, contentMode: .fill, alignment: .top) { StickerView(.starTape) }
                .entrance(.slide, delay: 0.15)
                .place(-195, 451, 1491, 323)
            Button(action: share) { StickerView(.speechHeart) }
                .buttonStyle(.squish)
                .idle(.bob(7), period: 1.2)
                .entrance(.pop(spin: -25), delay: 0.45)
                .place(334, 612, 432, 307)
            StickerView(.pinkStar).decor().idle(.spin, period: 7).entrance(.pop(spin: 180), delay: 0.35).place(96, 20, 216, 216)
            StickerView(.bow).decor().idle(.wobble(10), period: 0.9).entrance(.pop(spin: -60), delay: 0.4).place(732, 274, 167, 139, rotation: 8)

            Button(action: share) {
                // Her lettering is set very tight (line height 0.67), so each line gets its own short row.
                VStack(spacing: 0) {
                    BouncyText(text: "share your", size: 115, color: .powder, delay: 0.55)
                        .frame(height: 115 * 0.67 * s)
                    BouncyText(text: "plot twist", size: 115, color: .powder, delay: 0.85)
                        .frame(height: 115 * 0.67 * s)
                }
                .idle(.bob(4), period: 1.6)
            }
            .buttonStyle(.squish)
            .place(168, 925, 766, 166)
        }
    }
}

// MARK: - Artboard 4: library, top 8, badges

private struct LibraryArtboard: View {
    @Environment(AppModel.self) private var model
    @Environment(\.designScale) private var s

    var body: some View {
        Artboard(height: 2160) {
            StripedPaper(kind: .blue, top: 0).place(0, 0, 1080, 2160)

            // Two lines at her 0.67 line height, letters bouncing in.
            VStack(spacing: 0) {
                BouncyText(text: model.me?.possessive ?? "my", size: 177, color: .brick, delay: 0.05)
                    .frame(height: 177 * 0.67 * s)
                BouncyText(text: "library", size: 177, color: .brick, delay: 0.35)
                    .frame(height: 177 * 0.67 * s)
            }
            .decor()
            .place(40, 70, 1000, 280)

            // Top 8
            Frame().decor().entrance(.paper, delay: 0.2).place(64, 479, 951, 792)
            ForEach(0..<8, id: \.self) { i in
                let x: CGFloat = 160 + CGFloat(i % 4) * 196.3
                let y: CGFloat = i < 4 ? 605 : 890
                Ellipse().fill(Color.black.opacity(0.28)).blur(radius: 6 * s)
                    .decor()
                    .entrance(.rise, delay: 0.5 + Double(i) * 0.07)
                    .place(x - 20, y + 228, 215, 40)
                NavigationLink(value: Route.topEight) {
                    if let book = model.topEight[safe: i] ?? nil {
                        BookCover(book)
                    } else {
                        EmptySlot(number: i + 1)
                    }
                }
                .buttonStyle(.squish)
                .entrance(.flip, delay: 0.5 + Double(i) * 0.07)
                .place(x, y, 175, 263)
            }
            NavigationLink(value: Route.topEight) {
                ArtboardPill(title: "top 8", fill: .marigold, text: .brick, fontSize: 92)
            }
            .buttonStyle(.squish)
            .idle(.wobble(2.5), period: 1.3)
            .entrance(.pop(spin: 25), delay: 0.4)
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
            .entrance(.paper, delay: 0.3)
            .place(64, 1316, 951, 792)
            NavigationLink(value: Route.badges) {
                ArtboardPill(title: "badges", fill: .blush, text: .brick, fontSize: 92)
            }
            .buttonStyle(.squish)
            .idle(.wobble(2.5), period: 1.5)
            .entrance(.pop(spin: -25), delay: 0.5)
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

/// Earned badges pinned to the board as embroidered patches. They spin onto
/// the board one by one, then keep swaying.
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
                    .entrance(.rise, delay: 0.6)
                    .place(140, 260, 671, 300)
            } else {
                ForEach(Array(infos.prefix(Self.spots.count).enumerated()), id: \.element.code) { i, info in
                    let spot = Self.spots[i]
                    BadgePatch(badge: info)
                        .idle(.wobble(4), period: 1.4 + Double(i % 3) * 0.3)
                        .entrance(.pop(spin: i.isMultiple(of: 2) ? -220 : 220), delay: 0.7 + Double(i) * 0.1)
                        .place(spot.x, spot.y, spot.size, spot.size, rotation: spot.rot)
                }
                if infos.count > Self.spots.count {
                    DesignText("+\(infos.count - Self.spots.count) more", size: 44, color: .brick)
                        .entrance(.rise, delay: 1.4)
                        .place(640, 650, 260, 70)
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
