import Foundation

/// Sample data kept in memory, used when no Supabase keys are configured.
/// Everything works (adding books, punching the card, chatting) but resets on relaunch.
@MainActor
final class DemoBackend: Backend {
    let isDemo = true

    private let me = UUID()
    private var profiles: [Profile]
    private var books: [Book] = []
    private var shelfRows: [UserBook] = []
    private var top: [Int: Book] = [:]
    private var earned: [EarnedBadge] = []
    private var club: ClubMonth?
    private var messages: [ClubMessage] = []
    private var activities: [Activity] = []
    private var following: Set<UUID> = []

    init() {
        profiles = [
            Profile(id: me, username: "daryn_mae", displayName: "Daryn Mae", avatarURL: nil,
                    bio: "always with a book in my bag", skin: "library", songURL: nil,
                    monthlyGoal: 4, isPrivate: false, isAdmin: true),
        ]
        seed()
    }

    // MARK: Seed

    private static func book(_ title: String, _ author: String, isbn: String?, pages: Int, genre: String?) -> Book {
        Book(id: UUID(), source: .manual, externalID: isbn ?? UUID().uuidString, title: title, authors: [author],
             coverURL: isbn.map { "https://covers.openlibrary.org/b/isbn/\($0)-L.jpg?default=false" },
             pageCount: pages, publishedYear: nil, categories: [], badgeCategory: genre)
    }

