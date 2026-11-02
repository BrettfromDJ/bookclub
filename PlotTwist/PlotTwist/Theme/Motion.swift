import SwiftUI

// Motion for the scrapbook: things land on the page when an artboard scrolls in,
// then keep gently moving. Everything turns off with Reduce Motion.

// MARK: - Reveal

private struct RevealedKey: EnvironmentKey {
    static let defaultValue = true
}

extension EnvironmentValues {
    /// False until the artboard containing this view has scrolled into view.
    var revealed: Bool {
        get { self[RevealedKey.self] }
        set { self[RevealedKey.self] = newValue }
    }
}

/// How a piece lands on the page.
enum Entrance {
    /// Pops up from small, spinning by `spin` degrees.
    case pop(spin: Double = 0)
    /// Unfolds from a crumpled, tipped-back sheet.
    case paper
    /// Drops in from above with a bounce.
    case drop
    /// Flies in from an offset (in points), tilted.
    case fly(x: CGFloat, y: CGFloat)
    /// Flips around its vertical axis like a card being turned over.
    case flip
    /// Rises a little while fading in.
    case rise
    /// Slides in from the left edge.
    case slide

    fileprivate var animation: Animation {
        switch self {
        case .pop: .spring(response: 0.5, dampingFraction: 0.55)
        case .paper: .spring(response: 0.7, dampingFraction: 0.68)
        case .drop: .spring(response: 0.55, dampingFraction: 0.5)
        case .fly: .spring(response: 0.8, dampingFraction: 0.72)
        case .flip: .spring(response: 0.6, dampingFraction: 0.7)
        case .rise: .spring(response: 0.5, dampingFraction: 0.8)
        case .slide: .spring(response: 0.7, dampingFraction: 0.8)
        }
    }
}

private struct EntranceModifier: ViewModifier {
    @Environment(\.revealed) private var revealed
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let kind: Entrance
    let delay: Double

    func body(content: Content) -> some View {
        let shown = revealed || reduceMotion
        var sx: CGFloat = 1, sy: CGFloat = 1, rotation = 0.0, tilt = 0.0
        var axis: (x: CGFloat, y: CGFloat, z: CGFloat) = (1, 0, 0)
        var dx: CGFloat = 0, dy: CGFloat = 0
        var anchor = UnitPoint.center
        if !shown {
            switch kind {
            case .pop(let spin): sx = 0.2; sy = 0.2; rotation = spin
            case .paper: sx = 0.82; sy = 0.9; rotation = -7; tilt = 70; anchor = .top
            case .drop: dy = -140; rotation = -12
            case .fly(let x, let y): dx = x; dy = y; rotation = -25; sx = 0.6; sy = 0.6
            case .flip: tilt = 90; axis = (0, 1, 0)
            case .rise: dy = 24
            case .slide: dx = -420
            }
        }
        return content
            .scaleEffect(x: sx, y: sy, anchor: anchor)
            .rotationEffect(.degrees(rotation))
            .rotation3DEffect(.degrees(tilt), axis: axis, anchor: anchor, perspective: 0.5)
            .offset(x: dx, y: dy)
            .opacity(shown ? 1 : 0)
            .animation(reduceMotion ? nil : kind.animation.delay(shown ? delay : 0), value: shown)
    }
}

// MARK: - Idle loops

/// Gentle, never-ending movement once something is on the page.
enum Idle {
    /// Rocks back and forth by ± degrees.
    case wobble(Double)
    /// Floats up and down by ± points.
    case bob(CGFloat)
    /// Turns all the way round, once per period.
    case spin
    /// Grows and shrinks by a factor (e.g. 1.08).
    case pulse(CGFloat)
    /// Nudges along an offset and back.
    case nudge(x: CGFloat, y: CGFloat)
}

