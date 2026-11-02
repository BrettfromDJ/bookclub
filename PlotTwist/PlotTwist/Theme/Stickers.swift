import SwiftUI
import UIKit

/// The scrapbook stickers from her Canva file.
///
/// The real artwork lives in Assets.xcassets as `sticker-<case name>`
/// (exported from Canva as transparent PNGs). Each case also has a drawn
/// fallback, used if an image is missing.
enum Sticker: String, CaseIterable {
    case goldStar, redBurst, smiley, daisies, pinkHeart, navyHearts, pinkStar, bow
    case paperPlane, arrow, binderClip, starTape, speechHeart
    case scallop, roundFrame, patchCircle, patchRainbow, patchDonut, patchStar

    var assetName: String { "sticker-\(rawValue)" }
}

struct StickerView: View {
    let sticker: Sticker

    init(_ sticker: Sticker) { self.sticker = sticker }

    var body: some View {
        if let image = UIImage(named: sticker.assetName) {
            Image(uiImage: image).resizable().scaledToFit()
        } else {
            drawn.accessibilityHidden(true)
        }
    }

    @ViewBuilder private var drawn: some View {
        switch sticker {
        case .goldStar:
            DoodleStar(points: 6, inner: 0.3, seed: 11).fill(Color.marigold)
        case .redBurst:
            ZStack {
                DoodleStar(points: 8, inner: 0.55, seed: 4).fill(Color.kraft)
                DoodleStar(points: 8, inner: 0.45, seed: 4).fill(Color(hex: 0xD8261C)).padding(8)
            }
            .shadow(color: .black.opacity(0.15), radius: 1, y: 1)
        case .smiley:
            ZStack {
                Circle().fill(Color.kraft)
                Circle().strokeBorder(Color.ink, lineWidth: 3).padding(5)
                VStack(spacing: 3) {
                    HStack(spacing: 7) { Capsule().fill(Color.ink).frame(width: 3, height: 7); Capsule().fill(Color.ink).frame(width: 3, height: 7) }
                    Path { p in
                        p.addArc(center: CGPoint(x: 10, y: 0), radius: 9, startAngle: .degrees(20), endAngle: .degrees(160), clockwise: false)
                    }
                    .stroke(Color.ink, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 20, height: 10)
                }
            }
            .shadow(color: .black.opacity(0.15), radius: 1, y: 1)
        case .daisies:
            HStack(spacing: -10) {
                Daisy().frame(width: 34, height: 34)
                Daisy().frame(width: 30, height: 30).offset(y: 6)
            }
        case .pinkHeart:
            ZStack {
                HeartShape().fill(Color(hex: 0xF4B9C9)).padding(-4)
                HeartShape().stroke(Color(hex: 0xE04A5A), lineWidth: 3).padding(4)
            }
            .shadow(color: .black.opacity(0.12), radius: 1, y: 1)
        case .navyHearts:
            VStack(alignment: .leading, spacing: 2) {
                doodleHeart.frame(width: 26, height: 24)
                doodleHeart.frame(width: 24, height: 22).rotationEffect(.degrees(12)).padding(.leading, 22)
                doodleHeart.frame(width: 26, height: 24).rotationEffect(.degrees(-10)).padding(.leading, 6)
            }
        case .pinkStar:
            ZStack {
                DoodleStar(points: 5, inner: 0.42, seed: 9).fill(Color(hex: 0xF4A3BE))
                DoodleStar(points: 5, inner: 0.42, seed: 9).stroke(Color(hex: 0xD8331F), lineWidth: 2.5).padding(7)
            }
        case .bow:
            ZStack {
                HStack(spacing: 0) {
                    Ellipse().stroke(Color(hex: 0xD8331F), lineWidth: 2.5).frame(width: 18, height: 13).rotationEffect(.degrees(-15))
                    Circle().stroke(Color(hex: 0xD8331F), lineWidth: 2.5).frame(width: 6, height: 6)
                    Ellipse().stroke(Color(hex: 0xD8331F), lineWidth: 2.5).frame(width: 18, height: 13).rotationEffect(.degrees(15))
                }
                .padding(6)
                .background(Capsule().fill(Color(hex: 0xF4A3BE)))
            }
        case .paperPlane:
            ZStack(alignment: .topTrailing) {
                Path { p in
                    p.move(to: CGPoint(x: 0, y: 40))
                    p.addCurve(to: CGPoint(x: 60, y: 22), control1: CGPoint(x: 25, y: 50), control2: CGPoint(x: 35, y: 10))
                }
                .stroke(Color.ink, style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [4, 4]))
                Image(systemName: "paperplane")
                    .font(.system(size: 26, weight: .regular))
                    .foregroundStyle(Color.ink)
                    .padding(4)
                    .background(Color.kraft, in: RoundedRectangle(cornerRadius: 6))
            }
        case .arrow:
            CurvedArrow().stroke(Color.ink, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
        case .binderClip:
            BinderClip()
        case .starTape:
            ZStack {
                TornPaper(edges: [.leading, .trailing], roughness: 4, seed: 21).fill(Color.kraft.opacity(0.92))
                GeometryReader { geo in
                    let cols = max(Int(geo.size.width / 26), 1)
                    ForEach(0..<cols * 2, id: \.self) { i in
                        Image(systemName: "star.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(Color.ink)
                            .rotationEffect(.degrees(Double(i * 37 % 60) - 30))
                            .position(x: CGFloat(i % cols) * 26 + (i / cols == 0 ? 10 : 22),
                                      y: geo.size.height * (i / cols == 0 ? 0.32 : 0.7))
                    }
                }
            }
        case .scallop:
            Scallop(bumps: 16, depth: 0.06).fill(Color.powder)
        case .roundFrame:
            Circle().fill(Color.white).shadow(color: .black.opacity(0.25), radius: 2, y: 1.5)
        case .patchCircle:
            PatchView(symbol: "circle", fill: .white, border: Color(hex: 0x3D6CB9))
        case .patchRainbow:
            Image(systemName: "rainbow").resizable().scaledToFit().symbolRenderingMode(.multicolor)
        case .patchDonut:
            PatchView(symbol: "circle.circle", fill: Color(hex: 0xE7A0AE), border: Color(hex: 0xE9C99A))
        case .patchStar:
            PatchView(symbol: "star.fill", fill: Color(hex: 0xF0C93A), border: Color(hex: 0x3D6CB9))
        case .speechHeart:
            ZStack {
                Image(systemName: "bubble.left.fill").resizable().scaledToFit().foregroundStyle(Color.kraft)
                Image(systemName: "bubble.left").resizable().scaledToFit().foregroundStyle(Color.ink).padding(4)
                Image(systemName: "heart.fill").resizable().scaledToFit().foregroundStyle(Color.ink).padding(18).offset(y: -4)
            }
        }
    }

    private var doodleHeart: some View {
        ZStack {
            HeartShape().fill(Color.kraft).padding(-3)
            HeartShape().stroke(Color.navyInk, style: StrokeStyle(lineWidth: 2.5, lineJoin: .round)).padding(2)
        }
    }
}

private struct Daisy: View {
    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ZStack {
                ForEach(0..<14, id: \.self) { i in
                    Capsule()
                        .fill(Color.white)
                        .overlay(Capsule().stroke(Color.black.opacity(0.08), lineWidth: 0.5))
                        .frame(width: s * 0.17, height: s * 0.5)
                        .offset(y: -s * 0.24)
                        .rotationEffect(.degrees(Double(i) * 360 / 14))
                }
                Circle().fill(Color(hex: 0xF2B51D)).frame(width: s * 0.32)
            }
            .frame(width: s, height: s)
            .shadow(color: .black.opacity(0.15), radius: 1.5, y: 1)
        }
    }
}