    private func seed() {
        let summer = Self.book("Just for the Summer", "Abby Jimenez", isbn: "9781538704431", pages: 400, genre: "romance")
        let heartless = Self.book("Heartless", "Elsie Silver", isbn: "9781728290829", pages: 384, genre: "romance")
        let flawless = Self.book("Flawless", "Elsie Silver", isbn: "9781728290799", pages: 384, genre: "romance")
        let powerless = Self.book("Powerless", "Elsie Silver", isbn: "9781728290850", pages: 384, genre: "romance")
        let reckless = Self.book("Reckless", "Elsie Silver", isbn: "9781728290881", pages: 384, genre: "romance")
        let hopeless = Self.book("Hopeless", "Elsie Silver", isbn: "9781728290911", pages: 160, genre: "romance")
        let kissCam = Self.book("The One with the Kiss Cam", "Cindy Steel", isbn: nil, pages: 320, genre: "romance")
        let funny = Self.book("Funny Story", "Emily Henry", isbn: "9780593441282", pages: 400, genre: "romance")
        let fourth = Self.book("Fourth Wing", "Rebecca Yarros", isbn: "9781649374042", pages: 512, genre: "fantasy")
        let acotar = Self.book("A Court of Thorns and Roses", "Sarah J. Maas", isbn: "9781635575569", pages: 448, genre: "fantasy")
        let tomorrow = Self.book("Tomorrow, and Tomorrow, and Tomorrow", "Gabrielle Zevin", isbn: "9780593321201", pages: 416, genre: "literary")
        let evelyn = Self.book("The Seven Husbands of Evelyn Hugo", "Taylor Jenkins Reid", isbn: "9781501161933", pages: 400, genre: "historical")
        let bookLovers = Self.book("Book Lovers", "Emily Henry", isbn: "9780593334836", pages: 384, genre: "romance")
        let happy = Self.book("Happy Place", "Emily Henry", isbn: "9780593441275", pages: 400, genre: "romance")
        let yellowface = Self.book("Yellowface", "R. F. Kuang", isbn: "9780063250833", pages: 336, genre: "literary")
        books = [summer, heartless, flawless, powerless, reckless, hopeless, kissCam, funny, fourth, acotar, tomorrow, evelyn, bookLovers, happy, yellowface]

        let thisMonth = Month.start().prefix(8) // "YYYY-MM-"
        func row(_ b: Book, _ status: ShelfStatus, _ pos: Double, finished: String? = nil, formats: [BookFormat] = [.physical]) -> UserBook {
            UserBook(id: UUID(), userID: me, bookID: b.id, status: status, formats: formats, position: pos,
                     startedAt: nil, finishedAt: finished, rating: status == .read ? 5 : nil, book: b)
        }
        shelfRows = [
            row(summer, .reading, 0, formats: [.kindle]),
            row(flawless, .tbr, 1),
            row(reckless, .tbr, 2, formats: [.audio]),
            row(heartless, .tbr, 3),
            row(powerless, .tbr, 4, formats: [.kindle]),
            row(hopeless, .tbr, 5),
            row(happy, .tbr, 6, formats: [.audio, .physical]),
            row(funny, .read, 0, finished: "\(thisMonth)02"),
            row(bookLovers, .read, 0, finished: "\(thisMonth)05", formats: [.audio]),
            row(fourth, .read, 0, finished: "\(thisMonth)09"),
            row(acotar, .read, 0, finished: "2026-10-12"),
            row(tomorrow, .read, 0, finished: "2026-10-03"),
            row(evelyn, .read, 0, finished: "2026-09-21"),
        ]
        top = [1: heartless, 2: funny, 3: fourth, 4: acotar, 5: evelyn, 6: bookLovers, 7: tomorrow, 8: yellowface]
        let now = ISO8601DateFormatter().string(from: .now)
        earned = ["milestone:1", "genre:romance", "genre:fantasy", "genre:literary", "genre:historical"].map {
            EarnedBadge(badgeCode: $0, period: "", earnedAt: now)
        }

        club = ClubMonth(month: Month.start(), blurb: "A hockey-arena meet-cute gone viral. Grab a copy and come chat!",
                         partnerName: nil, partnerURL: nil, partnerLogoURL: nil, book: kissCam)

        let jordan = Profile(id: UUID(), username: "jordanrhea", displayName: "Jordan Rhea", avatarURL: nil, bio: "romantasy girlie",
                             skin: "library", songURL: nil, monthlyGoal: 5, isPrivate: false, isAdmin: false)
        let cami = Profile(id: UUID(), username: "cami_reads", displayName: "Cami", avatarURL: nil, bio: "sempre com um livro na bolsa",
                           skin: "library", songURL: nil, monthlyGoal: 3, isPrivate: true, isAdmin: false)
        profiles += [jordan, cami]
        following = [jordan.id]

        let ago = { (h: Double) in ISO8601DateFormatter().string(from: Date.now.addingTimeInterval(-h * 3600)) }
        messages = [
            ClubMessage(id: UUID(), month: Month.start(), userID: jordan.id, body: "ok the kiss cam scene in chapter 1?? i'm already obsessed", createdAt: ago(20), profile: summary(jordan)),
            ClubMessage(id: UUID(), month: Month.start(), userID: cami.id, body: "no spoilers past ch 10 pls 🙈", createdAt: ago(6), profile: summary(cami)),
        ]
        activities = [
            Activity(id: UUID(), userID: jordan.id, kind: .finished, createdAt: ago(3), book: heartless, badgeCode: nil, profile: summary(jordan),
                     comments: [Comment(id: UUID(), userID: me, body: "WAIT what did you think of the ending", createdAt: ago(2), profile: summary(profiles[0]))]),
            Activity(id: UUID(), userID: me, kind: .started, createdAt: ago(26), book: summer, badgeCode: nil, profile: summary(profiles[0]), comments: []),
            Activity(id: UUID(), userID: jordan.id, kind: .badge, createdAt: ago(50), book: nil, badgeCode: "genre:fantasy", profile: summary(jordan), comments: []),
        ]
    }

    private func summary(_ p: Profile) -> ProfileSummary {
        ProfileSummary(username: p.username, displayName: p.displayName, avatarURL: p.avatarURL)
    }

    private var myProfile: Profile { profiles.first { $0.id == me }! }

    // MARK: Auth

    func restoreSession() async -> UUID? { me }
    func sendCode(email: String) async throws {}
    func verify(email: String, code: String) async throws -> UUID { me }
    func signOut() async throws { throw BackendError.message("Demo mode: there's no account to sign out of. Add your Supabase keys to use real accounts.") }
    func deleteAccount() async throws { throw BackendError.message("Demo mode: nothing to delete.") }

