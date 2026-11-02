import SwiftUI

/// Search Google Books / Open Library as you type.
struct BookSearchField: View {
    @Binding var results: [BookCandidate]
    @Binding var searching: Bool
    var prompt = "title, author, or ISBN"
    @State private var query = ""
    @FocusState private var focused: Bool
    var autofocus = true

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundStyle(Color.brick)
            TextField(prompt, text: $query)
                .font(.display(16, weight: .semiBold))
                .foregroundStyle(Color.brick)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .focused($focused)
            if searching { ProgressView().tint(.brick) }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Capsule().fill(Color.cream))
        .overlay(Capsule().stroke(Color.brick, lineWidth: 1.5))
        .onAppear { if autofocus { focused = true } }
        .task(id: query) {
            // Debounce: wait for a pause in typing.
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            let q = query
            guard q.trimmingCharacters(in: .whitespaces).count >= 2 else { results = []; return }
            searching = true
            defer { searching = false }
            let found = (try? await BookSearch.search(q)) ?? []
            if !Task.isCancelled { results = found }
        }
    }
}

/// One search result row.
struct CandidateRow: View {
    let book: BookCandidate
    var body: some View {
        HStack(spacing: 12) {
            BookCover(book).frame(width: 48, height: 72).shadow(color: .black.opacity(0.15), radius: 2, y: 1)
            VStack(alignment: .leading, spacing: 3) {
                Text(book.title).font(.serif(18)).foregroundStyle(Color.brick).lineLimit(2)
                Text(book.authorLine.lowercased()).font(.display(12, weight: .semiBold)).foregroundStyle(Color.rose).lineLimit(1)
                if let pages = book.pageCount, pages > 0 {
                    Text("\(pages) pages").font(.display(11, weight: .semiBold)).foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
    }
}

/// Sheet: find a book and put it on a shelf.
struct AddBookSheet: View {
    @Environment(\.dismiss) private var dismiss
    var defaultStatus: ShelfStatus = .tbr
    @State private var results: [BookCandidate] = []
    @State private var searching = false
    @State private var picked: BookCandidate?

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                ScreenTitle(title: "add a book", subtitle: "to your plot twist")
                BookSearchField(results: $results, searching: $searching)
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(results) { book in
                            Button { picked = book } label: { CandidateRow(book: book) }
                                .buttonStyle(.plain)
                            Divider().overlay(Color.brick.opacity(0.2))
                        }
                    }
                    .padding(.top, 4)
                }
                .scrollDismissesKeyboard(.immediately)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .background(Color.cream.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("close") { dismiss() }.font(.display(15, weight: .bold))
                }
            }
            .navigationDestination(item: $picked) { book in
                AddConfirmView(book: book, defaultStatus: defaultStatus) { dismiss() }
            }
        }
    }
}

/// Pick formats and a shelf, then add.
struct AddConfirmView: View {
    @Environment(AppModel.self) private var model
    let book: BookCandidate
    var defaultStatus: ShelfStatus = .tbr
    var done: () -> Void
    @State private var formats: Set<BookFormat> = [.physical]
    @State private var status: ShelfStatus = .tbr
    @State private var saving = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                BookCover(book)
                    .frame(width: 160, height: 240)
                    .rotationEffect(.degrees(-3))
                    .shadow(color: .black.opacity(0.25), radius: 8, y: 6)
                    .padding(.top, 12)
                VStack(spacing: 4) {
                    Text(book.title).font(.serif(28)).multilineTextAlignment(.center).foregroundStyle(Color.brick)
                    Text(book.authorLine.lowercased()).font(.display(14, weight: .semiBold)).foregroundStyle(Color.rose)
                }
                PaperCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("how are you reading it?").font(.display(15)).foregroundStyle(Color.brick)
                        FormatPicker(formats: $formats)
                        Text("which shelf?").font(.display(15)).foregroundStyle(Color.brick)
                        Picker("Shelf", selection: $status) {
                            Text("tbr").tag(ShelfStatus.tbr)
                            Text("reading").tag(ShelfStatus.reading)
                            Text("finished").tag(ShelfStatus.read)
                        }
                        .pickerStyle(.segmented)
                    }
                }
                Button {
                    Task {
                        saving = true
                        let ok = await model.add(book, formats: BookFormat.allCases.filter(formats.contains), status: status)
                        saving = false
                        if ok { done() }
                    }
                } label: {
                    if saving { ProgressView().tint(.cream) } else { Text(status == .read ? "punch my card" : "add it") }
                }
                .buttonStyle(BrickButtonStyle())
                .disabled(saving)
            }
            .padding(20)
        }
        .background(Color.cream.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { status = defaultStatus }
    }
}

/// Explore: search any book, see the club pick, add to a shelf.
struct ExploreView: View {
    @Environment(AppModel.self) private var model
    @State private var results: [BookCandidate] = []
    @State private var searching = false
    @State private var picked: BookCandidate?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ScreenTitle(title: "explore books", subtitle: "find your next plot twist")
                BookSearchField(results: $results, searching: $searching, autofocus: false)
                if results.isEmpty, let club = model.club {
                    Text("this month's book club pick").font(.display(14)).foregroundStyle(Color.brick)
                    Button { picked = club.book.candidate } label: {
                        PaperCard { CandidateRow(book: club.book.candidate) }
                    }
                    .buttonStyle(.plain)
                    if !club.blurb.isEmpty {
                        Text(club.blurb).font(.serif(17)).foregroundStyle(Color.rose)
                    }
                }
                LazyVStack(spacing: 10) {
                    ForEach(results) { book in
                        Button { picked = book } label: {
                            CandidateRow(book: book)
                                .padding(10)
                                .background(RoundedRectangle(cornerRadius: 14).fill(Color.cream))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(20)
        }
        .scrollDismissesKeyboard(.immediately)
        .scrapbookScreen()
        .navigationDestination(item: $picked) { book in
            AddConfirmView(book: book) { picked = nil }
        }
    }
}