private struct BinderClip: View {
    private let bronze = LinearGradient(colors: [Color(hex: 0x9A8455), Color(hex: 0x6B5A35), Color(hex: 0x8C7748)],
                                        startPoint: .top, endPoint: .bottom)
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack(alignment: .top) {
                // Handle
                UnevenRoundedRectangle(topLeadingRadius: w * 0.12, topTrailingRadius: w * 0.12)
                    .fill(bronze)
                    .frame(width: w * 0.55, height: h * 0.55)
                    .overlay(alignment: .top) {
                        Circle().fill(Color.black.opacity(0.55)).frame(width: w * 0.08).padding(.top, h * 0.08)
                    }
                // Jaw
                RoundedRectangle(cornerRadius: 4)
                    .fill(bronze)
                    .frame(width: w, height: h * 0.42)
                    .offset(y: h * 0.52)
                    .shadow(color: .black.opacity(0.35), radius: 2, y: 2)
            }
            .frame(width: w, height: h)
        }
    }
}

/// An image from the asset catalog, or a fallback view if it's missing.
struct Artwork<Fallback: View>: View {
    let name: String
    /// nil stretches the image to the frame (fine for paper scraps).
    var contentMode: ContentMode? = .fit
    var alignment: Alignment = .center
    @ViewBuilder var fallback: Fallback

