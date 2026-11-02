import SwiftUI

// Pure logic shared by the screens. Ported from the web app's src/lib.

// MARK: - Punch card

/// Coffee-shop card: every finished book punches a hole, ten holes fill a card.
/// A full card stays on screen (all punched) until the next book starts a fresh one.
struct PunchCard: Equatable {
    static let holesPerCard = 10

    let cardNumber: Int
    let punched: Int
    let completedCards: Int
    let toNextCard: Int

    init(totalRead: Int) {
        let total = max(0, totalRead)
        let completed = total / Self.holesPerCard
        let remainder = total % Self.holesPerCard
        let showingFull = total > 0 && remainder == 0
        cardNumber = showingFull ? completed : completed + 1
        punched = showingFull ? Self.holesPerCard : remainder
        completedCards = completed
        toNextCard = showingFull ? Self.holesPerCard : Self.holesPerCard - remainder
    }
}

// MARK: - TBR ranking

/// Fractional ranking: a moved book gets a position between its new neighbours,
/// so only that one row is written.
enum Ranking {
    static func between(_ before: Double?, _ after: Double?) -> Double {
        switch (before, after) {
        case (nil, nil): 0
        case (nil, let a?): a - 1
        case (let b?, nil): b + 1
        case (let b?, let a?): (b + a) / 2
        }
    }
}

// MARK: - Months

enum Month {
    private static let calendar = Calendar(identifier: .gregorian)

    /// First day of the month as `YYYY-MM-01`, in local time.
    static func start(_ date: Date = .now) -> String {
        let c = calendar.dateComponents([.year, .month], from: date)
        return String(format: "%04ld-%02ld-01", c.year ?? 2000, c.month ?? 1)
    }

    /// Local date as `YYYY-MM-DD`.
    static func today(_ date: Date = .now) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04ld-%02ld-%02ld", c.year ?? 2000, c.month ?? 1, c.day ?? 1)
    }

    /// "november"
    static func name(_ date: Date = .now) -> String {
        date.formatted(.dateTime.month(.wide)).lowercased()
    }

    /// Whether a `YYYY-MM-DD` date falls in the month of `date`.
    static func contains(_ day: String?, month date: Date = .now) -> Bool {
        guard let day else { return false }
        return day.hasPrefix(String(start(date).prefix(7)))
    }
}

enum Timestamp {
    private static let withFraction: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    private static let plain = ISO8601DateFormatter()

    static func date(_ string: String) -> Date? {
        withFraction.date(from: string) ?? plain.date(from: string)
    }

    /// "2h", "3d", "just now"
    static func relative(_ string: String) -> String {
        guard let d = date(string) else { return "" }
        let s = Int(Date.now.timeIntervalSince(d))
        switch s {
        case ..<60: return "just now"
        case ..<3600: return "\(s / 60)m"
        case ..<86_400: return "\(s / 3600)h"
        case ..<604_800: return "\(s / 86_400)d"
        default: return d.formatted(.dateTime.month(.abbreviated).day())
        }
    }
}

// MARK: - Genres and badges

enum Genre {
    /// Earlier rules win, which is why the narrow categories come first.
    static let rules: [(code: String, words: [String])] = [
        ("graphic", ["comic", "graphic novel", "manga"]),
        ("ya", ["young adult", "juvenile fiction", "teen"]),
        ("poetry", ["poetry", "poems"]),
        ("biography", ["biography", "autobiography", "memoir"]),
        ("selfhelp", ["self-help", "self help", "personal growth", "motivation"]),
        ("scifi", ["science fiction", "sci-fi", "dystopia", "space opera", "cyberpunk"]),
        ("fantasy", ["fantasy", "dragons", "magic", "fairy tales"]),
        ("horror", ["horror", "ghost", "supernatural", "vampire"]),
        ("thriller", ["thriller", "suspense", "espionage"]),
        ("mystery", ["mystery", "detective", "crime"]),
        ("romance", ["romance", "love stories"]),
        ("historical", ["historical"]),
        ("classics", ["classics", "classic literature"]),
        ("literary", ["literary", "fiction"]),
        ("nonfiction", ["history", "science", "business", "psychology", "philosophy", "politics", "nonfiction",
                        "non-fiction", "true crime", "essays", "cooking", "travel"]),
    ]

    static func category(for subjects: [String]) -> String? {
        let text = subjects.joined(separator: " | ").lowercased()
        return rules.first { rule in rule.words.contains { text.contains($0) } }?.code
    }
}

struct BadgeInfo: Identifiable, Hashable {
    let code: String
    let name: String
    let description: String
    let symbol: String
    let fill: Color
    let border: Color
    var id: String { code }

    /// Which of her Canva patches this badge is stitched onto.
    var art: Sticker {
        switch code {
        case "milestone:10": .patchRainbow
        case "genre:scifi", "genre:ya": .patchStar
        case "goal:monthly": .patchDonut
        default: .patchCircle
        }
    }

    static func == (a: BadgeInfo, b: BadgeInfo) -> Bool { a.code == b.code }
    func hash(into h: inout Hasher) { h.combine(code) }
}

enum Badges {
    private static let denim = Color(hex: 0x3D6CB9)
    private static let sun = Color(hex: 0xF0C93A)
    private static let donut = Color(hex: 0xE7A0AE)
    private static let crust = Color(hex: 0xE9C99A)

