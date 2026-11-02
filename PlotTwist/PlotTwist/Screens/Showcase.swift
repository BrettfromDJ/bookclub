import SwiftUI
import UIKit

/// Pick the eight books on your showcase shelf.
struct TopEightEditor: View {
    @Environment(AppModel.self) private var model
    @State private var editingSlot: Int?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ScreenTitle(title: "top 8", subtitle: "tap a spot to pick a favorite")
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 4), spacing: 22) {
                    ForEach(0..<8, id: \.self) { i in
                        Button { editingSlot = i + 1 } label: {
                            VStack(spacing: 6) {
                                Group {
                                    if let book = model.topEight[safe: i] ?? nil {
                                        BookCover(book)
                                    } else {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 4).fill(Color.butter.opacity(0.7))
                                            Image(systemName: "plus").font(.title3.bold()).foregroundStyle(Color.brick)
                                        }
                                    }
                                }
                                .aspectRatio(2 / 3, contentMode: .fit)
                                .shadow(color: .black.opacity(0.2), radius: 3, y: 3)
                                Text("\(i + 1)").font(.display(13)).foregroundStyle(Color.marigold)
                            }
                        }
                        .buttonStyle(.squish)
                        .contextMenu {
                            if model.topEight[safe: i] ?? nil != nil {
                                Button("Remove", systemImage: "xmark", role: .destructive) {
                                    Task { await model.perform(haptic: nil) { try await model.backend.setTopBook(slot: i + 1, book: nil) } }
                                }
                            }
                        }
                    }
                }
                .padding(18)
                .background(RoundedRectangle(cornerRadius: 24).fill(Color.cream))
                .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Color.brick, lineWidth: 1.5).padding(8))
                Text("long-press a book to remove it").font(.display(12, weight: .semiBold)).foregroundStyle(.secondary)
            }
            .padding(20)
        }
        .scrapbookScreen()
        .sheet(item: Binding(get: { editingSlot.map(SlotID.init) }, set: { editingSlot = $0?.slot })) { slot in
            TopPickSheet(slot: slot.slot)
        }
    }

    private struct SlotID: Identifiable { let slot: Int; var id: Int { slot } }
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

    /// ImageRenderer can't wait for AsyncImage, so fetch the cover from the URL cache directly.
    private var coverSnapshot: UIImage? {
        guard let s = model.currentlyReading.first?.book.coverURL, let url = URL(string: s),
              let cached = URLCache.shared.cachedResponse(for: URLRequest(url: url)) else { return nil }
        return UIImage(data: cached.data)
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
                Text("plot twist").font(.display(40)).tracking(-3).foregroundStyle(Color.marigold)
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
