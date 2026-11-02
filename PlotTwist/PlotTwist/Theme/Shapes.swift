import SwiftUI

/// Deterministic random numbers, so hand-drawn edges look the same on every redraw.
struct SeededRandom {
    private var state: UInt64
    init(_ seed: UInt64) { state = seed &* 6364136223846793005 &+ 1442695040888963407 }
    mutating func next() -> CGFloat {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return CGFloat((state >> 33) % 10_000) / 10_000
    }
    mutating func range(_ lo: CGFloat, _ hi: CGFloat) -> CGFloat { lo + (hi - lo) * next() }
}

/// A rectangle with ripped edges, like torn notebook or watercolor paper.
struct TornPaper: Shape {
    var edges: Edge.Set = .all
    var roughness: CGFloat = 6
    var seed: UInt64 = 1

    func path(in rect: CGRect) -> Path {
        var rng = SeededRandom(seed)
        let step: CGFloat = 7
        var p = Path()

        func jag(_ on: Bool) -> CGFloat { on ? rng.range(0, roughness) : 0 }

        // Top edge, left to right.
        p.move(to: CGPoint(x: rect.minX, y: rect.minY + jag(edges.contains(.top))))
        var x = rect.minX
        while x < rect.maxX {
            x = min(x + step, rect.maxX)
            p.addLine(to: CGPoint(x: x, y: rect.minY + jag(edges.contains(.top))))
        }
        // Right edge, top to bottom.
        var y = rect.minY
        while y < rect.maxY {
            y = min(y + step, rect.maxY)
            p.addLine(to: CGPoint(x: rect.maxX - jag(edges.contains(.trailing)), y: y))
        }
        // Bottom edge, right to left.
        x = rect.maxX
        while x > rect.minX {
            x = max(x - step, rect.minX)
            p.addLine(to: CGPoint(x: x, y: rect.maxY - jag(edges.contains(.bottom))))
        }
        // Left edge, bottom to top.
        y = rect.maxY
        while y > rect.minY {
            y = max(y - step, rect.minY)
            p.addLine(to: CGPoint(x: rect.minX + jag(edges.contains(.leading)), y: y))
        }
        p.closeSubpath()
        return p
    }
}

/// A circle with a wavy edge (the "10 more!" badge, embroidered patches).
struct Scallop: Shape {
    var bumps = 16
    var depth: CGFloat = 0.06

    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        var p = Path()
        let steps = bumps * 12
        for i in 0...steps {
            let a = CGFloat(i) / CGFloat(steps) * .pi * 2
            let rr = r * (1 - depth) + r * depth * cos(a * CGFloat(bumps))
            let pt = CGPoint(x: c.x + rr * cos(a), y: c.y + rr * sin(a))
            i == 0 ? p.move(to: pt) : p.addLine(to: pt)
        }
        p.closeSubpath()
        return p
    }
}

/// A slightly wonky star, like a marker doodle.
struct DoodleStar: Shape {
    var points = 5
    var inner: CGFloat = 0.42
    var seed: UInt64 = 3

    func path(in rect: CGRect) -> Path {
        var rng = SeededRandom(seed)
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        var p = Path()
        for i in 0..<(points * 2) {
            let a = CGFloat(i) / CGFloat(points * 2) * .pi * 2 - .pi / 2 + rng.range(-0.08, 0.08)
            let rr = (i.isMultiple(of: 2) ? r : r * inner) * rng.range(0.9, 1.0)
            let pt = CGPoint(x: c.x + rr * cos(a), y: c.y + rr * sin(a))
            i == 0 ? p.move(to: pt) : p.addLine(to: pt)
        }
        p.closeSubpath()
        return p
    }
}

/// Bottom-edge zigzag for the reading receipt.
struct ReceiptShape: Shape {
    var tooth: CGFloat = 10

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - tooth))
        var x = rect.maxX
        var down = true
        while x > rect.minX {
            x = max(x - tooth, rect.minX)
            p.addLine(to: CGPoint(x: x, y: down ? rect.maxY : rect.maxY - tooth))
            down.toggle()
        }
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        p.closeSubpath()
        return p
    }
}