    /// Mirrors the seed rows in the migration, styled as her embroidered patches.
    static let all: [BadgeInfo] = [
        .init(code: "goal:monthly", name: "Goal Getter", description: "Hit your monthly reading goal", symbol: "target", fill: .cream, border: .brick),
        .init(code: "club:finisher", name: "Club Member", description: "Finished the monthly book club pick", symbol: "person.3.fill", fill: .powder, border: denim),
        .init(code: "genre:fantasy", name: "Dragon Rider", description: "Finished a fantasy book", symbol: "wand.and.stars", fill: Color(hex: 0xE6DAF5), border: Color(hex: 0x7A4FB5)),
        .init(code: "genre:scifi", name: "Star Charter", description: "Finished a science fiction book", symbol: "sparkles", fill: Color(hex: 0x1F2B57), border: sun),
        .init(code: "genre:mystery", name: "Sleuth", description: "Finished a mystery", symbol: "magnifyingglass", fill: crust, border: Color(hex: 0x6B4A2A)),
        .init(code: "genre:thriller", name: "Edge of Seat", description: "Finished a thriller", symbol: "bolt.fill", fill: Color(hex: 0x2A2A2A), border: Color(hex: 0xE53935)),
        .init(code: "genre:romance", name: "Hopeless Romantic", description: "Finished a romance", symbol: "heart.fill", fill: donut, border: Color(hex: 0xC2185B)),
        .init(code: "genre:horror", name: "Night Owl", description: "Finished a horror book", symbol: "moon.stars.fill", fill: Color(hex: 0x3A2E4F), border: Color(hex: 0xF29C38)),
        .init(code: "genre:historical", name: "Time Traveler", description: "Finished historical fiction", symbol: "hourglass", fill: crust, border: Color(hex: 0x8D5524)),
        .init(code: "genre:literary", name: "Deep Reader", description: "Finished literary fiction", symbol: "text.book.closed.fill", fill: .cream, border: Color(hex: 0x2E7D5B)),
        .init(code: "genre:classics", name: "Old Soul", description: "Finished a classic", symbol: "building.columns.fill", fill: Color(hex: 0xEFE6D2), border: Color(hex: 0x6D5D3F)),
        .init(code: "genre:ya", name: "Forever Young", description: "Finished a young adult book", symbol: "star.fill", fill: denim, border: sun),
        .init(code: "genre:nonfiction", name: "Fact Finder", description: "Finished a nonfiction book", symbol: "lightbulb.fill", fill: Color(hex: 0xFFF3C6), border: Color(hex: 0xC98A00)),
        .init(code: "genre:biography", name: "Life Story", description: "Finished a biography or memoir", symbol: "person.crop.circle.fill", fill: .powder, border: Color(hex: 0x37618E)),
        .init(code: "genre:selfhelp", name: "Glow Up", description: "Finished a self-help book", symbol: "sun.max.fill", fill: Color(hex: 0xFFE4B5), border: Color(hex: 0xE07B00)),
        .init(code: "genre:poetry", name: "Verse Keeper", description: "Finished a poetry collection", symbol: "quote.opening", fill: Color(hex: 0xF7E1EA), border: .rose),
        .init(code: "genre:graphic", name: "Panel Pro", description: "Finished a graphic novel or comic", symbol: "rectangle.split.2x2.fill", fill: Color(hex: 0xFFF59D), border: Color(hex: 0xD84315)),
        .init(code: "milestone:1", name: "First Chapter", description: "Finished your first book", symbol: "1.circle.fill", fill: .cream, border: denim),
        .init(code: "milestone:10", name: "Full Card", description: "Filled your first punch card (10 books)", symbol: "rainbow", fill: .cream, border: Color(hex: 0xE53935)),
        .init(code: "milestone:25", name: "Bookworm", description: "Finished 25 books", symbol: "ladybug.fill", fill: Color(hex: 0xDCEDC8), border: Color(hex: 0x558B2F)),
        .init(code: "milestone:50", name: "Shelf Stacker", description: "Finished 50 books", symbol: "books.vertical.fill", fill: crust, border: Color(hex: 0x6B4A2A)),
        .init(code: "milestone:100", name: "Centurion", description: "Finished 100 books", symbol: "crown.fill", fill: Color(hex: 0x1F2B57), border: sun),
    ]

    static func info(_ code: String) -> BadgeInfo? { all.first { $0.code == code } }
}

// MARK: - Reading receipt

struct ReceiptLine: Identifiable {
    let id: UUID
    let title: String
    let author: String
    let pages: Int?
    let finished: String?
}

struct Receipt {
    let monthName: String
    let reader: String
    let lines: [ReceiptLine]
    let goal: Int

    init(profile: Profile, shelf: [UserBook], date: Date = .now) {
        monthName = Month.name(date)
        reader = profile.shortName
        goal = profile.monthlyGoal
        lines = shelf
            .filter { $0.status == .read && Month.contains($0.finishedAt, month: date) }
            .sorted { ($0.finishedAt ?? "") < ($1.finishedAt ?? "") }
            .map { ReceiptLine(id: $0.id, title: $0.book.title, author: $0.book.authorLine, pages: $0.book.pageCount, finished: $0.finishedAt) }
    }

    var totalPages: Int { lines.compactMap(\.pages).reduce(0, +) }
    var hitGoal: Bool { lines.count >= goal }
}