    // MARK: Profiles

    func profile(id: UUID) async throws -> Profile {
        guard let p = profiles.first(where: { $0.id == id }) else { throw BackendError.message("Reader not found.") }
        return p
    }

    func profile(username: String) async throws -> Profile? { profiles.first { $0.username == username } }

    func searchProfiles(_ query: String) async throws -> [Profile] {
        let q = query.lowercased()
        return profiles.filter { $0.id != me && ($0.username.contains(q) || $0.displayName.lowercased().contains(q)) }
    }

    func updateProfile(_ patch: ProfilePatch) async throws {
        guard let i = profiles.firstIndex(where: { $0.id == me }) else { return }
        if let v = patch.username { profiles[i].username = v }
        if let v = patch.displayName { profiles[i].displayName = v }
        if let v = patch.bio { profiles[i].bio = v }
        if let v = patch.monthlyGoal { profiles[i].monthlyGoal = v }
        if let v = patch.isPrivate { profiles[i].isPrivate = v }
        if let v = patch.avatarURL { profiles[i].avatarURL = v }
    }

    func uploadAvatar(_ jpeg: Data) async throws -> String {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("avatar-\(UUID().uuidString).jpg")
        try jpeg.write(to: url)
        return url.absoluteString
    }

    // MARK: Shelves

    func shelf(userID: UUID) async throws -> [UserBook] {
        return userID == me ? shelfRows.sorted { $0.position < $1.position } : []
    }

    func addToShelf(_ c: BookCandidate, formats: [BookFormat], status: ShelfStatus) async throws {
        if shelfRows.contains(where: { $0.book.source == c.source && $0.book.externalID == c.externalID }) {
            throw BackendError.message("That book is already on your shelves.")
        }
        let book = Book(id: UUID(), source: c.source, externalID: c.externalID, title: c.title, authors: c.authors, coverURL: c.coverURL,
                        pageCount: c.pageCount, publishedYear: c.publishedYear, categories: c.categories, badgeCategory: c.badgeCategory)
        let top = shelfRows.filter { $0.status == .tbr }.map(\.position).min() ?? 1
        shelfRows.append(UserBook(id: UUID(), userID: me, bookID: book.id, status: status, formats: formats, position: top - 1,
                                  startedAt: status == .reading ? Month.today() : nil,
                                  finishedAt: status == .read ? Month.today() : nil, rating: nil, book: book))
        if status == .read { award(book) }
    }

    func setStatus(_ id: UUID, _ status: ShelfStatus) async throws {
        guard let i = shelfRows.firstIndex(where: { $0.id == id }) else { return }
        let was = shelfRows[i].status
        shelfRows[i].status = status
        shelfRows[i].finishedAt = status == .read ? Month.today() : nil
        if status == .reading { shelfRows[i].startedAt = Month.today() }
        if status == .read && was != .read { award(shelfRows[i].book) }
    }

    /// Mirrors award_for_finished() in the database.
    private func award(_ book: Book) {
        func give(_ code: String, period: String = "") {
            guard !earned.contains(where: { $0.badgeCode == code && $0.period == period }) else { return }
            earned.append(EarnedBadge(badgeCode: code, period: period, earnedAt: ISO8601DateFormatter().string(from: .now)))
        }
        if let g = book.badgeCategory { give("genre:\(g)") }
        let total = shelfRows.filter { $0.status == .read }.count
        for m in [1, 10, 25, 50, 100] where total >= m { give("milestone:\(m)") }
        let inMonth = shelfRows.filter { $0.status == .read && Month.contains($0.finishedAt) }.count
        if inMonth >= myProfile.monthlyGoal { give("goal:monthly", period: String(Month.start().prefix(7))) }
        if club?.book.id == book.id { give("club:finisher", period: String(Month.start().prefix(7))) }
    }

