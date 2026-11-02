import SwiftUI
import UniformTypeIdentifiers
import UIKit

/// Your Top 8: tap a spot to pick a book, hold and drag to reorder.
struct TopEightEditor: View {
    @Environment(AppModel.self) private var model
    @State private var editingSlot: Int?
    /// Local copy while dragging, so the other covers shuffle out of the way live.
    @State private var slots: [TopSlot] = []
    @State private var dragging: TopSlot.ID?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ScreenTitle(title: "top 8", subtitle: "tap to pick · hold & drag to reorder")
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 4), spacing: 22) {
                    ForEach(Array(slots.enumerated()), id: \.element.id) { i, slot in
                        cell(slot, index: i)
                    }
                }
                .padding(18)
                .background(RoundedRectangle(cornerRadius: 24).fill(Color.cream))
                .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Color.brick, lineWidth: 1.5).padding(8))
                .animation(.spring(response: 0.35, dampingFraction: 0.72), value: slots.map(\.id))
                .sensoryFeedback(.selection, trigger: slots.map(\.id))
                Text("hold a book to remove it, or drag it to a new spot").font(.display(12, weight: .semiBold)).foregroundStyle(.secondary)
            }
            .padding(20)
            // Letting go anywhere on the screen (not just on a spot) still finishes the drag.
            .onDrop(of: [.text], isTargeted: nil) { _ in
                guard dragging != nil else { return false }
                dragging = nil
                commit()
                return true
            }
        }
        .scrapbookScreen()
        .revealsOnAppear()
        .onAppear(perform: syncFromModel)
        .onChange(of: model.topEight) { _, _ in if dragging == nil { syncFromModel() } }
        .sheet(item: Binding(get: { editingSlot.map(SlotID.init) }, set: { editingSlot = $0?.slot })) { slot in
            TopPickSheet(slot: slot.slot)
        }
    }

    private func cell(_ slot: TopSlot, index i: Int) -> some View {
        Button {
            dragging = nil
            editingSlot = i + 1
        } label: {
            VStack(spacing: 6) {
                Group {
                    if let book = slot.book {
                        BookCover(book)
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 4).fill(Color.butter.opacity(0.7))
                            Image(systemName: "plus").font(.title3.bold()).foregroundStyle(Color.brick)
                        }
                    }
                }
                .aspectRatio(2 / 3, contentMode: .fit)
                .shadow(color: .black.opacity(dragging == slot.id ? 0 : 0.2), radius: 3, y: 3)
                .entrance(.flip, delay: Double(i) * 0.06)
                Text("\(i + 1)").font(.display(13)).foregroundStyle(Color.marigold)
            }
            // The spot being dragged fades while its copy follows your finger.
            .opacity(dragging == slot.id ? 0.25 : 1)
            .scaleEffect(dragging == slot.id ? 0.92 : 1)
        }
        .buttonStyle(.squish)
        .onDrag {
            dragging = slot.id
            return NSItemProvider(object: slot.id as NSString)
        } preview: {
            Group {
                if let book = slot.book { BookCover(book) } else { RoundedRectangle(cornerRadius: 4).fill(Color.butter) }
            }
            .frame(width: 80, height: 120)
            .rotationEffect(.degrees(-4))
        }
        .onDrop(of: [.text], delegate: ReorderDrop(target: slot, slots: $slots, dragging: $dragging, commit: commit))
        .contextMenu {
            if slot.book != nil {
                Button("Remove", systemImage: "xmark", role: .destructive) {
                    var books = slots.map(\.book)
                    books[i] = nil
                    Task { await model.reorderTopEight(books) }
                }
            }
        }
    }

    private func syncFromModel() {
        let books = (0..<8).map { model.topEight[safe: $0] ?? nil }
        // Keep each book's identity so SwiftUI can animate moves.
        slots = books.enumerated().map { i, book in
            if let existing = slots.first(where: { $0.book?.id != nil && $0.book?.id == book?.id }) { return existing }
            return TopSlot(book: book, fallbackIndex: i)
        }
    }

    private func commit() {
        let books = slots.map(\.book)
        Task { await model.reorderTopEight(books) }
    }

    private struct SlotID: Identifiable { let slot: Int; var id: Int { slot } }
}