/// Hand-drawn curved arrow pointing back at the current read.
struct CurvedArrow: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let start = CGPoint(x: rect.maxX * 0.85, y: rect.maxY)
        let end = CGPoint(x: rect.minX + rect.width * 0.05, y: rect.minY + rect.height * 0.2)
        p.move(to: start)
        p.addQuadCurve(to: end, control: CGPoint(x: rect.maxX * 0.95, y: rect.minY))
        p.move(to: end)
        p.addLine(to: CGPoint(x: end.x + rect.width * 0.28, y: end.y - rect.height * 0.12))
        p.move(to: end)
        p.addLine(to: CGPoint(x: end.x + rect.width * 0.22, y: end.y + rect.height * 0.2))
        return p
    }
}

/// Classic heart outline.
struct HeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        var p = Path()
        p.move(to: CGPoint(x: rect.minX + w * 0.5, y: rect.minY + h * 0.95))
        p.addCurve(to: CGPoint(x: rect.minX, y: rect.minY + h * 0.32),
                   control1: CGPoint(x: rect.minX + w * 0.2, y: rect.minY + h * 0.72),
                   control2: CGPoint(x: rect.minX, y: rect.minY + h * 0.55))
        p.addCurve(to: CGPoint(x: rect.minX + w * 0.5, y: rect.minY + h * 0.18),
                   control1: CGPoint(x: rect.minX, y: rect.minY + h * 0.02),
                   control2: CGPoint(x: rect.minX + w * 0.38, y: rect.minY))
        p.addCurve(to: CGPoint(x: rect.maxX, y: rect.minY + h * 0.32),
                   control1: CGPoint(x: rect.minX + w * 0.62, y: rect.minY),
                   control2: CGPoint(x: rect.maxX, y: rect.minY + h * 0.02))
        p.addCurve(to: CGPoint(x: rect.minX + w * 0.5, y: rect.minY + h * 0.95),
                   control1: CGPoint(x: rect.maxX, y: rect.minY + h * 0.55),
                   control2: CGPoint(x: rect.minX + w * 0.8, y: rect.minY + h * 0.72))
        p.closeSubpath()
        return p
    }
}

// MARK: - Backgrounds

/// Hand-painted vertical stripes (her light-blue and red/pink striped papers).
struct Stripes: View {
    var base: Color = .cream
    var stripe: Color = .powder
    /// Stripe width in points.
    var width: CGFloat = 22
    var seed: UInt64 = 7

    var body: some View {
        Canvas { ctx, size in
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(base))
            var rng = SeededRandom(seed)
            var x: CGFloat = -width / 2
            while x < size.width {
                var p = Path()
                let w = width * rng.range(0.85, 1.1)
                p.move(to: CGPoint(x: x, y: 0))
                var y: CGFloat = 0
                // Left edge wobbles down, right edge wobbles back up.
                while y < size.height {
                    y += 40
                    p.addLine(to: CGPoint(x: x + rng.range(-1.5, 1.5), y: y))
                }
                while y > 0 {
                    y -= 40
                    p.addLine(to: CGPoint(x: x + w + rng.range(-1.5, 1.5), y: max(y, 0)))
                }
                p.closeSubpath()
                ctx.fill(p, with: .color(stripe.opacity(rng.range(0.75, 0.95))))
                x += width * 2
            }
        }
    }
}

/// Faint ruled lines for notebook paper.
struct RuledLines: View {
    var spacing: CGFloat = 12
    var body: some View {
        Canvas { ctx, size in
            var y = spacing
            while y < size.height {
                ctx.stroke(Path { $0.move(to: CGPoint(x: 0, y: y)); $0.addLine(to: CGPoint(x: size.width, y: y)) },
                           with: .color(Color.powder.opacity(0.9)), lineWidth: 0.6)
                y += spacing
            }
            let margin = size.width * 0.08
            ctx.stroke(Path { $0.move(to: CGPoint(x: margin, y: 0)); $0.addLine(to: CGPoint(x: margin, y: size.height)) },
                       with: .color(Color.blush), lineWidth: 0.8)
        }
    }
}
