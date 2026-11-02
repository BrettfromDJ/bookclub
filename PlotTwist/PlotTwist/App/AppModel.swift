import SwiftUI
import UIKit

/// App-wide state: who's signed in and their journal. Screens read from here
/// and call its methods, which write to the backend and then refresh.
@MainActor
@Observable
final class AppModel {
    enum Phase { case launching, signedOut, signedIn }

    let backend: Backend
    var phase: Phase = .launching
    var me: Profile?
    var shelf: [UserBook] = []
    var topEight: [Book?] = Array(repeating: nil, count: 8)
    var badges: [EarnedBadge] = []
    var club: ClubMonth?
    /// Shown as a toast.
    var message: String?

    init() {
        if let url = AppConfig.supabaseURL, let key = AppConfig.supabaseAnonKey {
            backend = SupabaseBackend(url: url, anonKey: key)
        } else {
            backend = DemoBackend()
        }
    }

    var isDemo: Bool { backend.isDemo }

    // MARK: Derived

    var currentlyReading: [UserBook] { shelf.filter { $0.status == .reading } }
    var tbr: [UserBook] { shelf.filter { $0.status == .tbr }.sorted { $0.position < $1.position } }
    var finished: [UserBook] { shelf.filter { $0.status == .read } }
    var punchCard: PunchCard { PunchCard(totalRead: finished.count) }
    var finishedThisMonth: Int { finished.filter { Month.contains($0.finishedAt) }.count }

    // MARK: Session

    func launch() async {
        if let id = await backend.restoreSession() {
            await loadEverything(userID: id)
        } else {
            phase = .signedOut
        }
    }

    func signedIn(as id: UUID) async {
        await loadEverything(userID: id)
    }

    private func loadEverything(userID: UUID) async {
        do {
            me = try await backend.profile(id: userID)
            phase = .signedIn
            await refresh()
        } catch {
            phase = .signedOut
            show(error)
        }
    }

    func refresh() async {
        guard let id = me?.id else { return }
        async let shelf = backend.shelf(userID: id)
        async let top = backend.topEight(userID: id)
        async let badges = backend.badges(userID: id)
        async let club = backend.clubMonth(Month.start())
        async let profile = backend.profile(id: id)
        do {
            self.shelf = try await shelf
            self.topEight = try await top
            self.badges = try await badges
            self.club = try await club
            self.me = try await profile
        } catch {
            show(error)
        }
    }

    func signOut() async {
        do {
            try await backend.signOut()
            reset()
        } catch { show(error) }
    }

    func deleteAccount() async {
        do {
            try await backend.deleteAccount()
            reset()
        } catch { show(error) }
    }

    private func reset() {
        me = nil
        shelf = []
        topEight = Array(repeating: nil, count: 8)
        badges = []
        phase = .signedOut
    }

    // MARK: Actions

    /// Runs a write, refreshes the journal, and reports any error.
    @discardableResult
    func perform(_ success: String? = nil, haptic: UINotificationFeedbackGenerator.FeedbackType? = .success,
                 _ work: () async throws -> Void) async -> Bool {
        do {
            try await work()
            // Celebrate right away; the refresh finishes in the background.
            if let haptic { UINotificationFeedbackGenerator().notificationOccurred(haptic) }
            if let success { message = success }
            await refresh()
            return true
        } catch {
            show(error)
            await refresh()
            return false
        }
    }

    func add(_ book: BookCandidate, formats: [BookFormat], status: ShelfStatus) async -> Bool {
        let note = switch status {
        case .tbr: "Added to your TBR"
        case .reading: "Happy reading!"
        case .read: "Punched your card!"
        }
        return await perform(note) { try await backend.addToShelf(book, formats: formats, status: status) }
    }

    func setStatus(_ book: UserBook, _ status: ShelfStatus) async {
        let before = punchCard
        // Move the book on screen immediately (and punch the card) before the save finishes.
        if let i = shelf.firstIndex(where: { $0.id == book.id }) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                shelf[i].status = status
                shelf[i].finishedAt = status == .read ? Month.today() : nil
            }
        }
        let filledCard = status == .read && punchCard.completedCards > before.completedCards
        await perform(filledCard ? "You filled a punch card! 🎉" : (status == .read ? "Punched your card!" : nil)) {
            try await backend.setStatus(book.id, status)
        }
    }

    /// Saves a new Top 8 order (shown immediately, saved in the background).
    func reorderTopEight(_ books: [Book?]) async {
        topEight = books
        await perform(haptic: nil) { try await backend.setTopEight(books) }
    }

    /// Moves a TBR book to `index` within the TBR order.
    func moveTBR(from source: IndexSet, to destination: Int) async {
        var order = tbr
        order.move(fromOffsets: source, toOffset: destination)
        guard let moved = source.first.map({ tbr[$0] }), let newIndex = order.firstIndex(where: { $0.id == moved.id }) else { return }
        let before = newIndex > 0 ? order[newIndex - 1].position : nil
        let after = newIndex < order.count - 1 ? order[newIndex + 1].position : nil
        let position = Ranking.between(before, after)
        // Update locally first so the list doesn't jump.
        if let i = shelf.firstIndex(where: { $0.id == moved.id }) { shelf[i].position = position }
        await perform(haptic: nil) { try await backend.setPosition(moved.id, position) }
    }

    func show(_ error: Error) {
        message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}
