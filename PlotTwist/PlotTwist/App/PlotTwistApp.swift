import SwiftUI
import UIKit

@main
struct PlotTwistApp: App {
    @State private var model = AppModel()

    init() {
        // Book covers are fetched with URLSession, which uses this shared disk cache.
        URLCache.shared = URLCache(memoryCapacity: 50 * 1024 * 1024, diskCapacity: 300 * 1024 * 1024)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .tint(.brick)
        }
    }
}

struct RootView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            switch model.phase {
            case .launching:
                Splash()
            case .signedOut:
                LoginView()
            case .signedIn:
                NavigationStack {
                    HomeView()
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: model.phase)
        .overlay(alignment: .top) { Toast().animation(.spring(duration: 0.35), value: model.message) }
        .task { await model.launch() }
        // Coming back to the app picks up anything that changed meanwhile.
        .onChange(of: scenePhase) { _, phase in
            if phase == .active, model.phase == .signedIn { Task { await model.refresh() } }
        }
    }
}

private struct Splash: View {
    var body: some View {
        ZStack {
            Color.cream.ignoresSafeArea()
            Wordmark(size: 56)
                .idle(.wobble(4), period: 0.7)
                .entrance(.pop(spin: -30))
        }
        .revealsOnAppear()
    }
}

/// Her chunky "plot twist" logo (falls back to typed lettering if the artwork is missing).
struct Wordmark: View {
    var size: CGFloat = 40
    var body: some View {
        if let logo = UIImage(named: "logo-chunky") {
            Image(uiImage: logo)
                .resizable()
                .scaledToFit()
                .frame(height: size * 1.7)
                .accessibilityLabel("plot twist")
        } else {
            Text("plot twist")
                .font(.display(size))
                .tracking(-0.02 * size)
                .foregroundStyle(Color.marigold)
        }
    }
}

/// A short message that drops in from the top and fades away.
private struct Toast: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        if let message = model.message {
            Text(message)
                .font(.display(14, weight: .bold))
                .foregroundStyle(Color.cream)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(Capsule().fill(Color.brick))
                .shadow(color: .black.opacity(0.2), radius: 6, y: 3)
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
                .onTapGesture { model.message = nil }
                .task(id: message) {
                    try? await Task.sleep(for: .seconds(2.6))
                    withAnimation { model.message = nil }
                }
        }
    }
}
