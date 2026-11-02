import SwiftUI

/// "join the chat": one conversation per monthly pick, open to every reader.
struct ClubChatView: View {
    @Environment(AppModel.self) private var model
    @State private var messages: [ClubMessage] = []
    @State private var draft = ""
    @State private var sending = false
    @State private var reporting: ClubMessage?
    @FocusState private var typing: Bool

    private let month = Month.start()

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        header
                        if messages.isEmpty {
                            Text("no messages yet. say hi and start the plot twist!")
                                .font(.serif(18))
                                .foregroundStyle(Color.rose)
                                .multilineTextAlignment(.center)
                                .padding(.top, 20)
                        }
                        ForEach(messages) { message in
                            Bubble(message: message, mine: message.userID == model.me?.id)
                                .id(message.id)
                                .transition(.asymmetric(insertion: .scale(scale: 0.6, anchor: message.userID == model.me?.id ? .bottomTrailing : .bottomLeading)
                                                            .combined(with: .opacity),
                                                        removal: .opacity))
                                .contextMenu {
                                    if message.userID == model.me?.id {
                                        Button("Delete", systemImage: "trash", role: .destructive) { Task { await delete(message) } }
                                    } else {
                                        Button("Report", systemImage: "flag") { reporting = message }
                                    }
                                }
                        }
                    }
                    .padding(16)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: messages.last?.id) { _, id in
                    if let id { withAnimation { proxy.scrollTo(id, anchor: .bottom) } }
                }
            }

            composer
        }
        .scrapbookScreen(stripe: .blush)
        .revealsOnAppear()
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: messages)
        .task {
            // Simple polling keeps the chat fresh while it's open.
            while !Task.isCancelled {
                await load()
                try? await Task.sleep(for: .seconds(6))
            }
        }
        .sheet(item: $reporting) { message in
            ReportSheet(target: .message, id: message.id, what: "this message")
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            if let club = model.club {
                BookCover(club.book)
                    .frame(width: 120, height: 180)
                    .rotationEffect(.degrees(-4))
                    .shadow(color: .black.opacity(0.25), radius: 6, y: 5)
                    .idle(.wobble(2), period: 2.4)
                    .entrance(.drop)
                    .overlay(alignment: .topLeading) { StickerView(.navyHearts).frame(width: 50, height: 70).offset(x: -40, y: -10) }
                Text("\(Month.name()) book club").font(.serif(24)).foregroundStyle(Color.rose)
                Text(club.book.title).font(.display(20)).multilineTextAlignment(.center).foregroundStyle(Color.brick)
                if !club.blurb.isEmpty {
                    Text(club.blurb).font(.serif(16)).multilineTextAlignment(.center).foregroundStyle(Color.brick.opacity(0.8))
                }
                if let partner = club.partnerName {
                    Text("in partnership with \(partner)").font(.display(11, weight: .semiBold)).foregroundStyle(.secondary)
                }
                if !model.shelf.contains(where: { $0.bookID == club.book.id }) {
                    Button("add it to my tbr") {
                        Task { _ = await model.add(club.book.candidate, formats: [.physical], status: .tbr) }
                    }
                    .buttonStyle(BrickButtonStyle(fill: .olive))
                    .frame(maxWidth: 220)
                }
            } else {
                Text("this month's pick is coming soon").font(.serif(22)).foregroundStyle(Color.rose)
            }
        }
        .padding(.vertical, 12)
    }

    private var composer: some View {
        HStack(spacing: 10) {
            TextField("say something (no spoilers!)", text: $draft, axis: .vertical)
                .font(.display(15, weight: .semiBold))
                .lineLimit(1...4)
                .focused($typing)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 20).fill(Color.cream))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.brick, lineWidth: 1.2))
            Button {
                Task { await send() }
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color.cream)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(Color.olive))
            }
            .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || sending || model.club == nil)
            .accessibilityLabel("Send")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.cream.opacity(0.95))
    }

    private func load() async {
        do { messages = try await model.backend.clubMessages(month) } catch { /* keep what's on screen */ }
    }

    private func send() async {
        let text = draft
        sending = true
        defer { sending = false }
        do {
            try await model.backend.sendClubMessage(month, body: text)
            draft = ""
            await load()
        } catch {
            model.show(error)
        }
    }

    private func delete(_ message: ClubMessage) async {
        do {
            try await model.backend.deleteClubMessage(message.id)
            await load()
        } catch { model.show(error) }
    }
}

private struct Bubble: View {
    let message: ClubMessage
    let mine: Bool

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if mine {
                Spacer(minLength: 40)
            } else {
                NavigationLink(value: Route.reader(message.profile.username)) {
                    Avatar(url: message.profile.avatarURL, name: message.profile.name, size: 30)
                }
                .accessibilityLabel("\(message.profile.name)'s profile")
            }
            VStack(alignment: mine ? .trailing : .leading, spacing: 3) {
                if !mine {
                    Text(message.profile.name.lowercased()).font(.display(11, weight: .bold)).foregroundStyle(Color.rose)
                }
                Text(message.body)
                    .font(.display(15, weight: .semiBold))
                    .foregroundStyle(mine ? Color.cream : Color.brick)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(RoundedRectangle(cornerRadius: 18).fill(mine ? Color.brick : Color.cream))
                Text(Timestamp.relative(message.createdAt)).font(.caption2).foregroundStyle(.secondary)
            }
            if !mine { Spacer(minLength: 40) }
        }
    }
}

/// Report something to the admins (App Store guideline 1.2).
struct ReportSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let target: ReportTarget
    let id: UUID
    let what: String
    @State private var reason = ""

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                ScreenTitle(title: "report", subtitle: "tell us what's wrong with \(what)")
                TextField("reason (optional)", text: $reason, axis: .vertical)
                    .lineLimit(3...6)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
                Button("send report") {
                    Task {
                        if await model.perform("Thanks, we'll take a look.", { try await model.backend.report(target, id: id, reason: reason) }) {
                            dismiss()
                        }
                    }
                }
                .buttonStyle(BrickButtonStyle())
                Spacer()
            }
            .padding(20)
            .background(Color.cream.ignoresSafeArea())
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("cancel") { dismiss() } } }
        }
        .presentationDetents([.medium])
    }
}