    var body: some View {
        if let image = UIImage(named: name) {
            Group {
                if let contentMode {
                    Image(uiImage: image).resizable().aspectRatio(contentMode: contentMode)
                } else {
                    Image(uiImage: image).resizable()
                }
            }
            // minWidth/minHeight 0 make the frame take the placed size even when a
            // .fill image is larger, so .clipped() crops it to a strip.
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: alignment)
            .clipped()
            // Clipping hides the overflow but doesn't stop it catching taps, and these are
            // decorations anyway: let touches fall through to the buttons underneath.
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        } else {
            fallback
        }
    }
}

/// Her painted striped paper.
///
/// The stripes are one continuous sheet running down the whole scroll: `top` is
/// how far down that sheet (in design pixels) this piece starts, so a band that
/// continues in the next artboard lines up exactly. The image repeats with every
/// other copy flipped, which makes the joins seamless.
struct StripedPaper: View {
    enum Kind { case blue, red }
    var kind: Kind = .blue
    var top: CGFloat = 0

    var body: some View {
        if kind == .red {
            // Drawn crisp (the painted red texture looked blurry on device).
            CrispStripes(top: top).accessibilityHidden(true).allowsHitTesting(false)
        } else if let image = UIImage(named: "texture-stripesBlue"), image.size.width > 0 {
            GeometryReader { geo in
                let w = geo.size.width, h = geo.size.height
                if w > 0, h > 0 {
                    let s = w / Design.width
                    // In the Canva file the stripe image is ~26% wider than the artboard.
                    let tileW = w * 1.26
                    let tileH = tileW * image.size.height / image.size.width
                    let start = top * s
                    let first = Int((start / tileH).rounded(.down))
                    let last = Int(((start + h) / tileH).rounded(.down))
                    ZStack(alignment: .topLeading) {
                        ForEach(first...max(first, min(last, first + 12)), id: \.self) { i in
                            Image(uiImage: image)
                                .resizable()
                                .frame(width: tileW, height: tileH)
                                .scaleEffect(x: 1, y: i.isMultiple(of: 2) ? 1 : -1)
                                .offset(x: (w - tileW) / 2, y: CGFloat(i) * tileH - start)
                        }
                    }
                    .frame(width: w, height: h, alignment: .topLeading)
                    .clipped()
                }
            }
            .accessibilityHidden(true)
            .allowsHitTesting(false)
        } else {
            Stripes(stripe: .powder).allowsHitTesting(false)
        }
    }
}

