import SwiftUI

/// All shelves: currently reading, the ranked TBR (drag to reorder), and finished.
struct ShelfView: View {
    @Environment(AppModel.self) private var model
    @State private var shelf: ShelfStatus = .tbr
    @State private var formatFilter: BookFormat?
    @State private var adding = false

    private var rows: [UserBook] {
        let base: [UserBook] = switch shelf {
        case .tbr: model.tbr
        case .reading: model.currentlyReading
        case .read: model.finished.sorted { ($0.finishedAt ?? "") > ($1.finishedAt ?? "") }
        }
        guard let formatFilter else { return base }
        return base.filter { $0.formats.contains(formatFilter) }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    ScreenTitle(title: "my shelves", subtitle: subtitle)
                    Picker("Shelf", selection: $shelf) {
                        Text("tbr").tag(ShelfStatus.tbr)
                        Text("reading").tag(ShelfStatus.reading)
                        Text("finished").tag(ShelfStatus.read)
                    }
                    .pickerStyle(.segmented)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            chip("all", nil)
                            ForEach(BookFormat.allCases) { chip($0.label.lowercased(), $0) }
                        }
                    }
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            Section {
                if rows.isEmpty {
                    Text(emptyText)
                        .font(.serif(18))
                        .foregroundStyle(Color.rose)
                        .listRowBackground(Color.clear)
                }
                ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                    NavigationLink(value: Route.book(row.id)) {
                        ShelfRow(row: row, rank: shelf == .tbr && formatFilter == nil ? index + 1 : nil)
                    }
                    .listRowBackground(RoundedRectangle(cornerRadius: 14).fill(Color.cream).padding(.vertical, 3))
                    .listRowSeparator(.hidden)
                    .swipeActions(edge: .leading) {
                        if row.status != .read {
                            Button { Task { await model.setStatus(row, .read) } } label: { Label("Finished", systemImage: "checkmark.circle") }
                                .tint(.olive)
                        }
                    }
                }
                .onMove(perform: moveAction)
            }
        }
        .listStyle(.plain)
        .scrapbookScreen()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { adding = true } label: { Image(systemName: "plus.circle.fill").font(.title2) }
                    .accessibilityLabel("Add a book")
            }
        }
        .sheet(isPresented: $adding) { AddBookSheet(defaultStatus: shelf) }
        .refreshable { await model.refresh() }
    }

    /// Drag to rank only makes sense on the full, unfiltered TBR.
    private var moveAction: ((IndexSet, Int) -> Void)? {
        guard shelf == .tbr, formatFilter == nil else { return nil }
        return { from, to in Task { await model.moveTBR(from: from, to: to) } }
    }

    private var subtitle: String {
        switch shelf {
        case .tbr: "\(model.tbr.count) waiting · hold and drag to rank"
        case .reading: "\(model.currentlyReading.count) on the go"
        case .read: "\(model.finished.count) finished · \(model.finishedThisMonth) this month"
        }
    }

    private var emptyText: String {
        switch shelf {
        case .tbr: "nothing on your tbr yet. tap + to add a book."
        case .reading: "not reading anything right now. pick something from your tbr!"
        case .read: "finish a book to punch your card."
        }
    }

    private func chip(_ title: String, _ format: BookFormat?) -> some View {
        let on = formatFilter == format
        return Button { formatFilter = format } label: {
            Text(title)
                .font(.display(13, weight: .bold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .foregroundStyle(on ? Color.cream : Color.brick)
                .background(Capsule().fill(on ? Color.brick : Color.cream))
        }
        .buttonStyle(.plain)
    }
}

private struct ShelfRow: View {
    let row: UserBook
    var rank: Int?

    var body: some View {
        HStack(spacing: 12) {
            if let rank {
                Text("\(rank)").font(.display(16)).foregroundStyle(Color.marigold).frame(width: 24)
            }
            BookCover(row.book).frame(width: 44, height: 66)
            VStack(alignment: .leading, spacing: 3) {
                Text(row.book.title).font(.serif(18)).foregroundStyle(Color.brick).lineLimit(2)
                Text(row.book.authorLine.lowercased()).font(.display(12, weight: .semiBold)).foregroundStyle(Color.rose).lineLimit(1)
                HStack(spacing: 6) {
                    ForEach(row.formats) { Image(systemName: $0.symbol) }
                    if let rating = row.rating {
                        Text(String(repeating: "★", count: rating)).foregroundStyle(Color.marigold)
                    }
                }
                .font(.caption)
                .foregroundStyle(Color.brick.opacity(0.7))
            }
        }
        .padding(.vertical, 6)
    }
}

/// One book on your shelves: move it between shelves, formats, rating.
struct BookDetailView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let userBookID: UUID
    @State private var formats: Set<BookFormat> = []
    @State private var confirmRemove = false

    private var row: UserBook? { model.shelf.first { $0.id == userBookID } }

    var body: some View {
        ScrollView {
            if let row {
                VStack(spacing: 20) {
                    BookCover(row.book)
                        .frame(width: 180, height: 270)
                        .rotationEffect(.degrees(4))
                        .shadow(color: .black.opacity(0.25), radius: 8, y: 6)
                        .overlay(alignment: .topTrailing) { StickerView(.daisies).frame(width: 80, height: 60).offset(x: 30, y: -30) }
                        .padding(.top, 20)
                    VStack(spacing: 4) {
                        Text(row.book.title).font(.serif(30)).multilineTextAlignment(.center).foregroundStyle(Color.brick)
                        Text(row.book.authorLine.lowercased()).font(.display(14, weight: .semiBold)).foregroundStyle(Color.rose)
                        if let pages = row.book.pageCount { Text("\(pages) pages").font(.display(12, weight: .semiBold)).foregroundStyle(.secondary) }
                    }
                    Pill(title: row.status.label.lowercased(), fill: .blush, text: .brick, size: 14).rotationEffect(.degrees(-3))

                    PaperCard {
                        VStack(alignment: .leading, spacing: 16) {
                            switch row.status {
                            case .tbr:
                                Button("start reading") { Task { await model.setStatus(row, .reading) } }.buttonStyle(BrickButtonStyle(fill: .olive))
                                Button("i finished it!") { Task { await model.setStatus(row, .read) } }.buttonStyle(BrickButtonStyle())
                            case .reading:
                                Button("i finished it! punch my card") { Task { await model.setStatus(row, .read) } }.buttonStyle(BrickButtonStyle())
                                Button("back to the tbr") { Task { await model.setStatus(row, .tbr) } }.buttonStyle(BrickButtonStyle(fill: .olive))
                            case .read:
                                Text("finished \(row.finishedAt ?? "")").font(.display(14)).foregroundStyle(Color.brick)
                                RatingPicker(rating: row.rating) { r in Task { await model.perform(haptic: nil) { try await model.backend.setRating(row.id, r) } } }
                                Button("read it again") { Task { await model.setStatus(row, .reading) } }.buttonStyle(BrickButtonStyle(fill: .olive))
                            }
                            Text("formats").font(.display(15)).foregroundStyle(Color.brick)
                            FormatPicker(formats: $formats)
                                .onChange(of: formats) { _, new in
                                    guard Set(row.formats) != new, !new.isEmpty else { return }
                                    Task { await model.perform(haptic: nil) { try await model.backend.setFormats(row.id, BookFormat.allCases.filter(new.contains)) } }
                                }
                        }
                    }
                    Button("remove from my shelves", role: .destructive) { confirmRemove = true }
                        .font(.display(14, weight: .bold))
                }
                .padding(20)
                .onAppear { formats = Set(row.formats) }
                .confirmationDialog("Remove \(row.book.title)?", isPresented: $confirmRemove, titleVisibility: .visible) {
                    Button("Remove", role: .destructive) {
                        Task {
                            if await model.perform(haptic: .warning, { try await model.backend.removeFromShelf(row.id) }) { dismiss() }
                        }
                    }
                }
            } else {
                Text("this book isn't on your shelves anymore.").font(.serif(20)).foregroundStyle(Color.rose).padding(40)
            }
        }
        .scrapbookScreen()
    }
}

private struct RatingPicker: View {
    var rating: Int?
    var onChange: (Int?) -> Void

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...5, id: \.self) { i in
                Button { onChange(rating == i ? nil : i) } label: {
                    Image(systemName: i <= (rating ?? 0) ? "star.fill" : "star")
                        .font(.title2)
                        .foregroundStyle(Color.marigold)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(i) stars")
            }
        }
    }
}
