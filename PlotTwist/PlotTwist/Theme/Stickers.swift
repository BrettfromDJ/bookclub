import SwiftUI
import UIKit

/// The scrapbook stickers from her Canva file, drawn in code.
///
/// To use the real artwork instead, export a sticker from Canva as a transparent
/// PNG and add it to Assets.xcassets named `sticker-<case name>`
/// (for example `sticker-daisies`). The image then replaces the drawn version.
enum Sticker: String, CaseIterable {
    case goldStar, redBurst, smiley, daisies, pinkHeart, navyHearts, pinkStar, bow
    case paperPlane, arrow, binderClip, starTape, speechHeart

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