/// Her red-and-pink stripes, drawn as sharp shapes in the colors sampled from her
/// texture. Edges wobble slightly like paint; the wobble depends on the position
/// down the page (`top` + y), so stripes continue seamlessly into the next section.
struct CrispStripes: View {
    var top: CGFloat = 0
    var red = Color(hex: 0xA42702)
    var pink = Color(hex: 0xF6B4B5)

    var body: some View {
        Canvas { ctx, size in
            guard size.width > 0, size.height > 0 else { return }
            let s = size.width / Design.width
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(pink))
            // Design-pixel widths measured from her texture.
            let redWidths: [CGFloat] = [131, 149, 136, 132, 136, 120]
            let pinkWidths: [CGFloat] = [100, 93, 108, 129, 123, 119]
            let startY = top * s
            func wobble(_ stripe: Int, _ edge: Int, _ y: CGFloat) -> CGFloat {
                let absY = (startY + y) / s
                return (sin(absY / 95 + CGFloat(stripe * 3 + edge) * 1.7) * 2.2
                    + sin(absY / 37 + CGFloat(stripe + edge * 5)) * 0.9) * s
            }
            var x: CGFloat = -60 * s
            var i = 0
            while x < size.width {
                let w = redWidths[i % redWidths.count] * s
                var path = Path()
                let step: CGFloat = 12
                path.move(to: CGPoint(x: x + wobble(i, 0, 0), y: 0))
                var y: CGFloat = 0
                while y < size.height {
                    y = min(y + step, size.height)
                    path.addLine(to: CGPoint(x: x + wobble(i, 0, y), y: y))
                }
                while y > 0 {
                    path.addLine(to: CGPoint(x: x + w + wobble(i, 1, y), y: y))
                    y = max(y - step, 0)
                }
                path.addLine(to: CGPoint(x: x + w + wobble(i, 1, 0), y: 0))
                path.closeSubpath()
                ctx.fill(path, with: .color(red))
                x += w + pinkWidths[i % pinkWidths.count] * s
                i += 1
            }
        }
    }
}

/// An embroidered patch, used for badges.
struct PatchView: View {
    let symbol: String
    var fill: Color
    var border: Color
    var earned = true

    var body: some View {
        ZStack {
            Scallop(bumps: 14, depth: 0.05).fill(border)
            Circle().fill(fill).padding(9)
            Circle().strokeBorder(Color.white.opacity(0.85), style: StrokeStyle(lineWidth: 1.5, dash: [3, 3])).padding(5)
            Image(systemName: symbol)
                .resizable()
                .scaledToFit()
                .fontWeight(.bold)
                .foregroundStyle(border)
                .padding(22)
        }
        .compositingGroup()
        .saturation(earned ? 1 : 0)
        .opacity(earned ? 1 : 0.35)
        .shadow(color: .black.opacity(earned ? 0.25 : 0), radius: 2, y: 2)
    }
}

/// A badge drawn as one of her embroidered patches. A few badges use a specific
/// patch (rainbow, star, donut); the rest put their icon inside the blue circle patch.
struct BadgePatch: View {
    let badge: BadgeInfo
    var earned = true

    var body: some View {
        Group {
            if UIImage(named: badge.art.assetName) != nil {
                if badge.art == .patchCircle {
                    ZStack {
                        StickerView(.patchCircle)
                        Image(systemName: badge.symbol)
                            .resizable()
                            .scaledToFit()
                            .fontWeight(.heavy)
                            .foregroundStyle(badge.border)
                            .padding(26)
                    }
                } else {
                    StickerView(badge.art)
                }
            } else {
                PatchView(symbol: badge.symbol, fill: badge.fill, border: badge.border)
            }
        }
        .compositingGroup()
        .saturation(earned ? 1 : 0)
        .opacity(earned ? 1 : 0.35)
        .shadow(color: .black.opacity(earned ? 0.2 : 0), radius: 2, y: 2)
        .accessibilityLabel(badge.name)
    }
}
