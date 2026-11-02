import Foundation
import Supabase

/// The real backend: the same Supabase project and schema as the web app.
/// Row-level security in the database decides what each reader can see.
@MainActor
final class SupabaseBackend: Backend {
    let isDemo = false
    private let client: SupabaseClient

    init(url: URL, anonKey: String) {
        client = SupabaseClient(supabaseURL: url, supabaseKey: anonKey)
    }

    private static let bookJoin = "book:books(*)"
    private static let profileJoin = "profile:profiles(username, display_name, avatar_url)"

    private func uid() throws -> UUID {
        guard let id = client.auth.currentUser?.id else { throw BackendError.message("You're signed out.") }
        return id
    }

    // MARK: Auth

    func restoreSession() async -> UUID? {
        (try? await client.auth.session)?.user.id
    }

    func sendCode(email: String) async throws {
        try await client.auth.signInWithOTP(email: email, shouldCreateUser: true)
    }

    func verify(email: String, code: String) async throws -> UUID {
        let response = try await client.auth.verifyOTP(email: email, token: code, type: .email)
        guard let id = response.session?.user.id ?? client.auth.currentUser?.id else {
            throw BackendError.message("That code didn't work. Try again.")
        }
        return id
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }

    /// Required by App Store guideline 5.1.1(v). The `delete_my_account` function
    /// in the database removes the auth user, which cascades to everything they own.
    func deleteAccount() async throws {
        let id = try uid()
        _ = try? await client.storage.from("avatars").remove(paths: ["\(id.uuidString.lowercased())/avatar.jpg"])
        try await client.rpc("delete_my_account").execute()
        try? await client.auth.signOut()
    }

    // MARK: Profiles

    func profile(id: UUID) async throws -> Profile {
        try await client.from("profiles").select().eq("id", value: id.uuidString).single().execute().value
    }

    func profile(username: String) async throws -> Profile? {
        let rows: [Profile] = try await client.from("profiles").select().eq("username", value: username).limit(1).execute().value
        return rows.first
    }