private struct IdleModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let kind: Idle
    let period: Double
    @State private var on = false

    func body(content: Content) -> some View {
        var rotation = 0.0, scale: CGFloat = 1, dx: CGFloat = 0, dy: CGFloat = 0
        switch kind {
        case .wobble(let a): rotation = on ? a : -a
        case .bob(let d): dy = on ? -d : d
        case .spin: rotation = on ? 360 : 0
        case .pulse(let f): scale = on ? f : 1
        case .nudge(let x, let y): dx = on ? x : 0; dy = on ? y : 0
        }
        let animation: Animation = switch kind {
        case .spin: .linear(duration: period).repeatForever(autoreverses: false)
        default: .easeInOut(duration: period).repeatForever(autoreverses: true)
        }
        return content
            .rotationEffect(.degrees(rotation))
            .scaleEffect(scale)
            .offset(x: dx, y: dy)
            // Only these transforms animate; the view's position on the page never does.
            .animation(reduceMotion ? nil : animation, value: on)
            .task {
                guard !reduceMotion else { return }
                // Reset without animating, so the loop restarts cleanly each time this scrolls back into view.
                var reset = Transaction()
                reset.disablesAnimations = true
                withTransaction(reset) { on = false }
                // Small random start so stickers don't all move in lockstep.
                try? await Task.sleep(for: .milliseconds(Int.random(in: 30...400)))
                on = true
            }
    }
}

extension View {
    /// Animate in when the artboard is revealed.
    func entrance(_ kind: Entrance, delay: Double = 0) -> some View {
        modifier(EntranceModifier(kind: kind, delay: delay))
    }

    /// Keep moving gently forever.
    func idle(_ kind: Idle, period: Double = 2) -> some View {
        modifier(IdleModifier(kind: kind, period: period))
    }
}

// MARK: - Bouncy lettering

/// Display lettering where each letter bounces in, one after another.
struct BouncyText: View {
    @Environment(\.designScale) private var s
    @Environment(\.revealed) private var revealed
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let text: String
    /// Font size in design pixels.
    var size: CGFloat
    var color: Color = .brick
    var tracking: CGFloat = -0.02
    var delay: Double = 0

    @State private var naturalWidth: CGFloat = 0

    var body: some View {
        GeometryReader { box in
            letters
                .fixedSize()
                .background(GeometryReader { g in Color.clear.preference(key: NaturalWidthKey.self, value: g.size.width) })
                .onPreferenceChange(NaturalWidthKey.self) { naturalWidth = $0 }
                // Shrink to fit if the word is wider than its spot (e.g. a long name).
                .scaleEffect(naturalWidth > box.size.width && naturalWidth > 0 ? box.size.width / naturalWidth : 1)
                .frame(width: box.size.width, height: box.size.height)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
    }

    private var letters: some View {
        let shown = revealed || reduceMotion
        return HStack(spacing: tracking * size * s) {
            ForEach(Array(text.enumerated()), id: \.offset) { i, ch in
                Text(String(ch))
                    .font(.display(size * s))
                    .foregroundStyle(color)
                    .fixedSize()
                    .offset(y: shown ? 0 : 40 * s + CGFloat(i % 3) * 14 * s)
                    .rotationEffect(.degrees(shown ? 0 : Double((i % 2 == 0) ? -25 : 25)))
                    .scaleEffect(shown ? 1 : 0.3)
                    .opacity(shown ? 1 : 0)
                    .animation(
                        reduceMotion ? nil : .spring(response: 0.45, dampingFraction: 0.5).delay(shown ? delay + Double(i) * 0.035 : 0),
                        value: shown
                    )
            }
        }
    }
}

private struct NaturalWidthKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

/// Reveals `.entrance` pieces inside it when it appears (for screens other than the home artboards).
private struct RevealOnAppear: ViewModifier {
    @State private var revealed = false

    func body(content: Content) -> some View {
        content
            .environment(\.revealed, revealed)
            .task {
                try? await Task.sleep(for: .milliseconds(60))
                revealed = true
            }
    }
}

extension View {
    func revealsOnAppear() -> some View { modifier(RevealOnAppear()) }
}
