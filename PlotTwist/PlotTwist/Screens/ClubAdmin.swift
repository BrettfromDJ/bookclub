import SwiftUI

/// Admins: choose the book club pick for this month or next.
struct ClubPickEditor: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var monthOffset = 0
    @State private var current: ClubMonth?
    @State private var results: [BookCandidate] = []
    @State private var searching = false
    @State private var picked: BookCandidate?
    @State private var blurb = ""
    @State private var saving = false

    private var monthDate: Date {
        Calendar.current.date(byAdding: .month, value: monthOffset, to: .now) ?? .now
    }
    private var month: String { Month.start(monthDate) }
    private var monthLabel: String { monthDate.formatted(.dateTime.month(.wide).year()).lowercased() }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ScreenTitle(title: "book club pick", subtitle: "everyone reads this together")

                Picker("Month", selection: $monthOffset) {
                    Text("this month").tag(0)
                    Text("next month").tag(1)
                }
                .pickerStyle(.segmented)

                if let current, picked == nil {
                    PaperCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("\(monthLabel)'s pick").font(.display(13)).foregroundStyle(Color.rose)
                            CandidateRow(book: current.book.candidate)
                            if !current.blurb.isEmpty { Text(current.blurb).font(.serif(16)).foregroundStyle(Color.brick) }
                            Text("search below to change it").font(.display(11, weight: .semiBold)).foregroundStyle(.secondary)
                        }
                    }
                }

                if let picked {
                    PaperCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("new pick for \(monthLabel)").font(.display(13)).foregroundStyle(Color.rose)
                            CandidateRow(book: picked)
                            TextField("a short note for readers (optional)", text: $blurb, axis: .vertical)
                                .lineLimit(2...5)
                                .padding(10)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
                            Button {
                                Task { await save(picked) }
                            } label: {
                                if saving { ProgressView().tint(.cream) } else { Text("make it the \(monthLabel) pick") }
                            }
                            .buttonStyle(BrickButtonStyle())
                            .disabled(saving)
                            Button("choose a different book") { self.picked = nil }
                                .font(.display(13, weight: .bold))
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .entrance(.pop())
                } else {
                    BookSearchField(results: $results, searching: $searching, autofocus: false)
                    LazyVStack(spacing: 10) {
                        ForEach(results) { book in
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { picked = book }
                            } label: {
                                CandidateRow(book: book)
                                    .padding(10)
                                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.cream))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(20)
        }
        .scrollDismissesKeyboard(.immediately)
        .scrapbookScreen()
        .revealsOnAppear()
        .task(id: month) { await loadCurrent() }
    }

    private func loadCurrent() async {
        current = try? await model.backend.clubMonth(month)
        blurb = current?.blurb ?? ""
    }

    private func save(_ book: BookCandidate) async {
        saving = true
        defer { saving = false }
        let ok = await model.perform("\(book.title) is the \(monthLabel) pick!") {
            try await model.backend.setClubMonth(month, book: book, blurb: blurb)
        }
        if ok {
            picked = nil
            await loadCurrent()
        }
    }
}