/// One spot in the Top 8 grid. Filled spots are identified by their book, empty
/// ones by a fresh id, so the grid animates as things move around.
struct TopSlot: Identifiable, Equatable {
    let id: String
    var book: Book?

    init(book: Book?, fallbackIndex: Int) {
        self.book = book
        id = book.map { $0.id.uuidString } ?? "empty-\(fallbackIndex)-\(UUID().uuidString)"
    }
}

/// Live reordering: as the dragged book passes over a spot, it moves there.
private struct ReorderDrop: DropDelegate {
    let target: TopSlot
    @Binding var slots: [TopSlot]
    @Binding var dragging: TopSlot.ID?
    let commit: () -> Void

    func dropEntered(info: DropInfo) {
        guard let dragging, dragging != target.id,
              let from = slots.firstIndex(where: { $0.id == dragging }),
              let to = slots.firstIndex(where: { $0.id == target.id }) else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
            slots.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? { DropProposal(operation: .move) }

    func performDrop(info: DropInfo) -> Bool {
        dragging = nil
        commit()
        return true
    }
}

private struct TopPickSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let slot: Int
    @State private var results: [BookCandidate] = []
    @State private var searching = false

    /// Books you've finished come first: they're the likeliest favorites.
    private var suggestions: [BookCandidate] {
        model.finished.map(\.book.candidate)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                ScreenTitle(title: "spot #\(slot)")
                BookSearchField(results: $results, searching: $searching, autofocus: false)
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        if results.isEmpty && !suggestions.isEmpty {
                            Text("from your finished shelf").font(.display(13)).foregroundStyle(Color.rose)
                        }
                        ForEach(results.isEmpty ? suggestions : results) { book in
                            Button {
                                Task {
                                    if await model.perform(haptic: .success, { try await model.backend.setTopBook(slot: slot, book: book) }) { dismiss() }
                                }
                            } label: { CandidateRow(book: book) }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(20)
            .background(Color.cream.ignoresSafeArea())
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("close") { dismiss() } } }
        }
    }
}

/// Every badge as a patch: earned ones in full color, the rest faded.
struct BadgeBookView: View {
    @Environment(AppModel.self) private var model
    @State private var selected: BadgeInfo?

