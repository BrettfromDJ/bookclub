import Foundation

// Mirrors the tables in supabase/migrations. Column names are snake_case in
// Postgres, so each type maps them with CodingKeys.

enum BookFormat: String, Codable, CaseIterable, Identifiable, Hashable {
    case physical, audio, kindle
    var id: String { rawValue }
    var label: String {
        switch self {
        case .physical: "Physical"
        case .audio: "Audio"
        case .kindle: "Kindle"
        }
    }
    var symbol: String {
        switch self {
        case .physical: "book.closed"
        case .audio: "headphones"
        case .kindle: "ipad"
        }
    }
}

enum ShelfStatus: String, Codable, CaseIterable, Hashable {
    case tbr, reading, read
    var label: String {
        switch self {
        case .tbr: "To be read"
        case .reading: "Reading"
        case .read: "Finished"
        }
    }
}

enum BookSource: String, Codable, Hashable {
    case hardcover, google, openlibrary, manual
}

/// A search result that hasn't been saved to the books table yet.
struct BookCandidate: Codable, Hashable, Identifiable {
    var source: BookSource
    var externalID: String
    var title: String
    var authors: [String]
    var coverURL: String?
    var pageCount: Int?
    var publishedYear: Int?
    var categories: [String]
    var badgeCategory: String?

    var id: String { "\(source.rawValue):\(externalID)" }

    enum CodingKeys: String, CodingKey {
        case source, title, authors, categories
        case externalID = "external_id"
        case coverURL = "cover_url"
        case pageCount = "page_count"
        case publishedYear = "published_year"
        case badgeCategory = "badge_category"
    }
}

struct Book: Codable, Hashable, Identifiable {
    var id: UUID
    var source: BookSource
    var externalID: String
    var title: String
    var authors: [String]
    var coverURL: String?
    var pageCount: Int?
    var publishedYear: Int?
    var categories: [String]
    var badgeCategory: String?

    enum CodingKeys: String, CodingKey {
        case id, source, title, authors, categories
        case externalID = "external_id"
        case coverURL = "cover_url"
        case pageCount = "page_count"
        case publishedYear = "published_year"
        case badgeCategory = "badge_category"
    }

    var authorLine: String { authors.joined(separator: ", ") }

    var candidate: BookCandidate {
        BookCandidate(source: source, externalID: externalID, title: title, authors: authors, coverURL: coverURL,
                      pageCount: pageCount, publishedYear: publishedYear, categories: categories, badgeCategory: badgeCategory)
    }
}

extension BookCandidate {
    var authorLine: String { authors.joined(separator: ", ") }
}

/// A reader's relationship to a book: on the TBR, being read, or finished.
struct UserBook: Codable, Hashable, Identifiable {
    var id: UUID
    var userID: UUID
    var bookID: UUID
    var status: ShelfStatus
    var formats: [BookFormat]
    var position: Double
    /// `YYYY-MM-DD`
    var startedAt: String?
    /// `YYYY-MM-DD`
    var finishedAt: String?
    var rating: Int?
    var book: Book

    enum CodingKeys: String, CodingKey {
        case id, status, formats, position, rating, book
        case userID = "user_id"
        case bookID = "book_id"
        case startedAt = "started_at"
        case finishedAt = "finished_at"
    }
}

struct Profile: Codable, Hashable, Identifiable {
    var id: UUID
    var username: String
    var displayName: String
    var avatarURL: String?
    var bio: String
    var skin: String
    var songURL: String?
    var monthlyGoal: Int
    var isPrivate: Bool
    var isAdmin: Bool

    enum CodingKeys: String, CodingKey {
        case id, username, bio, skin
        case displayName = "display_name"
        case avatarURL = "avatar_url"
        case songURL = "song_url"
        case monthlyGoal = "monthly_goal"
        case isPrivate = "is_private"
        case isAdmin = "is_admin"
    }

    /// The name shown in titles: "daryn mae's library".
    var shortName: String {
        let name = displayName.trimmingCharacters(in: .whitespaces)
        return (name.isEmpty ? username : name).lowercased()
    }

