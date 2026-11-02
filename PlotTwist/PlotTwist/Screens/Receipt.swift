import SwiftUI
import UIKit

/// "print your november reading receipt": the month's finished books as a till receipt.
struct ReceiptView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.displayScale) private var displayScale
    @State private var printed = false
    @State private var image: Image?

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Printer slot
                RoundedRectangle(cornerRadius: 18)
                    .fill(LinearGradient(colors: [Color(hex: 0xF7F7F5), Color(hex: 0xD9D9D5)], startPoint: .top, endPoint: .bottom))
                    .frame(height: 56)
                    .overlay(alignment: .bottom) { Capsule().fill(Color(hex: 0x6E6E6A)).frame(height: 8).padding(.horizontal, 22).padding(.bottom, 12) }
                    .shadow(color: .black.opacity(0.2), radius: 6, y: 4)
                    .zIndex(1)

                if let receipt {
                    ReceiptCard(receipt: receipt)
                        .padding(.horizontal, 22)
                        .offset(y: printed ? -14 : -600)
                        .clipped()
                }
            }
            .padding(20)
            .clipped()
        }
        .scrapbookScreen()
        .toolbar {
            if let image {
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: image, preview: SharePreview("my \(Month.name()) reading receipt", image: image)) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .task {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            withAnimation(.easeOut(duration: 1.6)) { printed = true }
            render()
        }
    }

    private var receipt: Receipt? {
        model.me.map { Receipt(profile: $0, shelf: model.shelf) }
    }

    @MainActor private func render() {
        guard let receipt else { return }
        let renderer = ImageRenderer(content: ReceiptCard(receipt: receipt).frame(width: 340).padding(24).background(Color.powder))
        renderer.scale = displayScale
        if let ui = renderer.uiImage { image = Image(uiImage: ui) }
    }
}

struct ReceiptCard: View {
    let receipt: Receipt

    var body: some View {
        VStack(spacing: 10) {
            Text("plot twist").font(.display(26)).tracking(-1.5).foregroundStyle(Color.marigold)
            Text("\(receipt.monthName) reading receipt").font(.serif(19)).foregroundStyle(Color.rose)
            Text("reader: \(receipt.reader)").font(.system(size: 12, design: .monospaced))
            dashes
            if receipt.lines.isEmpty {
                Text("no books finished yet this month.\nthe plot is still thickening…")
                    .font(.system(size: 13, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 12)
            }
            ForEach(Array(receipt.lines.enumerated()), id: \.element.id) { i, line in
                HStack(alignment: .firstTextBaseline) {
                    Text(String(format: "%02d", i + 1))
                    VStack(alignment: .leading, spacing: 1) {
                        Text(line.title.uppercased()).lineLimit(2)
                        Text(line.author.lowercased()).foregroundStyle(.secondary).lineLimit(1)
                    }
                    Spacer(minLength: 8)
                    Text(line.pages.map { "\($0)p" } ?? "—")
                }
                .font(.system(size: 12, design: .monospaced))
            }
            dashes
            row("BOOKS", "\(receipt.lines.count)")
            row("PAGES", receipt.totalPages.formatted())
            row("GOAL", "\(receipt.lines.count)/\(receipt.goal)\(receipt.hitGoal ? " ✓" : "")")
            dashes
            Text(receipt.hitGoal ? "goal getter! ★" : "thank you for reading!")
                .font(.serif(18))
                .foregroundStyle(Color.brick)
            Barcode().frame(height: 34).padding(.horizontal, 30)
            Text("hot girls collect books faster than we can read them")
                .font(.system(size: 9, design: .monospaced))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .foregroundStyle(Color(hex: 0x2B2B2B))
        .padding(.horizontal, 18)
        .padding(.top, 22)
        .padding(.bottom, 30)
        .background(ReceiptShape(tooth: 9).fill(Color.white))
        .shadow(color: .black.opacity(0.12), radius: 4, y: 3)
    }

    private var dashes: some View {
        Text(String(repeating: "- ", count: 24)).font(.system(size: 11, design: .monospaced)).lineLimit(1).foregroundStyle(.secondary)
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack { Text(label); Spacer(); Text(value) }.font(.system(size: 13, weight: .bold, design: .monospaced))
    }
}

private struct Barcode: View {
    var body: some View {
        Canvas { ctx, size in
            var rng = SeededRandom(42)
            var x: CGFloat = 0
            while x < size.width {
                let w = rng.range(1, 3.5)
                ctx.fill(Path(CGRect(x: x, y: 0, width: w, height: size.height)), with: .color(.black))
                x += w + rng.range(1, 3)
            }
        }
    }
}
