import SwiftUI

/// "friends": what the people you follow are reading, plus finding new readers.
struct FriendsView: View {
    @Environment(AppModel.self) private var model
    @State private var tab = 0
    @State private var feed: [Activity] = []
    @State private var requests: [FollowRequest] = []
    @State private var query = ""
    @State private var people: [Profile] = []
    @State private var loading = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                ScreenTitle(title: "friends", subtitle: "what your people are reading")
                Picker("", selection: $tab) {
                    Text("feed").tag(0)
                    Text("find readers").tag(1)
                    Text(requests.isEmpty ? "requests" : "requests (\(requests.count))").tag(2)
                }
                .pickerStyle(.segmented)

                switch tab {
                case 0: feedList
                case 1: findPeople
                default: requestList
                }
            }
            .padding(20)
        }
        .scrapbookScreen()
        .refreshable { await load() }
        .task { await load() }
    }

    private func load() async {
        do {
            async let f = model.backend.feed()
            async let r = model.backend.followRequests()
            feed = try await f
            requests = try await r
        } catch { model.show(error) }
        loading = false
    }

    @ViewBuilder private var feedList: some View {
        if loading {
            ProgressView().frame(maxWidth: .infinity).padding(40)
        } else if feed.isEmpty {
            Text("your feed is quiet. find some readers to follow!")
                .font(.serif(18)).foregroundStyle(Color.rose)
        }
        ForEach(feed) { item in
            FeedCard(item: item) { await load() }
        }
    }

    @ViewBuilder private var findPeople: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundStyle(Color.brick)
            TextField("search by name or username", text: $query)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .padding(12)
        .background(Capsule().fill(Color.cream))
        .overlay(Capsule().stroke(Color.brick, lineWidth: 1.2))
        .task(id: query) {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            people = (try? await model.backend.searchProfiles(query)) ?? []
        }
        ForEach(people) { person in
            NavigationLink(value: Route.reader(person.username)) {
                HStack(spacing: 12) {
                    Avatar(url: person.avatarURL, name: person.shortName, size: 44)
                    VStack(alignment: .leading) {
                        Text(person.shortName).font(.display(16)).foregroundStyle(Color.brick)
                        Text("@\(person.username)").font(.display(12, weight: .semiBold)).foregroundStyle(Color.rose)
                    }
                    Spacer()
                    if person.isPrivate { Image(systemName: "lock.fill").foregroundStyle(.secondary) }
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.cream))
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder private var requestList: some View {
        if requests.isEmpty {
            Text("no follow requests right now.").font(.serif(18)).foregroundStyle(Color.rose)
        }
        ForEach(requests) { request in
            HStack(spacing: 12) {
                Avatar(url: request.profile.avatarURL, name: request.profile.name, size: 40)
                Text(request.profile.name.lowercased()).font(.display(15)).foregroundStyle(Color.brick)
                Spacer()
                Button("accept") { answer(request, true) }.buttonStyle(.borderedProminent).tint(.olive)
                Button("decline") { answer(request, false) }.buttonStyle(.bordered).tint(.brick)
            }
            .font(.display(13, weight: .bold))
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.cream))
        }
    }

    private func answer(_ request: FollowRequest, _ accept: Bool) {
        Task {
            await model.perform(accept ? "Accepted" : nil) { try await model.backend.answerFollowRequest(from: request.followerID, accept: accept) }
            await load()
        }
    }
}

private struct FeedCard: View {
    @Environment(AppModel.self) private var model
    let item: Activity
    var reload: () async -> Void
    @State private var comment = ""
    @State private var reporting = false

    var body: some View {
        PaperCard(dashed: false) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    NavigationLink(value: Route.reader(item.profile.username)) {
                        Avatar(url: item.profile.avatarURL, name: item.profile.name, size: 36)
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text(headline).font(.display(14, weight: .bold)).foregroundStyle(Color.brick)
                        Text(Timestamp.relative(item.createdAt)).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    if item.userID != model.me?.id {
                        Menu {
                            Button("Report", systemImage: "flag") { reporting = true }
                        } label: {
                            Image(systemName: "ellipsis").foregroundStyle(Color.brick).padding(6)
                        }
                    }
                }
                if let book = item.book {
                    HStack(spacing: 12) {
                        BookCover(book).frame(width: 56, height: 84).rotationEffect(.degrees(-3))
                        VStack(alignment: .leading) {
                            Text(book.title).font(.serif(19)).foregroundStyle(Color.brick)
                            Text(book.authorLine.lowercased()).font(.display(12, weight: .semiBold)).foregroundStyle(Color.rose)
                        }
                    }
                }
                if let code = item.badgeCode, let badge = Badges.info(code) {
                    HStack(spacing: 12) {
                        BadgePatch(badge: badge).frame(width: 64, height: 64)
                        VStack(alignment: .leading) {
                            Text(badge.name).font(.serif(19)).foregroundStyle(Color.brick)
                            Text(badge.description.lowercased()).font(.display(12, weight: .semiBold)).foregroundStyle(Color.rose)
                        }
                    }
                }
                ForEach(item.comments) { c in
                    (Text(c.profile.name.lowercased() + "  ").font(.display(13, weight: .bold)) + Text(c.body).font(.system(size: 14)))
                        .foregroundStyle(Color.brick)
                }
                HStack {
                    TextField("add a comment", text: $comment).font(.system(size: 14))
                    if !comment.isEmpty {
                        Button("post") {
                            Task {
                                if await model.perform(haptic: nil, { try await model.backend.addComment(activityID: item.id, body: comment) }) {
                                    comment = ""
                                    await reload()
                                }
                            }
                        }
                        .font(.display(13, weight: .bold))
                    }
                }
                .padding(.top, 4)
            }
        }
        .sheet(isPresented: $reporting) { ReportSheet(target: .activity, id: item.id, what: "this post") }
    }

    private var headline: String {
        let name = item.profile.name.lowercased()
        return switch item.kind {
        case .started: "\(name) started reading"
        case .finished: "\(name) finished a book ✓"
        case .monthlyPick: "\(name)'s pick of the month"
        case .badge: "\(name) earned a badge"
        }
    }
}

