import PhotosUI
import SwiftUI
import UIKit

/// "profile": your library card, plus settings.
struct ProfileView: View {
    @Environment(AppModel.self) private var model
    @State private var displayName = ""
    @State private var username = ""
    @State private var bio = ""
    @State private var goal = 4
    @State private var isPrivate = false
    @State private var photo: PhotosPickerItem?
    @State private var confirmSignOut = false
    @State private var confirmDelete = false

    var body: some View {
        Form {
            Section {
                if let me = model.me { LibraryCard(profile: me, finished: model.finished.count) }
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))

            Section("you") {
                PhotosPicker(selection: $photo, matching: .images) {
                    Label("change photo", systemImage: "camera")
                }
                TextField("name", text: $displayName)
                HStack {
                    Text("@").foregroundStyle(.secondary)
                    TextField("username", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                TextField("bio", text: $bio, axis: .vertical).lineLimit(2...4)
            }

            Section {
                Stepper("monthly goal: \(goal) books", value: $goal, in: 1...50)
                Toggle("private journal", isOn: $isPrivate)
            } header: {
                Text("reading")
            } footer: {
                Text("Private means only approved followers see your shelves and activity. Your library card, top 8 and badges are always visible.")
            }

            Section {
                Button("save changes") { Task { await save() } }
                    .buttonStyle(BrickButtonStyle())
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
            }

            if model.me?.isAdmin == true {
                Section {
                    NavigationLink(value: Route.clubAdmin) {
                        Label("set the monthly book club pick", systemImage: "books.vertical")
                    }
                } header: {
                    Text("book club admin")
                } footer: {
                    Text("Only admins see this.")
                }
            }

            Section("account") {
                Button("sign out") { confirmSignOut = true }
                Button("delete my account", role: .destructive) { confirmDelete = true }
            }
        }
        .font(.display(15, weight: .semiBold))
        .foregroundStyle(Color.brick)
        .scrapbookScreen(stripe: .blush)
        .onAppear(perform: fill)
        // Re-check the profile (e.g. admin access granted since sign-in).
        .task { await model.refresh() }
        .refreshable { await model.refresh(); fill() }
        .onChange(of: photo) { _, item in
            guard let item else { return }
            Task { await upload(item) }
        }
        .confirmationDialog("Sign out?", isPresented: $confirmSignOut) {
            Button("Sign out") { Task { await model.signOut() } }
        }
        .confirmationDialog("Delete your account?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete forever", role: .destructive) { Task { await model.deleteAccount() } }
        } message: {
            Text("This permanently deletes your shelves, badges, comments and messages. It can't be undone.")
        }
    }

    private func fill() {
        guard let me = model.me else { return }
        displayName = me.displayName
        username = me.username
        bio = me.bio
        goal = me.monthlyGoal
        isPrivate = me.isPrivate
    }

    private func save() async {
        let handle = username.lowercased().trimmingCharacters(in: .whitespaces)
        guard handle.range(of: "^[a-z0-9_]{3,24}$", options: .regularExpression) != nil else {
            model.message = "Usernames are 3–24 letters, numbers or underscores."
            return
        }
        let patch = ProfilePatch(username: handle, displayName: String(displayName.prefix(60)), bio: String(bio.prefix(300)),
                                 monthlyGoal: goal, isPrivate: isPrivate)
        await model.perform("Saved") { try await model.backend.updateProfile(patch) }
    }

    private func upload(_ item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data),
              let jpeg = image.squareThumbnail(side: 600).jpegData(compressionQuality: 0.85) else {
            model.message = "Couldn't read that photo."
            return
        }
        await model.perform("Looking good!") {
            let url = try await model.backend.uploadAvatar(jpeg)
            try await model.backend.updateProfile(ProfilePatch(avatarURL: url))
        }
    }
}

/// The "book lovers club" member ID from her Canva artboard.
struct LibraryCard: View {
    let profile: Profile
    let finished: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("BOOK LOVERS CLUB").font(.serif(22)).foregroundStyle(Color.ink)
                Spacer()
                StickerView(.goldStar).frame(width: 26, height: 26)
            }
            HStack(alignment: .top, spacing: 14) {
                VStack(spacing: 6) {
                    Avatar(url: profile.avatarURL, name: profile.shortName, size: 78)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    Barcode2().frame(width: 70, height: 18)
                }
                VStack(alignment: .leading, spacing: 6) {
                    field("name", profile.shortName)
                    field("member", "@\(profile.username)")
                    field("books read", "\(finished)")
                    field("motto", profile.bio.isEmpty ? "always with a book in my bag" : profile.bio)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.15), radius: 6, y: 4)
        )
        .overlay(alignment: .top) {
            // The lanyard clip
            Capsule().fill(Color(hex: 0xB9BEC4)).frame(width: 44, height: 12).offset(y: -6)
        }
        .overlay(alignment: .bottomTrailing) {
            StickerView(.pinkHeart).frame(width: 34, height: 30).rotationEffect(.degrees(12)).offset(x: 8, y: 8)
        }
        .rotationEffect(.degrees(-1.5))
        .padding(.horizontal, 6)
        .padding(.vertical, 10)
    }

    private func field(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label.uppercased()).font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundStyle(.secondary)
            Text(value).font(.display(13, weight: .semiBold)).foregroundStyle(Color.ink).lineLimit(2)
        }
    }
}

private struct Barcode2: View {
    var body: some View {
        Canvas { ctx, size in
            var rng = SeededRandom(7)
            var x: CGFloat = 0
            while x < size.width {
                let w = rng.range(0.8, 2.4)
                ctx.fill(Path(CGRect(x: x, y: 0, width: w, height: size.height)), with: .color(Color.ink))
                x += w + rng.range(0.8, 2)
            }
        }
    }
}

extension UIImage {
    /// Center-cropped square, downscaled for upload.
    func squareThumbnail(side: CGFloat) -> UIImage {
        let edge = min(size.width, size.height)
        let crop = CGRect(x: (size.width - edge) / 2, y: (size.height - edge) / 2, width: edge, height: edge)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format).image { _ in
            draw(in: CGRect(x: -crop.minX * side / edge, y: -crop.minY * side / edge, width: size.width * side / edge, height: size.height * side / edge))
        }
    }
}