    var body: some View {
        let earnedCodes = Set(model.badges.map(\.badgeCode))
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ScreenTitle(title: "badges", subtitle: "\(earnedCodes.count) of \(Badges.all.count) patches collected")
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 18) {
                    ForEach(Badges.all) { badge in
                        let earned = earnedCodes.contains(badge.code)
                        Button { selected = badge } label: {
                            VStack(spacing: 6) {
                                BadgePatch(badge: badge, earned: earned)
                                    .frame(width: 88, height: 88)
                                    .idle(.wobble(earned ? 4 : 0), period: 1.5)
                                    .entrance(.pop(spin: earned ? 200 : 0), delay: Double(Badges.all.firstIndex(of: badge) ?? 0) * 0.04)
                                Text(badge.name.lowercased())
                                    .font(.display(12, weight: .bold))
                                    .foregroundStyle(earned ? Color.brick : Color.brick.opacity(0.45))
                                    .multilineTextAlignment(.center)
                                if earned, let count = monthlyCount(badge.code), count > 1 {
                                    Text("×\(count)").font(.display(11, weight: .bold)).foregroundStyle(Color.marigold)
                                }
                            }
                        }
                        .buttonStyle(.squish)
                    }
                }
                .padding(18)
                .background(RoundedRectangle(cornerRadius: 24).fill(Color.cream))
            }
            .padding(20)
        }
        .scrapbookScreen()
        .revealsOnAppear()
        .alert(selected?.name ?? "", isPresented: Binding(get: { selected != nil }, set: { if !$0 { selected = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(selected?.description ?? "")
        }
    }

    /// Monthly badges can be earned more than once.
    private func monthlyCount(_ code: String) -> Int? {
        let n = model.badges.filter { $0.badgeCode == code }.count
        return n > 0 ? n : nil
    }
}

/// "share your plot twist": a card with your current read and stats, for stories or texts.
struct ShareCardSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.displayScale) private var displayScale
    @State private var image: UIImage?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                ShareCard(me: model.me, current: model.currentlyReading.first?.book, punch: model.punchCard,
                          thisMonth: model.finishedThisMonth, badges: Set(model.badges.map(\.badgeCode)).count)
                    .frame(width: 300, height: 533)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.2), radius: 10, y: 6)
                    .entrance(.paper)
                if let image {
                    ShareLink(item: Image(uiImage: image), preview: SharePreview("my plot twist", image: Image(uiImage: image))) {
                        Label("share", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(BrickButtonStyle())
                    .padding(.horizontal, 40)
                }
            }
            .padding(.top, 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(StripedBackground(stripe: .powder))
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("close") { dismiss() } } }
            .revealsOnAppear()
        }
        .task {
            // Let cover images load before snapshotting.
            try? await Task.sleep(for: .milliseconds(900))
            render()
        }
    }

    @MainActor private func render() {
        let card = ShareCard(me: model.me, current: model.currentlyReading.first?.book, punch: model.punchCard,
                             thisMonth: model.finishedThisMonth, badges: Set(model.badges.map(\.badgeCode)).count,
                             coverImage: coverSnapshot)
            .frame(width: 360, height: 640)
        let renderer = ImageRenderer(content: card)
        renderer.scale = displayScale
        image = renderer.uiImage
    }

    /// ImageRenderer can't wait for images to load, so use the already-loaded cover.
    private var coverSnapshot: UIImage? {
        guard let s = model.currentlyReading.first?.book.coverURL, let url = URL(string: s) else { return nil }
        if let loaded = ImageMemory.cache.object(forKey: url as NSURL) { return loaded }
        return URLCache.shared.cachedResponse(for: URLRequest(url: url)).flatMap { UIImage(data: $0.data) }
    }
}

/// 9:16 story card.
private struct ShareCard: View {
    let me: Profile?
    let current: Book?
    let punch: PunchCard
    let thisMonth: Int
    let badges: Int
    var coverImage: UIImage?

    var body: some View {
        ZStack {
            Stripes(stripe: .powder)
            VStack(spacing: 16) {
                Text("plot twist").font(.display(40)).tracking(-0.8).foregroundStyle(Color.marigold)
                Text("\(me?.possessive ?? "my") current read").font(.serif(22)).foregroundStyle(Color.rose)
                Group {
                    if let coverImage {
                        Image(uiImage: coverImage).resizable().scaledToFill()
                    } else if let current {
                        BookCover(current)
                    } else {
                        RoundedRectangle(cornerRadius: 4).fill(Color.butter)
                    }
                }
                .frame(width: 150, height: 225)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .rotationEffect(.degrees(4))
                .shadow(color: .black.opacity(0.25), radius: 6, y: 5)
                .overlay(alignment: .topTrailing) { StickerView(.daisies).frame(width: 74, height: 56).offset(x: 26, y: -26) }
                if let current {
                    Text(current.title).font(.display(18)).multilineTextAlignment(.center).foregroundStyle(Color.brick)
                }
                HStack(spacing: 10) {
                    stat("\(thisMonth)", "this month")
                    stat("\(punch.punched)/10", "punch card")
                    stat("\(badges)", "badges")
                }
                Pill(title: "hot girls collect books", fill: .blush, text: .cream, size: 13).rotationEffect(.degrees(-4))
            }
            .padding(24)
        }
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 0) {
            Text(value).font(.display(20)).foregroundStyle(Color.brick)
            Text(label).font(.display(9, weight: .semiBold)).foregroundStyle(Color.rose)
        }
        .frame(width: 80, height: 58)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.cream))
    }
}