    func setFormats(_ id: UUID, _ formats: [BookFormat]) async throws {
        guard !formats.isEmpty else { throw BackendError.message("Pick at least one format.") }
        if let i = shelfRows.firstIndex(where: { $0.id == id }) { shelfRows[i].formats = formats }
    }

    func setPosition(_ id: UUID, _ position: Double) async throws {
        if let i = shelfRows.firstIndex(where: { $0.id == id }) { shelfRows[i].position = position }
    }

    func setRating(_ id: UUID, _ rating: Int?) async throws {
        if let i = shelfRows.firstIndex(where: { $0.id == id }) { shelfRows[i].rating = rating }
    }

    func removeFromShelf(_ id: UUID) async throws {
        shelfRows.removeAll { $0.id == id }
    }

    // MARK: Showcase

    func topEight(userID: UUID) async throws -> [Book?] {
        guard userID == me else { return Array(repeating: nil, count: 8) }
        return (1...8).map { top[$0] }
    }

    func setTopBook(slot: Int, book c: BookCandidate?) async throws {
        guard let c else { top[slot] = nil; return }
        top[slot] = books.first { $0.externalID == c.externalID }
            ?? Book(id: UUID(), source: c.source, externalID: c.externalID, title: c.title, authors: c.authors, coverURL: c.coverURL,
                    pageCount: c.pageCount, publishedYear: c.publishedYear, categories: c.categories, badgeCategory: c.badgeCategory)
    }

    func setTopEight(_ books: [Book?]) async throws {
        top = [:]
        for (i, book) in books.prefix(8).enumerated() { if let book { top[i + 1] = book } }
    }

    func badges(userID: UUID) async throws -> [EarnedBadge] { userID == me ? earned : [] }

    // MARK: Book club

    func clubMonth(_ month: String) async throws -> ClubMonth? { club?.month == month ? club : nil }

    func setClubMonth(_ month: String, book c: BookCandidate, blurb: String) async throws {
        let book = books.first { $0.externalID == c.externalID }
            ?? Book(id: UUID(), source: c.source, externalID: c.externalID, title: c.title, authors: c.authors, coverURL: c.coverURL,
                    pageCount: c.pageCount, publishedYear: c.publishedYear, categories: c.categories, badgeCategory: c.badgeCategory)
        club = ClubMonth(month: month, blurb: blurb, partnerName: nil, partnerURL: nil, partnerLogoURL: nil, book: book)
    }
    func clubMessages(_ month: String) async throws -> [ClubMessage] { messages.filter { $0.month == month } }

    func sendClubMessage(_ month: String, body: String) async throws {
        let text = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        messages.append(ClubMessage(id: UUID(), month: month, userID: me, body: text, createdAt: ISO8601DateFormatter().string(from: .now), profile: summary(myProfile)))
    }

    func deleteClubMessage(_ id: UUID) async throws { messages.removeAll { $0.id == id && $0.userID == me } }

    // MARK: Social

    func feed() async throws -> [Activity] { activities.filter { $0.userID == me || following.contains($0.userID) } }

    func addComment(activityID: UUID, body: String) async throws {
        guard let i = activities.firstIndex(where: { $0.id == activityID }) else { return }
        activities[i].comments.append(Comment(id: UUID(), userID: me, body: body, createdAt: ISO8601DateFormatter().string(from: .now), profile: summary(myProfile)))
    }

    func followInfo(userID: UUID) async throws -> FollowInfo {
        FollowInfo(state: following.contains(userID) ? .accepted : .notFollowing, followers: 12, following: 9)
    }

    func follow(_ userID: UUID) async throws { following.insert(userID) }
    func unfollow(_ userID: UUID) async throws { following.remove(userID) }
    func followRequests() async throws -> [FollowRequest] { [] }
    func answerFollowRequest(from followerID: UUID, accept: Bool) async throws {}
    func report(_ target: ReportTarget, id: UUID, reason: String) async throws {}
    func block(_ userID: UUID) async throws { following.remove(userID) }
}