    func searchProfiles(_ query: String) async throws -> [Profile] {
        // Strip characters that have meaning in PostgREST filter strings.
        let q = query.filter { $0.isLetter || $0.isNumber || $0 == "_" || $0 == " " }.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return [] }
        return try await client.from("profiles")
            .select()
            .or("username.ilike.*\(q)*,display_name.ilike.*\(q)*")
            .limit(25)
            .execute().value
    }

    func updateProfile(_ patch: ProfilePatch) async throws {
        do {
            try await client.from("profiles").update(patch).eq("id", value: try uid().uuidString).execute()
        } catch let error as PostgrestError where error.code == "23505" {
            throw BackendError.message("That username is taken.")
        }
    }

    func uploadAvatar(_ jpeg: Data) async throws -> String {
        let path = "\(try uid().uuidString.lowercased())/avatar.jpg"
        let bucket = client.storage.from("avatars")
        _ = try await bucket.upload(path, data: jpeg, options: FileOptions(contentType: "image/jpeg", upsert: true))
        // Bust caches so the new photo shows right away.
        let url = try bucket.getPublicURL(path: path)
        return url.absoluteString + "?v=\(Int(Date.now.timeIntervalSince1970))"
    }

    // MARK: Shelves

    func shelf(userID: UUID) async throws -> [UserBook] {
        try await client.from("user_books")
            .select("*, \(Self.bookJoin)")
            .eq("user_id", value: userID.uuidString)
            .order("position")
            .execute().value
    }

    private struct BookID: Decodable { var id: UUID }

    /// Saves a search result to the shared books table, or finds the existing row.
    private func ensureBook(_ b: BookCandidate) async throws -> UUID {
        try await client.from("books").upsert(b, onConflict: "source,external_id", ignoreDuplicates: true).execute()
        let row: BookID = try await client.from("books")
            .select("id")
            .eq("source", value: b.source.rawValue)
            .eq("external_id", value: b.externalID)
            .single()
            .execute().value
        return row.id
    }

    private struct NewUserBook: Encodable {
        var user_id: UUID
        var book_id: UUID
        var status: ShelfStatus
        var formats: [BookFormat]
        var position: Double
        var started_at: String?
        var finished_at: String?
    }

    private struct Position: Decodable { var position: Double }

    func addToShelf(_ book: BookCandidate, formats: [BookFormat], status: ShelfStatus) async throws {
        let me = try uid()
        let bookID = try await ensureBook(book)
        // New TBR books go to the top.
        let first: [Position] = try await client.from("user_books")
            .select("position")
            .eq("user_id", value: me.uuidString)
            .eq("status", value: "tbr")
            .order("position")
            .limit(1)
            .execute().value
        let row = NewUserBook(
            user_id: me, book_id: bookID, status: status, formats: formats,
            position: (first.first?.position ?? 1) - 1,
            started_at: status == .reading ? Month.today() : nil,
            finished_at: status == .read ? Month.today() : nil
        )
        do {
            try await client.from("user_books").insert(row).execute()
        } catch let error as PostgrestError where error.code == "23505" {
            throw BackendError.message("That book is already on your shelves.")
        }
    }

    private struct StatusPatch: Encodable {
        var status: ShelfStatus
        var started_at: String?
        var finished_at: String?
        func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode(status, forKey: .status)
            // finished_at must be written as null when leaving "read".
            try c.encode(finished_at, forKey: .finished_at)
            if let started_at { try c.encode(started_at, forKey: .started_at) }
        }
        enum CodingKeys: String, CodingKey { case status, started_at, finished_at }
    }

    func setStatus(_ userBookID: UUID, _ status: ShelfStatus) async throws {
        let patch: StatusPatch = switch status {
        case .read: StatusPatch(status: .read, started_at: nil, finished_at: Month.today())
        case .reading: StatusPatch(status: .reading, started_at: Month.today(), finished_at: nil)
        case .tbr: StatusPatch(status: .tbr, started_at: nil, finished_at: nil)
        }
        try await client.from("user_books").update(patch).eq("id", value: userBookID.uuidString).execute()
    }

    func setFormats(_ userBookID: UUID, _ formats: [BookFormat]) async throws {
        guard !formats.isEmpty else { throw BackendError.message("Pick at least one format.") }
        try await client.from("user_books").update(["formats": formats]).eq("id", value: userBookID.uuidString).execute()
    }

    func setPosition(_ userBookID: UUID, _ position: Double) async throws {
        try await client.from("user_books").update(["position": position]).eq("id", value: userBookID.uuidString).execute()
    }

    private struct RatingPatch: Encodable {
        var rating: Int?
        func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode(rating, forKey: .rating)
        }
        enum CodingKeys: String, CodingKey { case rating }
    }

    func setRating(_ userBookID: UUID, _ rating: Int?) async throws {
        try await client.from("user_books").update(RatingPatch(rating: rating)).eq("id", value: userBookID.uuidString).execute()
    }

    func removeFromShelf(_ userBookID: UUID) async throws {
        try await client.from("user_books").delete().eq("id", value: userBookID.uuidString).execute()
    }

    // MARK: Showcase

    private struct TopRow: Decodable { var slot: Int; var book: Book }

    func topEight(userID: UUID) async throws -> [Book?] {
        let rows: [TopRow] = try await client.from("top_books")
            .select("slot, \(Self.bookJoin)")
            .eq("user_id", value: userID.uuidString)
            .execute().value
        var slots = [Book?](repeating: nil, count: 8)
        for row in rows where (1...8).contains(row.slot) { slots[row.slot - 1] = row.book }
        return slots
    }

    private struct TopBookRow: Encodable { var user_id: UUID; var slot: Int; var book_id: UUID }

    func setTopBook(slot: Int, book: BookCandidate?) async throws {
        let me = try uid()
        guard let book else {
            try await client.from("top_books").delete().eq("user_id", value: me.uuidString).eq("slot", value: String(slot)).execute()
            return
        }
        let bookID = try await ensureBook(book)
        try await client.from("top_books").upsert(TopBookRow(user_id: me, slot: slot, book_id: bookID)).execute()
    }

    func setTopEight(_ books: [Book?]) async throws {
        let me = try uid()
        let rows = books.prefix(8).enumerated().compactMap { i, book in
            book.map { TopBookRow(user_id: me, slot: i + 1, book_id: $0.id) }
        }
        try await client.from("top_books").delete().eq("user_id", value: me.uuidString).execute()
        if !rows.isEmpty { try await client.from("top_books").insert(rows).execute() }
    }

    func badges(userID: UUID) async throws -> [EarnedBadge] {
        try await client.from("user_badges")
            .select("badge_code, period, earned_at")
            .eq("user_id", value: userID.uuidString)
            .order("earned_at")
            .execute().value
    }

    // MARK: Book club

    func clubMonth(_ month: String) async throws -> ClubMonth? {
        let rows: [ClubMonth] = try await client.from("club_months")
            .select("*, \(Self.bookJoin)")
            .eq("month", value: month)
            .limit(1)
            .execute().value
        return rows.first
    }

    func clubMessages(_ month: String) async throws -> [ClubMessage] {
        let rows: [ClubMessage] = try await client.from("club_messages")
            .select("*, \(Self.profileJoin)")
            .eq("month", value: month)
            .order("created_at", ascending: false)
            .limit(200)
            .execute().value
        return rows.reversed()
    }

    private struct NewMessage: Encodable { var month: String; var user_id: UUID; var body: String }

    func sendClubMessage(_ month: String, body: String) async throws {
        let text = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        try await client.from("club_messages").insert(NewMessage(month: month, user_id: try uid(), body: String(text.prefix(1000)))).execute()
    }

    func deleteClubMessage(_ id: UUID) async throws {
        try await client.from("club_messages").delete().eq("id", value: id.uuidString).execute()
    }

    // MARK: Social

    private struct Followee: Decodable { var followee_id: UUID }

    /// Activity from people the reader follows, plus their own.
    func feed() async throws -> [Activity] {
        let me = try uid()
        let follows: [Followee] = try await client.from("follows")
            .select("followee_id")
            .eq("follower_id", value: me.uuidString)
            .eq("status", value: "accepted")
            .execute().value
        let ids = [me.uuidString] + follows.map(\.followee_id.uuidString)
        var items: [Activity] = try await client.from("activities")
            .select("*, \(Self.bookJoin), \(Self.profileJoin), comments(*, \(Self.profileJoin))")
            .in("user_id", values: ids)
            .order("created_at", ascending: false)
            .limit(50)
            .execute().value
        for i in items.indices { items[i].comments.sort { $0.createdAt < $1.createdAt } }
        return items
    }

    private struct NewComment: Encodable { var activity_id: UUID; var user_id: UUID; var body: String }

    func addComment(activityID: UUID, body: String) async throws {
        let text = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { throw BackendError.message("Write something first.") }
        try await client.from("comments").insert(NewComment(activity_id: activityID, user_id: try uid(), body: String(text.prefix(1000)))).execute()
    }

    private struct FollowStatus: Decodable { var status: String }

    func followInfo(userID: UUID) async throws -> FollowInfo {
        let me = try uid()
        let mine: [FollowStatus] = try await client.from("follows")
            .select("status")
            .eq("follower_id", value: me.uuidString)
            .eq("followee_id", value: userID.uuidString)
            .limit(1)
            .execute().value
        let followers = try await client.from("follows")
            .select("*", head: true, count: .exact)
            .eq("followee_id", value: userID.uuidString)
            .eq("status", value: "accepted")
            .execute().count ?? 0
        let following = try await client.from("follows")
            .select("*", head: true, count: .exact)
            .eq("follower_id", value: userID.uuidString)
            .eq("status", value: "accepted")
            .execute().count ?? 0
        return FollowInfo(state: FollowInfo.State(rawValue: mine.first?.status ?? "none") ?? .notFollowing, followers: followers, following: following)
    }

    private struct NewFollow: Encodable { var follower_id: UUID; var followee_id: UUID }

    func follow(_ userID: UUID) async throws {
        // The database turns this into a request if the account is private.
        try await client.from("follows").insert(NewFollow(follower_id: try uid(), followee_id: userID)).execute()
    }

    func unfollow(_ userID: UUID) async throws {
        try await client.from("follows").delete()
            .eq("follower_id", value: try uid().uuidString)
            .eq("followee_id", value: userID.uuidString)
            .execute()
    }

    func followRequests() async throws -> [FollowRequest] {
        try await client.from("follows")
            .select("follower_id, profile:profiles!follows_follower_id_fkey(username, display_name, avatar_url)")
            .eq("followee_id", value: try uid().uuidString)
            .eq("status", value: "pending")
            .execute().value
    }

    func answerFollowRequest(from followerID: UUID, accept: Bool) async throws {
        let me = try uid().uuidString
        if accept {
            try await client.from("follows").update(["status": "accepted"])
                .eq("follower_id", value: followerID.uuidString).eq("followee_id", value: me).execute()
        } else {
            try await client.from("follows").delete()
                .eq("follower_id", value: followerID.uuidString).eq("followee_id", value: me).execute()
        }
    }

    private struct NewReport: Encodable { var reporter_id: UUID; var target_kind: String; var target_id: UUID; var reason: String }

    func report(_ target: ReportTarget, id: UUID, reason: String) async throws {
        try await client.from("reports")
            .insert(NewReport(reporter_id: try uid(), target_kind: target.rawValue, target_id: id, reason: String(reason.prefix(500))))
            .execute()
    }

    private struct NewBlock: Encodable { var blocker_id: UUID; var blocked_id: UUID }

    func block(_ userID: UUID) async throws {
        let me = try uid()
        try await client.from("blocks").insert(NewBlock(blocker_id: me, blocked_id: userID)).execute()
        // Blocking also removes any follow in either direction.
        let a = me.uuidString, b = userID.uuidString
        try await client.from("follows").delete()
            .or("and(follower_id.eq.\(a),followee_id.eq.\(b)),and(follower_id.eq.\(b),followee_id.eq.\(a))")
            .execute()
    }
}