    var possessive: String {
        shortName.hasSuffix("s") ? "\(shortName)’" : "\(shortName)’s"
    }
}

/// The public bits of a profile that ride along with feed items, comments and messages.
struct ProfileSummary: Codable, Hashable {
    var username: String
    var displayName: String
    var avatarURL: String?

    enum CodingKeys: String, CodingKey {
        case username
        case displayName = "display_name"
        case avatarURL = "avatar_url"
    }

    var name: String { displayName.isEmpty ? username : displayName }
}

struct EarnedBadge: Codable, Hashable {
    var badgeCode: String
    /// '' for one-time badges, 'YYYY-MM' for monthly ones.
    var period: String
    var earnedAt: String

    enum CodingKeys: String, CodingKey {
        case period
        case badgeCode = "badge_code"
        case earnedAt = "earned_at"
    }
}

enum ActivityKind: String, Codable {
    case started, finished
    case monthlyPick = "monthly_pick"
    case badge
}

struct Comment: Codable, Hashable, Identifiable {
    var id: UUID
    var userID: UUID
    var body: String
    var createdAt: String
    var profile: ProfileSummary

    enum CodingKeys: String, CodingKey {
        case id, body, profile
        case userID = "user_id"
        case createdAt = "created_at"
    }
}

struct Activity: Codable, Hashable, Identifiable {
    var id: UUID
    var userID: UUID
    var kind: ActivityKind
    var createdAt: String
    var book: Book?
    var badgeCode: String?
    var profile: ProfileSummary
    var comments: [Comment]

    enum CodingKeys: String, CodingKey {
        case id, kind, book, profile, comments
        case userID = "user_id"
        case createdAt = "created_at"
        case badgeCode = "badge_code"
    }
}

struct ClubMonth: Codable, Hashable {
    /// `YYYY-MM-01`
    var month: String
    var blurb: String
    var partnerName: String?
    var partnerURL: String?
    var partnerLogoURL: String?
    var book: Book

    enum CodingKeys: String, CodingKey {
        case month, blurb, book
        case partnerName = "partner_name"
        case partnerURL = "partner_url"
        case partnerLogoURL = "partner_logo_url"
    }
}

struct ClubMessage: Codable, Hashable, Identifiable {
    var id: UUID
    var month: String
    var userID: UUID
    var body: String
    var createdAt: String
    var profile: ProfileSummary

    enum CodingKeys: String, CodingKey {
        case id, month, body, profile
        case userID = "user_id"
        case createdAt = "created_at"
    }
}

struct FollowInfo: Hashable {
    enum State: String { case notFollowing = "none", pending, accepted }
    var state: State
    var followers: Int
    var following: Int
}

struct FollowRequest: Codable, Hashable, Identifiable {
    var followerID: UUID
    var profile: ProfileSummary
    var id: UUID { followerID }

    enum CodingKeys: String, CodingKey {
        case profile
        case followerID = "follower_id"
    }
}

/// Fields a reader can change on their own profile.
struct ProfilePatch: Encodable {
    var username: String?
    var displayName: String?
    var bio: String?
    var monthlyGoal: Int?
    var isPrivate: Bool?
    var avatarURL: String?

    enum CodingKeys: String, CodingKey {
        case username, bio
        case displayName = "display_name"
        case monthlyGoal = "monthly_goal"
        case isPrivate = "is_private"
        case avatarURL = "avatar_url"
    }

    // Only send the fields that were set.
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(username, forKey: .username)
        try c.encodeIfPresent(displayName, forKey: .displayName)
        try c.encodeIfPresent(bio, forKey: .bio)
        try c.encodeIfPresent(monthlyGoal, forKey: .monthlyGoal)
        try c.encodeIfPresent(isPrivate, forKey: .isPrivate)
        try c.encodeIfPresent(avatarURL, forKey: .avatarURL)
    }
}

enum ReportTarget: String {
    case user, comment, activity, message
}
