import Foundation

/// Searches books the same way the website does: Hardcover first (through the
/// website, which keeps the Hardcover token on the server), then Google Books,
/// then Open Library, moving on whenever one fails or finds nothing.
enum BookSearch {
    static func search(_ query: String) async throws -> [BookCandidate] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return [] }

        if let books = try? await website(q), !books.isEmpty { return books.map(tidy) }
        if let books = try? await google(q), !books.isEmpty { return books.map(tidy) }
        return try await openLibrary(q).map(tidy)
    }

    /// Hardcover stores some names with extra spaces ("Katie   West").
    private static func tidy(_ book: BookCandidate) -> BookCandidate {
        var b = book
        b.authors = b.authors.map { $0.split(whereSeparator: \.isWhitespace).joined(separator: " ") }
        b.title = b.title.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        return b
    }

    // MARK: Website (Hardcover)

    private struct WebsiteResponse: Decodable { var results: [BookCandidate] }

    /// The website's /api/books/search, which searches Hardcover with the server's key.
    private static func website(_ q: String) async throws -> [BookCandidate] {
        guard let base = AppConfig.searchAPIBase,
              var c = URLComponents(url: base.appendingPathComponent("api/books/search"), resolvingAgainstBaseURL: false) else { return [] }
        c.queryItems = [URLQueryItem(name: "q", value: q)]
        guard let url = c.url else { return [] }
        var request = URLRequest(url: url)
        request.timeoutInterval = 8
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { return [] }
        return try JSONDecoder().decode(WebsiteResponse.self, from: data).results
    }

    // MARK: Google Books

    private struct GoogleResponse: Decodable {
        struct Volume: Decodable {
            struct Info: Decodable {
                struct Images: Decodable { var thumbnail: String?; var smallThumbnail: String? }
                var title: String?
                var authors: [String]?
                var pageCount: Int?
                var publishedDate: String?
                var categories: [String]?
                var imageLinks: Images?
            }
            var id: String
            var volumeInfo: Info?
        }
        var items: [Volume]?
    }

    private static func google(_ q: String) async throws -> [BookCandidate] {
        var c = URLComponents(string: "https://www.googleapis.com/books/v1/volumes")!
        c.queryItems = [
            URLQueryItem(name: "q", value: q),
            URLQueryItem(name: "maxResults", value: "20"),
            URLQueryItem(name: "printType", value: "books"),
        ]
        if let key = AppConfig.googleBooksKey { c.queryItems?.append(URLQueryItem(name: "key", value: key)) }
        let (data, response) = try await URLSession.shared.data(from: c.url!)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { return [] }
        let json = try JSONDecoder().decode(GoogleResponse.self, from: data)
        return (json.items ?? []).compactMap { v in
            guard let info = v.volumeInfo, let title = info.title else { return nil }
            let categories = info.categories ?? []
            // Google serves http thumbnails with a page curl; https without the curl looks cleaner.
            let cover = (info.imageLinks?.thumbnail ?? info.imageLinks?.smallThumbnail)?
                .replacingOccurrences(of: "http://", with: "https://")
                .replacingOccurrences(of: "&edge=curl", with: "")
            return BookCandidate(
                source: .google, externalID: v.id, title: title, authors: info.authors ?? [], coverURL: cover,
                pageCount: info.pageCount, publishedYear: info.publishedDate.flatMap { Int($0.prefix(4)) },
                categories: categories, badgeCategory: Genre.category(for: categories)
            )
        }
    }

    // MARK: Open Library

    private struct OpenLibraryResponse: Decodable {
        struct Doc: Decodable {
            var key: String
            var title: String?
            var author_name: [String]?
            var cover_i: Int?
            var number_of_pages_median: Int?
            var first_publish_year: Int?
            var subject: [String]?
        }
        var docs: [Doc]?
    }

    private static func openLibrary(_ q: String) async throws -> [BookCandidate] {
        var c = URLComponents(string: "https://openlibrary.org/search.json")!
        c.queryItems = [
            URLQueryItem(name: "q", value: q),
            URLQueryItem(name: "limit", value: "20"),
            URLQueryItem(name: "fields", value: "key,title,author_name,cover_i,number_of_pages_median,first_publish_year,subject"),
        ]
        let (data, _) = try await URLSession.shared.data(from: c.url!)
        let json = try JSONDecoder().decode(OpenLibraryResponse.self, from: data)
        return (json.docs ?? []).compactMap { d in
            guard let title = d.title else { return nil }
            let subjects = Array((d.subject ?? []).prefix(12))
            return BookCandidate(
                source: .openlibrary, externalID: d.key, title: title, authors: d.author_name ?? [],
                coverURL: d.cover_i.map { "https://covers.openlibrary.org/b/id/\($0)-L.jpg" },
                pageCount: d.number_of_pages_median, publishedYear: d.first_publish_year,
                categories: subjects, badgeCategory: Genre.category(for: subjects)
            )
        }
    }
}

enum AppConfig {
    private static func value(_ key: String) -> String? {
        guard let v = Bundle.main.object(forInfoDictionaryKey: key) as? String else { return nil }
        let trimmed = v.trimmingCharacters(in: .whitespaces)
        // An unset build setting comes through empty (or as the literal "$(…)" if misconfigured).
        return trimmed.isEmpty || trimmed.hasPrefix("$(") ? nil : trimmed
    }

    static var supabaseURL: URL? {
        guard let host = value("SupabaseHost") else { return nil }
        return URL(string: host.hasPrefix("http") ? host : "https://\(host)")
    }

    static var supabaseAnonKey: String? { value("SupabaseAnonKey") }
    static var googleBooksKey: String? { value("GoogleBooksAPIKey") }

    /// The Plot Twist website, whose search endpoint covers Hardcover.
    static var searchAPIBase: URL? {
        guard let host = value("SearchAPIHost") else { return nil }
        return URL(string: host.hasPrefix("http") ? host : "https://\(host)")
    }
}
