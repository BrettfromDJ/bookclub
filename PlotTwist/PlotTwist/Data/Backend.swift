import Foundation

/// Everything the app reads and writes. `SupabaseBackend` talks to the real
/// database; `DemoBackend` keeps sample data in memory so the app runs in the
/// Simulator before Supabase is set up.
@MainActor
protocol Backend: AnyObject {
    var isDemo: Bool { get }

    // Auth
    func restoreSession() async -> UUID?
    func sendCode(email: String) async throws
    func verify(email: String, code: String) async throws -> UUID
    func signOut() async throws
    func deleteAccount() async throws

    // Profiles
    func profile(id: UUID) async throws -> Profile
    func profile(username: String) async throws -> Profile?
    func searchProfiles(_ query: String) async throws -> [Profile]
    func updateProfile(_ patch: ProfilePatch) async throws
    func uploadAvatar(_ jpeg: Data) async throws -> String

    // Shelves
    func shelf(userID: UUID) async throws -> [UserBook]
    func addToShelf(_ book: BookCandidate, formats: [BookFormat], status: ShelfStatus) async throws
    func setStatus(_ userBookID: UUID, _ status: ShelfStatus) async throws
    func setFormats(_ userBookID: UUID, _ formats: [BookFormat]) async throws
    func setPosition(_ userBookID: UUID, _ position: Double) async throws
    func setRating(_ userBookID: UUID, _ rating: Int?) async throws
    func removeFromShelf(_ userBookID: UUID) async throws

    // Showcase
    func topEight(userID: UUID) async throws -> [Book?]
    func setTopBook(slot: Int, book: BookCandidate?) async throws
    func badges(userID: UUID) async throws -> [EarnedBadge]

    // Book club
    func clubMonth(_ month: String) async throws -> ClubMonth?
    func clubMessages(_ month: String) async throws -> [ClubMessage]
    func sendClubMessage(_ month: String, body: String) async throws
    func deleteClubMessage(_ id: UUID) async throws

    // Social
    func feed() async throws -> [Activity]
    func addComment(activityID: UUID, body: String) async throws
    func followInfo(userID: UUID) async throws -> FollowInfo
    func follow(_ userID: UUID) async throws
    func unfollow(_ userID: UUID) async throws
    func followRequests() async throws -> [FollowRequest]
    func answerFollowRequest(from followerID: UUID, accept: Bool) async throws
    func report(_ target: ReportTarget, id: UUID, reason: String) async throws
    func block(_ userID: UUID) async throws
}

enum BackendError: LocalizedError {
    case message(String)
    var errorDescription: String? {
        switch self {
        case .message(let m): m
        }
    }
}