/// Another reader's showcase: their library, top 8 and badges.
struct ReaderView: View {
    @Environment(AppModel.self) private var model
    let username: String
    @State private var profile: Profile?
    @State private var top: [Book?] = []
    @State private var earned: [EarnedBadge] = []
    @State private var follow: FollowInfo?
    @State private var reporting = false
    @State private var confirmBlock = false

    var body: some View {
        ScrollView {
            if let profile {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 14) {
                        Avatar(url: profile.avatarURL, name: profile.shortName, size: 72)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(profile.possessive) library").font(.display(28)).tracking(-0.4).foregroundStyle(Color.brick)
                            Text("@\(profile.username)").font(.display(13, weight: .semiBold)).foregroundStyle(Color.rose)
                        }
                    }
                    if !profile.bio.isEmpty { Text(profile.bio).font(.serif(18)).foregroundStyle(Color.brick) }
                    if let follow, profile.id != model.me?.id {
                        HStack {
                            Text("\(follow.followers) followers · \(follow.following) following").font(.display(12, weight: .semiBold)).foregroundStyle(.secondary)
                            Spacer()
                            followButton(follow, profile)
                        }
                    }
                    Pill(title: "top 8", fill: .marigold, text: .brick, size: 18).rotationEffect(.degrees(3))
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 14) {
                        ForEach(0..<8, id: \.self) { i in
                            if let book = top[safe: i] ?? nil {
                                BookCover(book).aspectRatio(2 / 3, contentMode: .fit)
                            } else {
                                RoundedRectangle(cornerRadius: 4).fill(Color.butter.opacity(0.5)).aspectRatio(2 / 3, contentMode: .fit)
                            }
                        }
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 22).fill(Color.cream))
                    Pill(title: "badges", fill: .blush, text: .brick, size: 18).rotationEffect(.degrees(-5))
                    let badges = Array(Set(earned.map(\.badgeCode))).compactMap(Badges.info).sorted { $0.name < $1.name }
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(badges) { b in BadgePatch(badge: b).frame(height: 72) }
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 22).fill(Color.cream))
                    if profile.isPrivate && follow?.state != .accepted && profile.id != model.me?.id {
                        Label("this journal is private. follow to see what they're reading.", systemImage: "lock.fill")
                            .font(.display(12, weight: .semiBold)).foregroundStyle(.secondary)
                    }
                }
                .padding(20)
            } else {
                ProgressView().padding(60)
            }
        }
        .scrapbookScreen()
        .toolbar {
            if let profile, profile.id != model.me?.id {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Report", systemImage: "flag") { reporting = true }
                        Button("Block", systemImage: "hand.raised", role: .destructive) { confirmBlock = true }
                    } label: { Image(systemName: "ellipsis.circle") }
                }
            }
        }
        .sheet(isPresented: $reporting) {
            if let profile { ReportSheet(target: .user, id: profile.id, what: "@\(profile.username)") }
        }
        .confirmationDialog("Block this reader?", isPresented: $confirmBlock, titleVisibility: .visible) {
            Button("Block", role: .destructive) {
                guard let id = profile?.id else { return }
                Task { await model.perform("Blocked") { try await model.backend.block(id) }; await load() }
            }
        } message: {
            Text("They won't see your journal and you won't see theirs.")
        }
        .task { await load() }
    }

    private func followButton(_ info: FollowInfo, _ profile: Profile) -> some View {
        let title = switch info.state {
        case .accepted: "following"
        case .pending: "requested"
        case .notFollowing: profile.isPrivate ? "request to follow" : "follow"
        }
        return Button(title) {
            Task {
                await model.perform(haptic: nil) {
                    if info.state == .notFollowing { try await model.backend.follow(profile.id) } else { try await model.backend.unfollow(profile.id) }
                }
                await load()
            }
        }
        .font(.display(13, weight: .bold))
        .buttonStyle(.borderedProminent)
        .tint(info.state == .notFollowing ? .brick : .olive)
    }

    private func load() async {
        do {
            guard let p = try await model.backend.profile(username: username) else { return }
            profile = p
            top = try await model.backend.topEight(userID: p.id)
            earned = try await model.backend.badges(userID: p.id)
            if p.id != model.me?.id { follow = try await model.backend.followInfo(userID: p.id) }
        } catch { model.show(error) }
    }
}
