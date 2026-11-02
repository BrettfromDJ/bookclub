import SwiftUI

// Colors and type pulled from the "Plot Twist" Canva file.

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }

    /// Off-white paper used for cards and frames.
    static let cream = Color(hex: 0xFFFEF7)
    /// Pale butter used for the "explore books" pill.
    static let butter = Color(hex: 0xFFF3C6)
    /// Headline gold ("hot girls collect books…").
    static let honey = Color(hex: 0xDDB860)
    /// Brighter gold ("plot twist", "top 8" tag, "profile" pill).
    static let marigold = Color(hex: 0xE0A619)
    /// Deep brick red used for most titles and the dashed borders.
    static let brick = Color(hex: 0xA22301)
    /// Rose used for "november book club" and the punch card title.
    static let rose = Color(hex: 0xD15C73)
    /// Bubblegum pink pills and "reading receipt".
    static let blush = Color(hex: 0xF8C0D5)
    /// Powder blue ("friends" pill, "share your plot twist", "10 more!" badge).
    static let powder = Color(hex: 0xD3E4F1)
    /// Olive green action pills ("add a book to your tbr", "join the chat").
    static let olive = Color(hex: 0x949A60)
    /// Dark ink for doodles.
    static let ink = Color(hex: 0x3B2A20)
    /// Navy ink for the heart doodles.
    static let navyInk = Color(hex: 0x2B3460)
    /// Kraft paper behind cut-out stickers.
    static let kraft = Color(hex: 0xEDE3CF)
}

extension Font {
    /// Wide, heavy rounded sans (her "plot twist", "top 8", pill labels).
    /// Stand-in for the Canva font: Poppins.
    static func display(_ size: CGFloat, weight: DisplayWeight = .extraBold) -> Font {
        .custom(weight.rawValue, size: size)
    }

    /// Tight display serif ("hot girls collect books…", "november book club").
    /// Stand-in for the Canva font: DM Serif Display.
    static func serif(_ size: CGFloat, italic: Bool = false) -> Font {
        .custom(italic ? "DMSerifDisplay-Italic" : "DMSerifDisplay-Regular", size: size)
    }

    enum DisplayWeight: String {
        case semiBold = "Poppins-SemiBold"
        case bold = "Poppins-Bold"
        case extraBold = "Poppins-ExtraBold"
    }
}

// MARK: - Design canvas

/// Her artboards are 1080 px wide. Views on the home screen are placed in those
/// design coordinates and scaled to the phone's width, so the layout matches the
/// Canva file on every iPhone size.
private struct DesignScaleKey: EnvironmentKey {
    static let defaultValue: CGFloat = 393.0 / 1080.0
}

extension EnvironmentValues {
    var designScale: CGFloat {
        get { self[DesignScaleKey.self] }
        set { self[DesignScaleKey.self] = newValue }
    }
}

enum Design {
    static let width: CGFloat = 1080
}

private struct Place: ViewModifier {
    @Environment(\.designScale) private var s
    let x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, rotation: Double

    func body(content: Content) -> some View {
        content
            .frame(width: w * s, height: h * s)
            .rotationEffect(.degrees(rotation))
            .position(x: (x + w / 2) * s, y: (y + h / 2) * s)
    }
}

extension View {
    /// Places a view at Canva coordinates (left, top, width, height, rotation in degrees).
    func place(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, rotation: Double = 0) -> some View {
        modifier(Place(x: x, y: y, w: w, h: h, rotation: rotation))
    }
}

/// One of her artboards: a fixed-height design-coordinate canvas.
struct Artboard<Content: View>: View {
    @Environment(\.designScale) private var s
    let height: CGFloat
    @ViewBuilder var content: Content

    var body: some View {
        ZStack(alignment: .topLeading) { content }
            .frame(width: Design.width * s, height: height * s, alignment: .topLeading)
    }
}

/// Text sized in design pixels.
struct DesignText: View {
    @Environment(\.designScale) private var s
    let text: String
    var size: CGFloat
    var serif = false
    var italic = false
    var weight: Font.DisplayWeight = .extraBold
    var color: Color = .brick
    var alignment: TextAlignment = .center
    var tracking: CGFloat = 0
    var lineSpacing: CGFloat = 0

    init(_ text: String, size: CGFloat, serif: Bool = false, italic: Bool = false, weight: Font.DisplayWeight = .extraBold,
         color: Color = .brick, alignment: TextAlignment = .center, tracking: CGFloat = 0, lineSpacing: CGFloat = 0) {
        self.text = text
        self.size = size
        self.serif = serif
        self.italic = italic
        self.weight = weight
        self.color = color
        self.alignment = alignment
        self.tracking = tracking
        self.lineSpacing = lineSpacing
    }

    var body: some View {
        Text(text)
            .font(serif ? .serif(size * s, italic: italic) : .display(size * s, weight: weight))
            .tracking(tracking * size * s)
            .lineSpacing(lineSpacing * s)
            .foregroundStyle(color)
            .multilineTextAlignment(alignment)
            .minimumScaleFactor(0.5)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: frameAlignment)
    }

    private var frameAlignment: Alignment {
        switch alignment {
        case .leading: .leading
        case .trailing: .trailing
        default: .center
        }
    }
}
