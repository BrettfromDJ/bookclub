import SwiftUI

/// Email sign-in with a 6-digit code (no password, no link to tap).
struct LoginView: View {
    @Environment(AppModel.self) private var model
    @State private var email = ""
    @State private var code = ""
    @State private var codeSent = false
    @State private var working = false
    @FocusState private var focus: Field?

    private enum Field { case email, code }

    var body: some View {
        ZStack {
            StripedBackground()
            ScrollView {
                VStack(spacing: 22) {
                    ZStack(alignment: .topTrailing) {
                        VStack(spacing: 6) {
                            Wordmark(size: 52)
                            Text("hot girls collect books faster than we can read them")
                                .font(.serif(20))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(Color.honey)
                        }
                        .padding(26)
                        .background(RoundedRectangle(cornerRadius: 26).fill(Color.cream))
                        .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(Color.brick, style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])).padding(6))
                        StickerView(.daisies).frame(width: 90, height: 66)
                            .idle(.wobble(7), period: 1.6)
                            .entrance(.pop(spin: -120), delay: 0.4)
                            .offset(x: 14, y: -30)
                    }
                    .entrance(.drop)
                    .padding(.top, 60)

                    PaperCard(dashed: false) {
                        VStack(alignment: .leading, spacing: 14) {
                            if !codeSent {
                                Text("sign in or join").font(.display(20)).foregroundStyle(Color.brick)
                                Text("we'll email you a 6-digit code.").font(.serif(17)).foregroundStyle(Color.rose)
                                TextField("you@email.com", text: $email)
                                    .keyboardType(.emailAddress)
                                    .textContentType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .focused($focus, equals: .email)
                                    .submitLabel(.send)
                                    .onSubmit { Task { await sendCode() } }
                                    .field()
                                Button { Task { await sendCode() } } label: { label("send my code") }
                                    .buttonStyle(BrickButtonStyle())
                                    .disabled(!email.contains("@") || working)
                            } else {
                                Text("check your email").font(.display(20)).foregroundStyle(Color.brick)
                                Text("type the code we sent to \(email)").font(.serif(17)).foregroundStyle(Color.rose)
                                TextField("123456", text: $code)
                                    .keyboardType(.numberPad)
                                    .textContentType(.oneTimeCode)
                                    .font(.display(24))
                                    .multilineTextAlignment(.center)
                                    .focused($focus, equals: .code)
                                    .field()
                                    .onChange(of: code) { _, new in
                                        if new.filter(\.isNumber).count == 6 { Task { await verify() } }
                                    }
                                Button { Task { await verify() } } label: { label("let me in") }
                                    .buttonStyle(BrickButtonStyle())
                                    .disabled(code.count < 6 || working)
                                Button("use a different email") { codeSent = false; code = "" }
                                    .font(.display(13, weight: .bold))
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    Text("by joining you agree to be kind in the book club chat 💌")
                        .font(.display(11, weight: .semiBold))
                        .foregroundStyle(Color.brick.opacity(0.7))
                }
                .padding(24)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .revealsOnAppear()
        .onAppear { focus = .email }
    }

    @ViewBuilder private func label(_ text: String) -> some View {
        if working { ProgressView().tint(.cream) } else { Text(text) }
    }

    private func sendCode() async {
        let address = email.trimmingCharacters(in: .whitespaces).lowercased()
        guard address.contains("@") else { return }
        working = true
        defer { working = false }
        do {
            try await model.backend.sendCode(email: address)
            email = address
            codeSent = true
            focus = .code
        } catch { model.show(error) }
    }

    private func verify() async {
        guard !working else { return }
        working = true
        defer { working = false }
        do {
            let id = try await model.backend.verify(email: email, code: code.filter(\.isNumber))
            await model.signedIn(as: id)
        } catch {
            code = ""
            model.show(error)
        }
    }
}

private extension View {
    func field() -> some View {
        self
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.brick.opacity(0.4), lineWidth: 1))
    }
}
