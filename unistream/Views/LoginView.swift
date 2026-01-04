import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isShowingSignUp = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var userState: UserState
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(gradient: Gradient(colors: [.blue.opacity(0.8), .black]),
                             startPoint: .top,
                             endPoint: .bottom)
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Logo
                        Image(systemName: "play.circle.fill")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.white)
                            .padding(.top, 50)
                        
                        Text("Unistream")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        // Social Sign in buttons
                        VStack(spacing: 15) {
                            // Sign in with Apple
                            SignInWithAppleButton { request in
                                request.requestedScopes = [.email, .fullName]
                            } onCompletion: { result in
                                handleAppleSignIn(result)
                            }
                            .frame(height: 50)
                            .cornerRadius(8)
                            
                            // Google Sign In
                            Button(action: signInWithGoogle) {
                                HStack {
                                    Image("google_logo")
                                        .resizable()
                                        .frame(width: 20, height: 20)
                                    Text("Continue with Google")
                                        .font(.headline)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(8)
                                .foregroundColor(.black)
                            }
                            .disabled(isLoading)
                            
                            // Facebook Sign In
                            Button(action: signInWithFacebook) {
                                HStack {
                                    Image("facebook_logo")
                                        .resizable()
                                        .frame(width: 20, height: 20)
                                    Text("Continue with Facebook")
                                        .font(.headline)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(8)
                                .foregroundColor(.white)
                            }
                            .disabled(isLoading)
                            
                            // X (Twitter) Sign In
                            Button(action: signInWithX) {
                                HStack {
                                    Image("x_logo")
                                        .resizable()
                                        .frame(width: 20, height: 20)
                                    Text("Continue with X")
                                        .font(.headline)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.black)
                                .cornerRadius(8)
                                .foregroundColor(.white)
                            }
                            .disabled(isLoading)
                        }
                        .padding(.horizontal)
                        
                        // Divider
                        HStack {
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(.gray)
                            Text("or")
                                .foregroundColor(.gray)
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal)
                        
                        // Email/Password fields
                        VStack(spacing: 15) {
                            TextField("Email", text: $email)
                                .textFieldStyle(RoundedTextFieldStyle())
                            
                            SecureField("Password", text: $password)
                                .textFieldStyle(RoundedTextFieldStyle())
                            
                            Button(action: signInWithEmail) {
                                Text("Sign In")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Sign Up Link
                        Button(action: { isShowingSignUp = true }) {
                            Text("Don't have an account? Sign Up")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $isShowingSignUp) {
                SignUpView()
            }
        }
    }
    
    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        // Implement Apple sign in
    }
    
    private func signInWithGoogle() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            showError("Unable to present login")
            return
        }
        
        isLoading = true
        
        Task {
            do {
                let user = try await SocialAuthService.shared.signInWithGoogle(presenting: rootViewController)
                await MainActor.run {
                    userState.currentUser = user
                    userState.isAuthenticated = true
                }
            } catch {
                await MainActor.run {
                    showError(error.localizedDescription)
                }
            }
            
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    private func signInWithFacebook() {
        isLoading = true
        
        Task {
            do {
                let user = try await SocialAuthService.shared.signInWithFacebook()
                await MainActor.run {
                    userState.currentUser = user
                    userState.isAuthenticated = true
                }
            } catch {
                await MainActor.run {
                    showError(error.localizedDescription)
                }
            }
            
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    private func signInWithX() {
        isLoading = true
        
        Task {
            do {
                let user = try await SocialAuthService.shared.signInWithX()
                await MainActor.run {
                    userState.currentUser = user
                    userState.isAuthenticated = true
                }
            } catch {
                await MainActor.run {
                    showError(error.localizedDescription)
                }
            }
            
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    private func signInWithEmail() {
        isLoading = true
        
        guard !email.isEmpty, email.contains("@") else {
            showError("Please enter a valid email")
            return
        }
        
        guard !password.isEmpty else {
            showError("Please enter your password")
            return
        }
        
        Task {
            do {
                try await userState.signIn(email: email, password: password)
            } catch {
                await MainActor.run {
                    showError(error.localizedDescription)
                }
            }
            
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    private func showError(_ message: String) {
        isLoading = false
        alertMessage = message
        showingAlert = true
    }
}

// Custom text field style
struct RoundedTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.white)
            .cornerRadius(8)
            .shadow(radius: 2)
    }
} 