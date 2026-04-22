import SwiftUI

struct AuthView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings

    @State private var isLogin = true
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    @State private var isLoading = false
    @State private var errorMessage = ""

    private let auth    = SupabaseAuth.shared
    private let service = SupabaseService.shared

    var body: some View {
        ZStack {
            Color.ggBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Logo
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color.ggAccent.opacity(0.15))
                                .frame(width: 90, height: 90)
                            Text("GG")
                                .font(.system(size: 36, weight: .black, design: .rounded))
                                .foregroundColor(.ggAccent)
                        }
                        Text("GYMGRIND")
                            .font(.system(size: 32, weight: .black))
                            .foregroundColor(.ggText)
                            .tracking(4)
                        Text(isLogin ? "Welcome back" : "Create your account")
                            .font(.ggCaption)
                            .foregroundColor(.ggTextSecondary)
                    }
                    .padding(.top, 60)
                    .padding(.bottom, 40)

                    // Toggle login/register
                    HStack(spacing: 0) {
                        tabButton("LOGIN", selected: isLogin) { isLogin = true }
                        tabButton("REGISTER", selected: !isLogin) { isLogin = false }
                    }
                    .background(Color.ggSurface)
                    .cornerRadius(10)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)

                    // Form
                    VStack(spacing: 16) {
                        if !isLogin {
                            inputField(icon: "person.fill", placeholder: "Username", text: $username)
                        }
                        inputField(icon: "envelope.fill", placeholder: "Email", text: $email, keyboard: .emailAddress)
                        inputField(icon: "lock.fill", placeholder: "Password", text: $password, secure: true)
                    }
                    .padding(.horizontal, 24)

                    // Error
                    if !errorMessage.isEmpty {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.ggDanger)
                            Text(errorMessage)
                                .font(.ggCaption)
                                .foregroundColor(.ggDanger)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 12)
                    }

                    // Submit button
                    Button {
                        Task { await submit() }
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .tint(.black)
                                    .scaleEffect(0.8)
                            }
                            Text(isLogin ? "SIGN IN" : "CREATE ACCOUNT")
                                .font(.system(size: 17, weight: .black))
                                .tracking(1)
                        }
                    }
                    .buttonStyle(GGButtonStyle())
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .disabled(isLoading || !canSubmit)
                    .opacity(canSubmit ? 1 : 0.4)

                    Spacer(minLength: 40)
                }
            }
        }
    }

    var canSubmit: Bool {
        !email.isEmpty && !password.isEmpty && (isLogin || !username.isEmpty)
    }

    func submit() async {
        isLoading = true
        errorMessage = ""
        do {
            if isLogin {
                try await auth.signIn(email: email, password: password)
            } else {
                try await auth.signUp(email: email, password: password, username: username)
                settings.userName = username
                settings.onboardingDone = true
            }
            // Sync profile + pull cloud data
            await service.syncProfile(settings: settings)
            await service.pullAllData(into: context)
        } catch {
            errorMessage = friendlyError(error)
        }
        isLoading = false
    }

    func friendlyError(_ error: Error) -> String {
        let msg = error.localizedDescription.lowercased()
        if msg.contains("invalid") || msg.contains("credentials") {
            return "Email ou password incorretos"
        }
        if msg.contains("already") || msg.contains("exists") {
            return "Este email já está registado"
        }
        if msg.contains("400") { return "Dados inválidos. Verifica o email e a password (mín. 6 caracteres)" }
        if msg.contains("422") { return "Password demasiado curta (mín. 6 caracteres)" }
        return "Erro: \(error.localizedDescription)"
    }

    func tabButton(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.ggCaption)
                .tracking(1)
                .foregroundColor(selected ? .black : .ggTextSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(selected ? Color.ggAccent : Color.clear)
                .cornerRadius(9)
        }
    }

    func inputField(icon: String, placeholder: String, text: Binding<String>,
                    keyboard: UIKeyboardType = .default, secure: Bool = false) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.ggTextSecondary)
                .frame(width: 20)

            if secure {
                SecureField(placeholder, text: text)
                    .font(.ggBody)
                    .foregroundColor(.ggText)
            } else {
                TextField(placeholder, text: text)
                    .font(.ggBody)
                    .foregroundColor(.ggText)
                    .keyboardType(keyboard)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
            }
        }
        .padding(16)
        .background(Color.ggSurface)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.ggBorder, lineWidth: 1))
    }
}
