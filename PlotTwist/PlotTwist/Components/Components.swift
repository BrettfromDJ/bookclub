import SwiftUI

// Building blocks in her scrapbook style, shared across screens.

/// A book cover from its URL, with a styled stand-in while loading or if there's no cover.
struct BookCover: View {
    var url: String?
    var title: String
    var author: String = ""
    var cornerRadius: CGFloat = 3

    var body: some View {
        AsyncImage(url: url.flatMap(URL.init(string:)), transaction: Transaction(animation: .easeIn(duration: 0.2))) { phase in
            if case .success(let image) = phase {
                image.resizable().scaledToFill()
            } else {
                placeholder
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .accessibilityLabel(author.isEmpty ? title : "\(title) by \(author)")
    }

    private static let palette: [(Color, Color)] = [
        (.blush, .brick), (.powder, .navyInk), (.butter, .brick), (.olive, .cream), (.rose, .cream), (.honey, .cream),
    ]

    private var placeholder: some View {
        let seed = title.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
        let (bg, fg) = Self.palette[seed % Self.palette.count]
        return ZStack {
            bg
            VStack(spacing: 4) {
                Text(title)
                    .font(.serif(15))
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.4)
                if !author.isEmpty {
                    Text(author.lowercased())
                        .font(.display(8, weight: .semiBold))
                        .minimumScaleFactor(0.5)
                }
            }
            .foregroundStyle(fg)
            .padding(6)
        }
    }
}

extension BookCover {
    init(_ book: Book) { self.init(url: book.coverURL, title: book.title, author: book.authorLine) }
    init(_ book: BookCandidate) { self.init(url: book.coverURL, title: book.title, author: book.authorLine) }
}

/// Her rounded label pills ("your current read", "add a book to your tbr").
struct Pill: View {
    let title: String
    var fill: Color = .olive
    var text: Color = .cream
    var size: CGFloat = 15

    var body: some View {
        Text(title)
            .font(.display(size))
            .tracking(-0.02 * size)
            .foregroundStyle(text)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .padding(.horizontal, size * 1.2)
            .padding(.vertical, size * 0.55)
            .background(Capsule().fill(fill))
    }
}

/// A design-scaled pill placed on an artboard; the label is sized in design pixels.
struct ArtboardPill: View {
    @Environment(\.designScale) private var s
    let title: String
    var fill: Color
    var text: Color
    var fontSize: CGFloat

    var body: some View {
        ZStack {
            Capsule().fill(fill)
            Text(title)
                .font(.display(fontSize * s))
                .tracking(-0.078 * fontSize * s)
                .foregroundStyle(text)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.horizontal, 20 * s)
        }
    }
}

/// Small round profile photo.
struct Avatar: View {
    var url: String?
    var name: String
    var size: CGFloat = 40

    var body: some View {
        AsyncImage(url: url.flatMap(URL.init(string:))) { phase in
            if case .success(let image) = phase {
                image.resizable().scaledToFill()
            } else {
                ZStack {
                    Color.blush
                    Text(String(name.prefix(1)).lowercased())
                        .font(.serif(size * 0.5))
                        .foregroundStyle(Color.brick)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.cream, lineWidth: 2))
    }
}

/// Toggle chips for physical / audio / kindle.
struct FormatPicker: View {
    @Binding var formats: Set<BookFormat>

    var body: some View {
        HStack(spacing: 8) {
            ForEach(BookFormat.allCases) { f in
                let on = formats.contains(f)
                Button {
                    if on, formats.count > 1 { formats.remove(f) } else { formats.insert(f) }
                } label: {
                    Label(f.label, systemImage: f.symbol)
                        .font(.display(13, weight: .bold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .foregroundStyle(on ? Color.cream : Color.brick)
                        .background(Capsule().fill(on ? Color.brick : Color.cream))
                        .overlay(Capsule().stroke(Color.brick, lineWidth: 1.5))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
    }
}

/// Cream paper card with her dashed brick border.
struct PaperCard<Content: View>: View {
    var dashed = true
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 22).fill(Color.cream))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(Color.brick, style: StrokeStyle(lineWidth: 1.5, dash: dashed ? [5, 4] : []))
                    .padding(5)
            )
            .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
    }
}

/// Section title for the secondary screens.
struct ScreenTitle: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.display(34))
                .tracking(-1.5)
                .foregroundStyle(Color.brick)
            if let subtitle {
                Text(subtitle)
                    .font(.serif(19))
                    .foregroundStyle(Color.rose)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Blue striped background used behind every screen.
struct StripedBackground: View {
    var stripe: Color = .powder
    var base: Color = .cream
    var body: some View {
        Stripes(base: base, stripe: stripe).ignoresSafeArea()
    }
}

extension View {
    /// Standard look for the secondary screens: striped paper behind, plain back button.
    func scrapbookScreen(stripe: Color = .powder) -> some View {
        self
            .scrollContentBackground(.hidden)
            .background(StripedBackground(stripe: stripe))
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
    }
}

/// Primary button: brick capsule.
struct BrickButtonStyle: ButtonStyle {
    var fill: Color = .brick
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.display(16))
            .foregroundStyle(Color.cream)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(Capsule().fill(fill))
            .opacity(configuration.isPressed ? 0.8 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

/// Makes artboard elements feel tappable: a little squish and a tick.
struct SquishButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(duration: 0.25), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == SquishButtonStyle {
    static var squish: SquishButtonStyle { SquishButtonStyle() }
}
