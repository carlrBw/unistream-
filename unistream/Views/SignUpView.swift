import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userState: UserState
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var username = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [.blue.opacity(0.8), .black]),
                             startPoint: .top,
                             endPoint: .bottom)
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        Text("Create Account")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.top, 50)
                        
                        VStack(spacing: 15) {
                            TextField("Username", text: $username)
                                .textFieldStyle(RoundedTextFieldStyle())
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                            
                            TextField("Email", text: $email)
                                .textFieldStyle(RoundedTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                            
                            SecureField("Password", text: $password)
                                .textFieldStyle(RoundedTextFieldStyle())
                            
                            SecureField("Confirm Password", text: $confirmPassword)
                                .textFieldStyle(RoundedTextFieldStyle())
                            
                            Button(action: handleSignUp) {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Sign Up")
                                        .font(.headline)
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(8)
                            .disabled(isLoading)
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationBarItems(leading: Button("Cancel") {
                dismiss()
            })
            .alert("Error", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func handleSignUp() {
        isLoading = true
        
        // Basic validation
        guard !username.isEmpty else {
            showError("Please enter a username")
            return
        }
        
        guard !email.isEmpty, email.contains("@") else {
            showError("Please enter a valid email")
            return
        }
        
        guard password.count >= 6 else {
            showError("Password must be at least 6 characters")
            return
        }
        
        guard password == confirmPassword else {
            showError("Passwords don't match")
            return
        }
        
        Task {
            do {
                try await userState.signUp(username: username, email: email, password: password)
                await MainActor.run {
                    dismiss()
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
    
    private func showError(_ message: String) {
        isLoading = false
        alertMessage = message
        showingAlert = true
    }
}

#Preview {
    SignUpView()
        .environmentObject(UserState())
} 